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

  bool get requiresReLogin => isUnauthorized || _isSessionFailure(statusCode, message);

  static bool _isSessionFailure(int statusCode, String message) {
    if (statusCode == 401) return true;
    if (statusCode != 403) return false;
    final lower = message.toLowerCase();
    return lower.contains('invalid token') ||
        lower.contains('session invalidated') ||
        lower.contains('no token provided') ||
        lower.contains('unauthorized') ||
        lower.contains('forbidden: invalid token');
  }

  static const String sessionExpiredMessage =
      'Sesión expirada. Inicia sesión de nuevo.';

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
      final details = decoded['details']?.toString();
      if (details != null &&
          details.isNotEmpty &&
          (message == fallback || message == 'Error processing QR scan')) {
        message = details;
      }
    } else if (response.body.isNotEmpty) {
      message = response.body;
    }
  } catch (_) {
    if (response.body.isNotEmpty) {
      message = response.body;
    }
  }

  if (response.statusCode == 401 || ApiException._isSessionFailure(response.statusCode, message)) {
    message = ApiException.sessionExpiredMessage;
  } else if (response.statusCode == 409) {
    if (message.contains('already recorded') || message.contains('ya fue registrado')) {
      message = 'Este beneficiario ya fue registrado para esta actividad.';
    }
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
