import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'auth_service.dart';

class ApiService {
  static Future<http.Response> get(
    String path, {
    Map<String, String>? headers,
    bool auth = true,
  }) async {
    final uri = Uri.parse(apiUrl(path));
    final token = auth ? await AuthService.getToken() : null;
    final merged = <String, String>{
      'Content-Type': 'application/json',
      if (headers != null) ...headers,
      if (token != null) 'Authorization': 'Bearer $token',
    };
    return http.get(uri, headers: merged);
  }

  static Future<http.Response> post(
    String path, {
    Object? body,
    Map<String, String>? headers,
    bool auth = true,
  }) async {
    final uri = Uri.parse(apiUrl(path));
    final token = auth ? await AuthService.getToken() : null;
    final merged = <String, String>{
      'Content-Type': 'application/json',
      if (headers != null) ...headers,
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final encoded = body == null ? null : jsonEncode(body);
    return http.post(uri, headers: merged, body: encoded);
  }

  static Future<http.Response> put(
    String path, {
    Object? body,
    Map<String, String>? headers,
    bool auth = true,
  }) async {
    final uri = Uri.parse(apiUrl(path));
    final token = auth ? await AuthService.getToken() : null;
    final merged = <String, String>{
      'Content-Type': 'application/json',
      if (headers != null) ...headers,
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final encoded = body == null ? null : jsonEncode(body);
    return http.put(uri, headers: merged, body: encoded);
  }

  static Future<http.Response> delete(
    String path, {
    Map<String, String>? headers,
    bool auth = true,
  }) async {
    final uri = Uri.parse(apiUrl(path));
    final token = auth ? await AuthService.getToken() : null;
    final merged = <String, String>{
      'Content-Type': 'application/json',
      if (headers != null) ...headers,
      if (token != null) 'Authorization': 'Bearer $token',
    };
    return http.delete(uri, headers: merged);
  }
}
