import '../config.dart';
import 'api_service.dart';
import 'auth_service.dart';

/// Validates stored session before entering the app.
Future<SessionStatus> resolveSession() async {
  final token = await AuthService.getToken();
  if (token == null || token.isEmpty) return SessionStatus.none;

  if (AuthService.isTokenExpired(token)) {
    await AuthService.deleteToken();
    return SessionStatus.expired;
  }

  try {
    final response = await ApiService.get(
      '${Endpoints.activityTracks}?page=1&limit=1',
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return SessionStatus.valid;
    }
    if (_isAuthFailureStatus(response.statusCode, response.body)) {
      await AuthService.deleteToken();
      return SessionStatus.expired;
    }
    return SessionStatus.valid;
  } catch (_) {
    return SessionStatus.valid;
  }
}

bool _isAuthFailureStatus(int statusCode, String body) {
  if (statusCode == 401) return true;
  if (statusCode != 403) return false;
  final lower = body.toLowerCase();
  return lower.contains('invalid token') ||
      lower.contains('session invalidated') ||
      lower.contains('no token provided') ||
      lower.contains('unauthorized');
}
