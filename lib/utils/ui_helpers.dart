import 'package:flutter/material.dart';
import 'api_error.dart';

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

bool handleApiError(BuildContext context, Object error, {VoidCallback? onUnauthorized}) {
  final message = error is ApiException ? error.message : error.toString();
  if (error is ApiException && error.isUnauthorized) {
    onUnauthorized?.call();
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    }
    return true;
  }
  showAppSnackBar(context, message, isError: true);
  return false;
}
