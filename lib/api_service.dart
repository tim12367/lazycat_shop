/*
 * 共用API請求
 */
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:lazycat_shop/token_storage.dart';

import 'config.dart';

class ApiService {
  final BuildContext context;
  final Config config = Config();

  // 建構子
  ApiService(this.context);

  Dio getLazyCatDio() {
    final lazyCatBaseUrl = config.getLazyCatBaseUrl();
    final dio = Dio();
    dio.options.baseUrl = lazyCatBaseUrl; // 設定baseUrl
    dio.options.extra['maxAuthRetryLimit'] = 5; // 最大重試次數
    dio.options.extra['retryCount'] = 0; // 目前重試次數

    // 請求LOG
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        requestHeader: true,
        responseBody: true,
      ),
    );
    dio.interceptors.add(LazyCatInterceptors(context, dio)); // 自動重試
    return dio;
  }
}

// 自訂請求攔截器
class LazyCatInterceptors extends Interceptor {
  final Config config = Config();
  final BuildContext context;
  final Dio originalDio;

  LazyCatInterceptors(this.context, this.originalDio);

  final tokenStorage = TokenStorage();

  // 送出請求前
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Log
    log('REQUEST[${options.method}] => PATH: ${options.path}');

    // 塞token
    final accessToken = await tokenStorage.getAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    handler.next(options);
  }

  // 錯誤時
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    log(
      'ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}',
    );

    int? statusCode = err.response?.statusCode;

    // 取出原始options
    RequestOptions originalOptions = err.requestOptions;

    int maxAuthRetryLimit =
        originalOptions.extra['maxAuthRetryLimit']; // 最大重試次數
    int retryCount = originalOptions.extra['retryCount']; // 目前重試次數

    // 若遇到401
    if ((statusCode == 401 || statusCode == 403) &&
        retryCount < maxAuthRetryLimit) {
      // 更新計數器
      int currentRetryCount = retryCount + 1;
      originalOptions.extra['retryCount'] = currentRetryCount;

      log(
        "發生錯誤401|403，嘗試刷新access token...($currentRetryCount/$maxAuthRetryLimit)次",
      );

      String? refreshToken = await tokenStorage.getRefreshToken();

      //有 refreshToken，重試
      if (refreshToken != null && refreshToken.isNotEmpty) {
        // 從回應取得token
        String newAccessToken = await _getAccessToken(refreshToken);
        await tokenStorage.setAccessToken(newAccessToken); // 更新 access token

        // 重試之前的請求
        final response = await originalDio.fetch(originalOptions);
        return handler.resolve(response);
      } else {
        // 無 refreshToken，清空資料
        log("刷新token失敗!!");
        tokenStorage.clear();
        // TODO: 返回登入頁面
      }
    }

    handler.next(err); // 繼續傳遞錯誤
  }

  // 用 refreshToken 取得 accessToken
  Future<String> _getAccessToken(String refreshToken) async {
    final dio = Dio();
    final Config config = Config();
    final lazyCatBaseUrl = config.getLazyCatBaseUrl();

    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        requestHeader: true,
        responseBody: true,
      ),
    );

    // 請求新access token /get-access-token
    final getAccessTokenResponse = await dio.post(
      '$lazyCatBaseUrl/get-access-token',
      options: Options(headers: {"Authorization": "Bearer $refreshToken"}),
    );

    return getAccessTokenResponse.data.toString();
  }
}
