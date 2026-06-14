import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int statusCode;
  final String? code;
  final String? nextAllowedAt;

  const ApiException({
    required this.message,
    required this.statusCode,
    this.code,
    this.nextAllowedAt,
  });

  bool get isUnauthorized => statusCode == 401;
  bool get isConflict => statusCode == 409;
  bool get isCooldown => statusCode == 429;

  @override
  String toString() => message;
}

ApiException parseApiException(http.Response response, {String fallback = 'Error de servidor'}) {
  String message = fallback;
  String? code;
  String? nextAllowedAt;

  try {
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      message = decoded['error']?.toString() ??
          decoded['message']?.toString() ??
          fallback;
      code = decoded['code']?.toString();
      nextAllowedAt = decoded['nextAllowedAt']?.toString();
    } else if (response.body.isNotEmpty) {
      message = response.body;
    }
  } catch (_) {
    if (response.body.isNotEmpty) {
      message = response.body;
    }
  }

  if (response.statusCode == 401) {
    message = 'Sesión expirada. Inicia sesión de nuevo.';
  } else if (response.statusCode == 429) {
    if (nextAllowedAt != null) {
      try {
        final next = DateTime.parse(nextAllowedAt).toLocal();
        final formatted =
            '${next.day.toString().padLeft(2, '0')}/${next.month.toString().padLeft(2, '0')}/${next.year} ${next.hour.toString().padLeft(2, '0')}:${next.minute.toString().padLeft(2, '0')}';
        message = '$message Próximo registro: $formatted';
      } catch (_) {}
    }
  }

  return ApiException(
    message: message,
    statusCode: response.statusCode,
    code: code,
    nextAllowedAt: nextAllowedAt,
  );
}

void ensureSuccess(http.Response response, {String fallback = 'Error de servidor'}) {
  if (response.statusCode >= 200 && response.statusCode < 300) return;
  throw parseApiException(response, fallback: fallback);
}
