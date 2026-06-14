class ActivityTrack {
  final int id;
  final String name;
  final String? description;
  final String? eventDate;
  final String? eventTime;
  final String? location;
  final String? status;
  final bool? scanningActive;
  final bool? parkingEnabled;
  final bool? repeatAttendanceEnabled;
  final int? repeatAttendanceCooldownHours;
  final bool? archived;
  final int? totalAttendance;
  final int? beneficiariosCount;
  final int? guestsCount;
  final int? createdBy;
  final String? createdAt;

  ActivityTrack({
    required this.id,
    required this.name,
    this.description,
    this.eventDate,
    this.eventTime,
    this.location,
    this.status,
    this.scanningActive,
    this.parkingEnabled,
    this.repeatAttendanceEnabled,
    this.repeatAttendanceCooldownHours,
    this.archived,
    this.totalAttendance,
    this.beneficiariosCount,
    this.guestsCount,
    this.createdBy,
    this.createdAt,
  });

  bool get isArchived => archived == true;
  bool get isParking => parkingEnabled == true;
  bool get isScanning => scanningActive == true;

  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value == 1;
    final normalized = value.toString().trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
    return null;
  }

  ActivityTrack copyWith({
    int? id,
    String? name,
    String? description,
    String? eventDate,
    String? eventTime,
    String? location,
    String? status,
    bool? scanningActive,
    bool? parkingEnabled,
    bool? repeatAttendanceEnabled,
    int? repeatAttendanceCooldownHours,
    bool? archived,
    int? totalAttendance,
    int? beneficiariosCount,
    int? guestsCount,
  }) {
    return ActivityTrack(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      eventDate: eventDate ?? this.eventDate,
      eventTime: eventTime ?? this.eventTime,
      location: location ?? this.location,
      status: status ?? this.status,
      scanningActive: scanningActive ?? this.scanningActive,
      parkingEnabled: parkingEnabled ?? this.parkingEnabled,
      repeatAttendanceEnabled: repeatAttendanceEnabled ?? this.repeatAttendanceEnabled,
      repeatAttendanceCooldownHours:
          repeatAttendanceCooldownHours ?? this.repeatAttendanceCooldownHours,
      archived: archived ?? this.archived,
      totalAttendance: totalAttendance ?? this.totalAttendance,
      beneficiariosCount: beneficiariosCount ?? this.beneficiariosCount,
      guestsCount: guestsCount ?? this.guestsCount,
      createdBy: createdBy,
      createdAt: createdAt,
    );
  }

  factory ActivityTrack.fromJson(Map<String, dynamic> json) {
    return ActivityTrack(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? 'Actividad sin nombre',
      description: json['description']?.toString(),
      eventDate: json['event_date']?.toString(),
      eventTime: json['event_time']?.toString(),
      location: json['location']?.toString(),
      status: json['status']?.toString(),
      scanningActive: _parseBool(json['scanning_active']) ?? false,
      parkingEnabled: _parseBool(json['parking_enabled']) ?? false,
      repeatAttendanceEnabled: _parseBool(json['repeat_attendance_enabled']) ?? false,
      repeatAttendanceCooldownHours: json['repeat_attendance_cooldown_hours'] is int
          ? json['repeat_attendance_cooldown_hours']
          : int.tryParse(json['repeat_attendance_cooldown_hours']?.toString() ?? ''),
      archived: _parseBool(json['archived']) ?? false,
      totalAttendance: json['total_attendance'] is int
          ? json['total_attendance']
          : int.tryParse(json['total_attendance']?.toString() ?? ''),
      beneficiariosCount: json['beneficiarios_count'] is int
          ? json['beneficiarios_count']
          : int.tryParse(json['beneficiarios_count']?.toString() ?? ''),
      guestsCount: json['guests_count'] is int
          ? json['guests_count']
          : int.tryParse(json['guests_count']?.toString() ?? ''),
      createdBy: json['created_by'] is int ? json['created_by'] : int.tryParse(json['created_by']?.toString() ?? ''),
      createdAt: json['created_at']?.toString(),
    );
  }
}
