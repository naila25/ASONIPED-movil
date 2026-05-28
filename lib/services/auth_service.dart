import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';

  /// Save JWT token securely
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Read JWT token
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Delete stored JWT token
  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }
}
