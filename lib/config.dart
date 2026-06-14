// Centralized API configuration
const String apiBaseUrl = 'https://asoniped-backend-production.up.railway.app';

/// Public web app URL used to build parking links (/estacionamiento/:token).
/// Must match the production frontend origin (same as web: window.location.origin).
const String webAppBaseUrl = 'https://asoniped.org';

String apiUrl(String path) {
  if (path.startsWith('http')) return path;
  final normalized = path.startsWith('/') ? path : '/$path';
  return '$apiBaseUrl$normalized';
}

String parkingPublicUrl(String token) {
  return '$webAppBaseUrl/estacionamiento/${Uri.encodeComponent(token)}';
}

class Endpoints {
  static const String login = '/users/login';
  static const String activityTracks = '/api/attendance/activity-tracks';
  static const String activeScanningTrack = '/api/attendance/activity-tracks/active-scanning';
  static const String qrScan = '/api/attendance/attendance-records/qr-scan';
  static const String manualAttendance = '/api/attendance/attendance-records/manual';
  static const String attendanceRecords = '/api/attendance/attendance-records';

  static String activityTrack(int id) => '$activityTracks/$id';
  static String archiveActivity(int id) => '$activityTracks/$id/archive';
  static String unarchiveActivity(int id) => '$activityTracks/$id/unarchive';
  static String startScanning(int id) => '$activityTracks/$id/start-scanning';
  static String stopScanning(int id) => '$activityTracks/$id/stop-scanning';
  static String parkingLink(int id) => '$activityTracks/$id/parking-link';
  static String parkingRegistrations(int id) => '$activityTracks/$id/parking-registrations';
  static String attendanceByActivity(int id) => '$attendanceRecords/activity-track/$id';
  static String attendanceStats(int id) => '$attendanceRecords/activity-track/$id/stats';
}
