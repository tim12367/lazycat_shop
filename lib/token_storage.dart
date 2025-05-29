import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  final storage = FlutterSecureStorage();

  Future<void> setAccessToken(String accessToken) async {
    return await storage.write(key: 'accessToken', value: accessToken);
  }

  Future<void> setRefreshToken(String refreshToken) async {
    return await storage.write(key: 'refreshToken', value: refreshToken);
  }

  Future<String?> getAccessToken() async {
    return await storage.read(key: 'accessToken');
  }

  Future<String?> getRefreshToken() async {
    return await storage.read(key: 'refreshToken');
  }

  Future<void> clear() async {
    return await storage.deleteAll();
  }
}
