import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum SessionStatus { none, valid, expired }

class AuthService {
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';
  static const String sessionExpiredMessage =
      'Sesión expirada. Inicia sesión de nuevo.';

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

  /// Whether the JWT `exp` claim is in the past.
  static bool isTokenExpired(String token) {
    try {
      final payload = _decodeTokenPayload(token);
      if (payload == null) return true;
      final exp = payload['exp'];
      if (exp is int) {
        return DateTime.now().millisecondsSinceEpoch >= exp * 1000;
      }
      if (exp is String) {
        final parsed = int.tryParse(exp);
        if (parsed != null) {
          return DateTime.now().millisecondsSinceEpoch >= parsed * 1000;
        }
      }
    } catch (_) {
      return true;
    }
    return false;
  }

  static Map<String, dynamic>? _decodeTokenPayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    final normalized = base64Url.normalize(parts[1]);
    final decoded = utf8.decode(base64Url.decode(normalized));
    return jsonDecode(decoded) as Map<String, dynamic>;
  }

  /// Decode user claims from the stored JWT (username, email, roles, etc.).
  static Future<Map<String, dynamic>?> getUserFromToken() async {
    final token = await getToken();
    if (token == null) return null;
    return _decodeTokenPayload(token);
  }
}
