import 'package:flutter/material.dart';
import 'api_error.dart';
import '../services/auth_service.dart';

void showAppSnackBar(BuildContext context, String message, {bool isError = false}) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red.shade700 : const Color(0xFF166534),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/// Returns true when the error was handled as an expired/invalid session.
Future<bool> handleApiError(
  BuildContext context,
  Object error, {
  VoidCallback? onUnauthorized,
}) async {
  if (error is ApiException && error.requiresReLogin) {
    onUnauthorized?.call();
    await AuthService.deleteToken();
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (_) => false,
        arguments: AuthService.sessionExpiredMessage,
      );
    }
    return true;
  }

  final message = error is ApiException ? error.message : error.toString();
  showAppSnackBar(context, message, isError: true);
  return false;
}

bool isSessionExpiredError(Object error) {
  return error is ApiException && error.requiresReLogin;
}
