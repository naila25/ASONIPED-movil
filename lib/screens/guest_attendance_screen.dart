import 'package:flutter/material.dart';
import '../models/activity_track.dart';
import '../services/attendance_service.dart';

class GuestAttendanceScreen extends StatefulWidget {
  const GuestAttendanceScreen({super.key});

  @override
  State<GuestAttendanceScreen> createState() => _GuestAttendanceScreenState();
}

class _GuestAttendanceScreenState extends State<GuestAttendanceScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _message;
  List<ActivityTrack> _activities = [];
  ActivityTrack? _selectedActivity;
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _cedulaController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _cedulaController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadActivities() async {
    try {
      final items = await AttendanceService.fetchActivityTracks();
      setState(() {
        _activities = items;
        if (_selectedActivity == null && _activities.isNotEmpty) {
          _selectedActivity = _activities.first;
        }
      });
    } catch (e) {
      setState(() {
        _message = 'Unable to load activities: $e';
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedActivity == null) {
      setState(() {
        _message = 'Please select an activity first.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final record = await AttendanceService.submitGuestAttendance(
        activityTrackId: _selectedActivity!.id,
        fullName: _fullNameController.text.trim(),
        cedula: _cedulaController.text.trim().isEmpty
            ? null
            : _cedulaController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
      );

      setState(() {
        _message = 'Guest attendance recorded for ${record.fullName}.';
        _fullNameController.clear();
        _cedulaController.clear();
        _phoneController.clear();
      });
    } catch (e) {
      setState(() {
        _message = 'Failed to record guest attendance: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Guest / Manual Attendance',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<ActivityTrack>(
                initialValue: _selectedActivity,
                decoration: const InputDecoration(labelText: 'Select activity'),
                items: _activities
                    .map(
                      (activity) => DropdownMenuItem(
                        value: activity,
                        child: Text(activity.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedActivity = value;
                  });
                },
                validator: (_) =>
                    _selectedActivity == null ? 'Choose an activity' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Full name'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter full name'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cedulaController,
                decoration: const InputDecoration(
                  labelText: 'Cédula (optional)',
                ),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone (optional)',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Record attendance'),
              ),
              if (_message != null) ...[
                const SizedBox(height: 16),
                Text(
                  _message!,
                  style: TextStyle(
                    color: _message!.startsWith('Failed')
                        ? Colors.red
                        : Colors.green,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
