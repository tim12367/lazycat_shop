/*
 * 共用API請求
 */
import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:lazycat_shop/token_storage.dart';

class ApiService {
  final lazyCatBaseUrl = const String.fromEnvironment("lazy.cat.shop.baseurl");

  Dio getLazyCatDio() {
    final dio = Dio();
    dio.options.baseUrl = lazyCatBaseUrl; // 設定baseUrl
    dio.options.headers = {
      HttpHeaders.accessControlAllowOriginHeader: lazyCatBaseUrl,
    };
    // 請求LOG
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
    dio.interceptors.add(LazyCatInterceptors()); // 304自動重試
    return dio;
  }
}

class LazyCatInterceptors extends Interceptor {
  final tokenStorage = TokenStorage();
  final lazyCatBaseUrl = const String.fromEnvironment("lazy.cat.shop.baseurl");
  final dio = Dio();

  // 送出前插入access token
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    log('REQUEST[${options.method}] => PATH: ${options.path}');
    final accessToken = await tokenStorage.getAccessToken();
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    log(
      'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
    );
    super.onResponse(response, handler);
  }

  @override
  Future onError(DioException err, ErrorInterceptorHandler handler) async {
    log(
      'ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}',
    );

    if (err.response?.statusCode == 401) {
      String? refreshToken = await tokenStorage.getRefreshToken();

      //有 refreshToken，重試
      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          // 請求新access token /get-access-token
          final getAccessTokenResponse = await dio.post(
            '$lazyCatBaseUrl/get-access-token',
            options: Options(
              headers: {
                "Authorization": "Bearer $refreshToken", // 设置 content-length.
              },
            ),
          );

          String newAccessToken = getAccessTokenResponse.data.toString();
          tokenStorage.setAccessToken(newAccessToken); // 更新 access token

          // 重試之前的請求
          err.requestOptions.headers['Authorization'] =
              'Bearer $newAccessToken';
          final response = await dio.fetch(err.requestOptions);
          return handler.resolve(response);
        } catch (e) {
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
