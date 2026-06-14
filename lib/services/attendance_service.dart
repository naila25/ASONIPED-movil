import 'dart:convert';
import '../config.dart';
import '../models/activity_track.dart';
import '../models/attendance_record.dart';
import '../models/parking_registration.dart';
import '../utils/api_error.dart';
import 'api_service.dart';

class AttendanceService {
  static List<ActivityTrack> _parseActivityList(dynamic items) {
    if (items is! List) return [];
    return items.map((item) => ActivityTrack.fromJson(item as Map<String, dynamic>)).toList();
  }

  static List<AttendanceRecord> _parseRecordList(dynamic records) {
    if (records is! List) return [];
    return records.map((item) => AttendanceRecord.fromJson(item as Map<String, dynamic>)).toList();
  }

  static Future<PaginatedResult<ActivityTrack>> fetchActivityTracks({
    int page = 1,
    int limit = 50,
    String? status,
    bool includeArchived = false,
    String? search,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'limit': '$limit',
      if (status != null) 'status': status,
      if (includeArchived) 'includeArchived': 'true',
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    };
    final query = params.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&');
    final response = await ApiService.get('${Endpoints.activityTracks}?$query');
    ensureSuccess(response, fallback: 'No se pudieron cargar las actividades');

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final items = _parseActivityList(body['activityTracks']);
    return PaginatedResult(
      items: items,
      total: body['total'] is int ? body['total'] : int.tryParse(body['total']?.toString() ?? '') ?? items.length,
      page: body['page'] is int ? body['page'] : page,
      limit: body['limit'] is int ? body['limit'] : limit,
      totalPages: body['totalPages'] is int ? body['totalPages'] : 1,
    );
  }

