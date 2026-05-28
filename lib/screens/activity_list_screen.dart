import 'package:flutter/material.dart';
import '../models/activity_track.dart';
import '../services/attendance_service.dart';

class ActivityListScreen extends StatefulWidget {
  const ActivityListScreen({super.key});

  @override
  State<ActivityListScreen> createState() => _ActivityListScreenState();
}

class _ActivityListScreenState extends State<ActivityListScreen> {
  bool _loading = true;
  String? _error;
  List<ActivityTrack> _activities = [];

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await AttendanceService.fetchActivityTracks();
      setState(() {
        _activities = items;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFF5F7FB);
    const cardColor = Colors.white;
    const headingColor = Color(0xFF0F172A);
    const textColor = Color(0xFF475569);
    const borderColor = Color(0xFFE2E8F0);
    const accentColor = Color(0xFF12A56B);
    const accentSoft = Color(0xFFE7FBF2);

    Widget sectionCard({required Widget child}) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F0F172A),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: child,
      );
    }

    return Container(
      color: backgroundColor,
      child: SafeArea(
        child: RefreshIndicator(
          color: accentColor,
          onRefresh: _loadActivities,
          child: _loading
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 180),
                    Center(child: CircularProgressIndicator()),
                  ],
                )
              : _error != null
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: [
                        sectionCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                    )
                  : _activities.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          children: [
                            sectionCard(
                              child: const Padding(
                                padding: EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.event_note_rounded,
                                      size: 56,
                                      color: Color(0xFFCBD5E1),
                                    ),
                                    SizedBox(height: 14),
                                    Text(
                                      'No activities available.',
                                      style: TextStyle(
                                        color: headingColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'Pull to refresh and try again.',
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          children: [
                            sectionCard(
                              child: const Padding(
                                padding: EdgeInsets.all(18),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.list_alt_rounded,
                                      color: accentColor,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Actividades',
                                      style: TextStyle(
                                        color: headingColor,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            ..._activities.map(
                              (activity) => Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: borderColor),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x0F0F172A),
                                      blurRadius: 18,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  title: Text(
                                    activity.name,
                                    style: const TextStyle(
                                      color: headingColor,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${activity.eventDate ?? 'Date unknown'} • ${activity.location ?? 'Location not set'}',
                                    style: const TextStyle(color: textColor),
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: accentSoft,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      activity.status?.toUpperCase() ?? 'UNKNOWN',
                                      style: const TextStyle(
                                        color: accentColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
        ),
      ),
    );
  }
}
