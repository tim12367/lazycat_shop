/*
 * 共用API請求
 */
import 'package:dio/dio.dart';

class ApiService {
  Dio getDioWithAuth() {
    final dio = Dio();
    // 請求LOG
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
    return dio;
  }
}