  static Future<ActivityTrack?> fetchActivityById(int id) async {
    final response = await ApiService.get(Endpoints.activityTrack(id));
    if (response.statusCode == 404) return null;
    ensureSuccess(response, fallback: 'No se pudo cargar la actividad');
    return ActivityTrack.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  static Future<ActivityTrack?> fetchActiveScanningTrack() async {
    final response = await ApiService.get(Endpoints.activeScanningTrack);
    if (response.statusCode != 200) return null;

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final activeTrack = body['activeTrack'];
    if (activeTrack is Map<String, dynamic>) {
      return ActivityTrack.fromJson(activeTrack);
    }
    return null;
  }

  static Future<int> createActivityTrack({
    required String name,
    required String eventDate,
    String? description,
    String? eventTime,
    String? location,
    bool parkingEnabled = false,
    bool repeatAttendanceEnabled = false,
    int? repeatAttendanceCooldownHours,
  }) async {
    final response = await ApiService.post(Endpoints.activityTracks, body: {
      'name': name,
      'event_date': eventDate,
      'description': description,
      'event_time': eventTime,
      'location': location,
      'parking_enabled': parkingEnabled,
      'repeat_attendance_enabled': repeatAttendanceEnabled,
      if (repeatAttendanceEnabled && repeatAttendanceCooldownHours != null)
        'repeat_attendance_cooldown_hours': repeatAttendanceCooldownHours,
    });
    ensureSuccess(response, fallback: 'No se pudo crear la actividad');

    final parsed = jsonDecode(response.body) as Map<String, dynamic>;
    final id = parsed['activity_track_id'] ?? parsed['id'];
    if (id is int) return id;
    return int.tryParse(id?.toString() ?? '') ?? 0;
  }

  static Future<void> updateActivityTrack(int id, Map<String, dynamic> data) async {
    final response = await ApiService.put(Endpoints.activityTrack(id), body: data);
    ensureSuccess(response, fallback: 'No se pudo actualizar la actividad');
  }

  static Future<void> archiveActivityTrack(int id) async {
    final response = await ApiService.put(Endpoints.archiveActivity(id));
    ensureSuccess(response, fallback: 'No se pudo archivar la actividad');
  }

  static Future<void> unarchiveActivityTrack(int id) async {
    final response = await ApiService.put(Endpoints.unarchiveActivity(id));
    ensureSuccess(response, fallback: 'No se pudo restaurar la actividad');
  }

  static Future<void> startScanning(int activityTrackId) async {
    final response = await ApiService.put(Endpoints.startScanning(activityTrackId));
    ensureSuccess(response, fallback: 'No se pudo iniciar el escaneo');
  }

  static Future<void> stopScanning(int activityTrackId) async {
    final response = await ApiService.put(Endpoints.stopScanning(activityTrackId));
    ensureSuccess(response, fallback: 'No se pudo detener el escaneo');
  }

  static Future<ParkingPublicLink> fetchParkingLink(int activityTrackId) async {
    final response = await ApiService.get(Endpoints.parkingLink(activityTrackId));
    ensureSuccess(response, fallback: 'No se pudo obtener el enlace de estacionamiento');
    return ParkingPublicLink.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  static Future<List<ParkingRegistration>> fetchParkingRegistrations(int activityTrackId) async {
    final response = await ApiService.get(Endpoints.parkingRegistrations(activityTrackId));
    ensureSuccess(response, fallback: 'No se pudieron cargar los registros de estacionamiento');
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final rows = body['registrations'];
    if (rows is! List) return [];
    return rows.map((e) => ParkingRegistration.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<int> submitParkingRegistration({
    required int activityTrackId,
    required String plate,
    String? fullName,
    String? cedula,
    String? phone,
  }) async {
    final response = await ApiService.post(
      Endpoints.parkingRegistrations(activityTrackId),
      body: {
        'plate': plate,
        if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
        if (cedula != null && cedula.isNotEmpty) 'cedula': cedula,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
    );
    ensureSuccess(response, fallback: 'No se pudo registrar el vehículo');
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final id = body['id'];
    if (id is int) return id;
    return int.tryParse(id?.toString() ?? '') ?? 0;
  }

  static Future<PaginatedResult<AttendanceRecord>> fetchAttendanceRecords({
    int page = 1,
    int limit = 50,
    int? activityTrackId,
    String? attendanceType,
    String? attendanceMethod,
    String? startDate,
    String? endDate,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'limit': '$limit',
      if (activityTrackId != null) 'activityTrackId': '$activityTrackId',
      if (attendanceType != null) 'attendanceType': attendanceType,
      if (attendanceMethod != null) 'attendanceMethod': attendanceMethod,
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
    };
    final query = params.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&');
    final response = await ApiService.get('${Endpoints.attendanceRecords}?$query');
    ensureSuccess(response, fallback: 'No se pudieron cargar los registros');

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final items = _parseRecordList(body['records']);
    return PaginatedResult(
      items: items,
      total: body['total'] is int ? body['total'] : items.length,
      page: body['page'] is int ? body['page'] : page,
      limit: body['limit'] is int ? body['limit'] : limit,
      totalPages: body['totalPages'] is int ? body['totalPages'] : 1,
    );
  }

  static Future<List<AttendanceRecord>> fetchAttendanceByActivity(int activityTrackId, {int limit = 100}) async {
    final response = await ApiService.get('${Endpoints.attendanceByActivity(activityTrackId)}?limit=$limit');
    ensureSuccess(response, fallback: 'No se pudieron cargar las asistencias de la actividad');
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseRecordList(body['records']);
  }

  static Future<AttendanceStats> fetchAttendanceStats(int activityTrackId) async {
    final response = await ApiService.get(Endpoints.attendanceStats(activityTrackId));
    ensureSuccess(response, fallback: 'No se pudieron cargar las estadísticas');
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return AttendanceStats.fromJson(body['stats'] as Map<String, dynamic>);
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
    ensureSuccess(response, fallback: 'No se pudo registrar la asistencia');

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final record = body['attendanceRecord'] ?? body['data'] ?? body;
    if (record is Map<String, dynamic>) {
      return AttendanceRecord.fromJson(record);
    }
    throw ApiException(message: 'Respuesta inesperada del servidor', statusCode: response.statusCode);
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
    ensureSuccess(response, fallback: 'No se pudo procesar el código QR');

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final record = body['attendanceRecord'] ?? body['data'] ?? body;
    if (record is Map<String, dynamic>) {
      return AttendanceRecord.fromJson(record);
    }
    throw ApiException(message: 'Respuesta inesperada del servidor', statusCode: response.statusCode);
  }
}
