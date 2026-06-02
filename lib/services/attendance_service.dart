import 'dart:convert';
import '../config.dart';
import '../models/activity_track.dart';
import '../models/attendance_record.dart';
import 'api_service.dart';

class AttendanceService {
  static Future<List<ActivityTrack>> fetchActivityTracks() async {
    final response = await ApiService.get(Endpoints.activityTracks);
    if (response.statusCode != 200) {
      throw Exception('Failed to load activities: ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final items = body['activityTracks'] ?? body['data'] ?? body;
    if (items is List) {
      return items.map((item) => ActivityTrack.fromJson(item as Map<String, dynamic>)).toList();
    }

    return [];
  }

  static Future<int> createActivityTrack({
    required String name,
    required String eventDate,
    String? description,
    String? eventTime,
    String? location,
    bool? parkingEnabled,
    bool? repeatAttendanceEnabled,
    int? repeatAttendanceCooldownHours,
  }) async {
    final body = {
      'name': name,
      'event_date': eventDate,
      if (description != null) 'description': description,
      if (eventTime != null) 'event_time': eventTime,
      if (location != null) 'location': location,
      if (parkingEnabled != null) 'parking_enabled': parkingEnabled,
      if (repeatAttendanceEnabled != null) 'repeat_attendance_enabled': repeatAttendanceEnabled,
      if (repeatAttendanceCooldownHours != null) 'repeat_attendance_cooldown_hours': repeatAttendanceCooldownHours,
    };

    final response = await ApiService.post(Endpoints.activityTracks, body: body);
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create activity: ${response.body}');
    }

    final parsed = jsonDecode(response.body) as Map<String, dynamic>;
    final id = parsed['activity_track_id'] ?? parsed['id'] ?? parsed['data']?['id'];
    if (id is int) return id;
    if (id is String) return int.tryParse(id) ?? 0;
    return 0;
  }

  static Future<List<AttendanceRecord>> fetchAttendanceRecords({int limit = 50}) async {
    final response = await ApiService.get('${Endpoints.attendanceRecords}?limit=$limit');
    if (response.statusCode != 200) {
      throw Exception('Failed to load attendance records: ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final records = body['records'] ?? body['data'] ?? [];
    if (records is List) {
      return records.map((item) => AttendanceRecord.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  static Future<AttendanceRecord> submitGuestAttendance({
    required int activityTrackId,
    required String fullName,
    String? cedula,
    String? phone,
  }) async {
    final response = await ApiService.post(Endpoints.manualAttendance, body: {
      'activity_track_id': activityTrackId,
      'attendance_type': 'guest',
      'full_name': fullName,
      if (cedula != null && cedula.isNotEmpty) 'cedula': cedula,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    });

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to submit guest attendance: ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final record = body['attendanceRecord'] ?? body['data'] ?? body;
    if (record is Map<String, dynamic>) {
      return AttendanceRecord.fromJson(record);
    }
    throw Exception('Unexpected response when submitting guest attendance.');
  }

  static Future<AttendanceRecord> submitQrScan({
    required int activityTrackId,
    required int recordId,
    required String name,
  }) async {
    final response = await ApiService.post(Endpoints.qrScan, body: {
      'activityTrackId': activityTrackId,
      'qrData': {
        'record_id': recordId,
        'name': name,
      },
    });

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to process QR scan: ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final record = body['attendanceRecord'] ?? body['data'] ?? body;
    if (record is Map<String, dynamic>) {
      return AttendanceRecord.fromJson(record);
    }
    throw Exception('Unexpected response when processing QR scan.');
  }
}
