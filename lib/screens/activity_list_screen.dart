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
    return RefreshIndicator(
      onRefresh: _loadActivities,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            )
          : _activities.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Center(child: Text('No activities available.')),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _activities.length,
              itemBuilder: (context, index) {
                final activity = _activities[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(activity.name),
                    subtitle: Text(
                      '${activity.eventDate ?? 'Date unknown'} • ${activity.location ?? 'Location not set'}',
                    ),
                    trailing: Text(activity.status?.toUpperCase() ?? 'UNKNOWN'),
                  ),
                );
              },
            ),
    );
  }
}
