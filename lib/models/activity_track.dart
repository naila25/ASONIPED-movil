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
    this.createdBy,
    this.createdAt,
  });

  factory ActivityTrack.fromJson(Map<String, dynamic> json) {
    return ActivityTrack(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? 'Unnamed activity',
      description: json['description']?.toString(),
      eventDate: json['event_date']?.toString(),
      eventTime: json['event_time']?.toString(),
      location: json['location']?.toString(),
      status: json['status']?.toString(),
      scanningActive: json['scanning_active'] == true || json['scanning_active']?.toString() == 'true',
      parkingEnabled: json['parking_enabled'] == true || json['parking_enabled']?.toString() == 'true',
      createdBy: json['created_by'] is int ? json['created_by'] : int.tryParse(json['created_by']?.toString() ?? ''),
      createdAt: json['created_at']?.toString(),
    );
  }
}
