class ParkingRegistration {
  final int id;
  final int activityTrackId;
  final String plateRaw;
  final String plateNormalized;
  final String? fullName;
  final String? cedula;
  final String? phone;
  final String source;
  final String? createdAt;

  ParkingRegistration({
    required this.id,
    required this.activityTrackId,
    required this.plateRaw,
    required this.plateNormalized,
    this.fullName,
    this.cedula,
    this.phone,
    required this.source,
    this.createdAt,
  });

  factory ParkingRegistration.fromJson(Map<String, dynamic> json) {
    return ParkingRegistration(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      activityTrackId: json['activity_track_id'] is int
          ? json['activity_track_id']
          : int.tryParse(json['activity_track_id']?.toString() ?? '') ?? 0,
      plateRaw: json['plate_raw']?.toString() ?? '',
      plateNormalized: json['plate_normalized']?.toString() ?? '',
      fullName: json['full_name']?.toString(),
      cedula: json['cedula']?.toString(),
      phone: json['phone']?.toString(),
      source: json['source']?.toString() ?? 'admin',
      createdAt: json['created_at']?.toString(),
    );
  }
}

class ParkingPublicLink {
  final String token;
  final String expiresAt;

  ParkingPublicLink({required this.token, required this.expiresAt});

  factory ParkingPublicLink.fromJson(Map<String, dynamic> json) {
    return ParkingPublicLink(
      token: json['token']?.toString() ?? '',
      expiresAt: json['expiresAt']?.toString() ?? '',
    );
  }
}

class PaginatedResult<T> {
  final List<T> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  PaginatedResult({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });
}

class AttendanceStats {
  final int totalAttendance;
  final int beneficiariosCount;
  final int guestsCount;
  final int qrScansCount;
  final int manualEntriesCount;

  AttendanceStats({
    required this.totalAttendance,
    required this.beneficiariosCount,
    required this.guestsCount,
    required this.qrScansCount,
    required this.manualEntriesCount,
  });

  factory AttendanceStats.fromJson(Map<String, dynamic> json) {
    return AttendanceStats(
      totalAttendance: _int(json['total_attendance']),
      beneficiariosCount: _int(json['beneficiarios_count']),
      guestsCount: _int(json['guests_count']),
      qrScansCount: _int(json['qr_scans_count']),
      manualEntriesCount: _int(json['manual_entries_count']),
    );
  }

  static int _int(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
}
