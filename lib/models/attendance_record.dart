class AttendanceRecord {
  final int id;
  final int activityTrackId;
  final int? recordId;
  final String attendanceType;
  final String fullName;
  final String? cedula;
  final String? phone;
  final String attendanceMethod;
  final String? createdAt;
  final String? activityTrackName;
  final String? activityTrackDate;

  AttendanceRecord({
    required this.id,
    required this.activityTrackId,
    this.recordId,
    required this.attendanceType,
    required this.fullName,
    this.cedula,
    this.phone,
    required this.attendanceMethod,
    this.createdAt,
    this.activityTrackName,
    this.activityTrackDate,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      activityTrackId: json['activity_track_id'] is int
          ? json['activity_track_id']
          : int.tryParse(json['activity_track_id']?.toString() ?? '') ?? 0,
      recordId: json['record_id'] is int ? json['record_id'] : int.tryParse(json['record_id']?.toString() ?? ''),
      attendanceType: json['attendance_type']?.toString() ?? 'guest',
      fullName: json['full_name']?.toString() ?? 'Desconocido',
      cedula: json['cedula']?.toString(),
      phone: json['phone']?.toString(),
      attendanceMethod: json['attendance_method']?.toString() ?? 'manual_form',
      createdAt: json['created_at']?.toString() ?? json['scanned_at']?.toString(),
      activityTrackName: json['activity_track_name']?.toString(),
      activityTrackDate: json['activity_track_date']?.toString(),
    );
  }

  String get typeLabel => attendanceType == 'beneficiario' ? 'Beneficiario' : 'Invitado';

  String get methodLabel => attendanceMethod == 'qr_scan' ? 'QR' : 'Manual';
}
