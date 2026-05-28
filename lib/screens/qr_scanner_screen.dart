import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/activity_track.dart';
import '../services/attendance_service.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _cameraAvailable = false;
  bool _scanned = false;
  String? _statusMessage;
  List<ActivityTrack> _activities = [];
  ActivityTrack? _selectedActivity;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
    _loadActivities();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      _cameraAvailable = status.isGranted;
    });
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
        _statusMessage = 'Unable to load activities: $e';
      });
    }
  }

  Future<void> _processQrData(String rawValue) async {
    if (_scanned) return;
    if (_selectedActivity == null) {
      setState(() {
        _statusMessage = 'Select an activity before scanning.';
      });
      return;
    }

    setState(() {
      _scanned = true;
      _statusMessage = 'Processing QR code...';
    });

    try {
      final decoded = jsonDecode(rawValue);
      final recordId = decoded['record_id'];
      final name = decoded['name'];

      if (recordId == null || name == null) {
        throw Exception('QR payload missing required fields.');
      }

      await AttendanceService.submitQrScan(
        activityTrackId: _selectedActivity!.id,
        recordId: recordId as int,
        name: name.toString(),
      );

      setState(() {
        _statusMessage = 'Check-in successful for $name.';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'QR scan failed: $e';
      });
    } finally {
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        _scanned = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'QR Attendance Scanner',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
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
                onChanged: (value) => setState(() {
                  _selectedActivity = value;
                }),
              ),
              const SizedBox(height: 12),
              if (_statusMessage != null)
                Text(_statusMessage!, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
        Expanded(
          child: _cameraAvailable
              ? MobileScanner(
                  controller: _scannerController,
                  onDetect: (barcode, arguments) {
                    final rawValue = barcode.rawValue;
                    if (rawValue != null && !_scanned) {
                      _processQrData(rawValue);
                    }
                  },
                )
              : const Center(
                  child: Text(
                    'Camera permission is required to scan QR codes.',
                    textAlign: TextAlign.center,
                  ),
                ),
        ),
      ],
    );
  }
}
