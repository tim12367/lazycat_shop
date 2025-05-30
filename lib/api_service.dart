/*
 * 共用API請求
 */
import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:lazycat_shop/token_storage.dart';
import 'package:provider/provider.dart';

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
    // dio.options.headers = {
    //   HttpHeaders.accessControlAllowOriginHeader: "*",
    //   HttpHeaders.accessControlAllowMethodsHeader: "GET,PUT,PATCH,POST,DELETE",
    //   HttpHeaders.accessControlAllowHeadersHeader:
    //       "Origin, X-Requested-With, Content-Type, Accept",
    // };
    // 請求LOG
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
    dio.interceptors.add(LazyCatInterceptors(context)); // 304自動重試
    return dio;
  }
}

class LazyCatInterceptors extends Interceptor {
  final Config config = Config();
  final BuildContext context;

  LazyCatInterceptors(this.context);

  final tokenStorage = TokenStorage();
  final dio = Dio();

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
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    super.onRequest(options, handler);
  }

  // 當響應即將被處理時調用
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    log(
      'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
    );
    super.onResponse(response, handler);
  }

  // 錯誤時
  @override
  Future onError(DioException err, ErrorInterceptorHandler handler) async {
    log(
      'ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}',
    );
    final lazyCatBaseUrl = config.getLazyCatBaseUrl();

    // 若遇到401
    if (err.response?.statusCode == 401) {
      String? refreshToken = await tokenStorage.getRefreshToken();

      //有 refreshToken，重試
      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          // 請求新access token /get-access-token
          final getAccessTokenResponse = await dio.post(
            '$lazyCatBaseUrl/get-access-token',
            options: Options(
              headers: {"Authorization": "Bearer $refreshToken"},
            ),
          );

          // 從回應取得token
          String newAccessToken = getAccessTokenResponse.data.toString();
          tokenStorage.setAccessToken(newAccessToken); // 更新 access token

          // 重試之前的請求
          err.requestOptions.headers['Authorization'] =
              'Bearer $newAccessToken';
          final response = await dio.fetch(err.requestOptions);
          return handler.resolve(response);
        } catch (e) {
          // 失敗清空token
          tokenStorage.clear();
        }
      } else {
        // 無 refreshToken，清空
        tokenStorage.clear();
      }
    }
    super.onError(err, handler);
  }
}
