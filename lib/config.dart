// Centralized API configuration
const String apiBaseUrl = 'https://asoniped-backend-production.up.railway.app';

String apiUrl(String path) {
  if (path.startsWith('http')) return path;
  // Ensure path starts with a slash
  final normalized = path.startsWith('/') ? path : '/$path';
  return '$apiBaseUrl$normalized';
}

class Endpoints {
  static const String login = '/users/login';
  static const String activityTracks = '/api/attendance/activity-tracks';
  static const String qrScan = '/api/attendance/attendance-records/qr-scan';
  static const String manualAttendance = '/api/attendance/attendance-records/manual';
  static const String attendanceRecords = '/api/attendance/attendance-records';
}
