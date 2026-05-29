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
    const backgroundColor = Color(0xFFF5F7FB);
    const cardColor = Colors.white;
    const headingColor = Color(0xFF0F172A);
    const textColor = Color(0xFF475569);
    const borderColor = Color(0xFFE2E8F0);
    const accentColor = Color(0xFF12A56B);
    const accentSoft = Color(0xFFE7FBF2);

    Widget sectionCard({required Widget child}) {
      return Container(
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
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            sectionCard(
              child: const Padding(
                padding: EdgeInsets.all(18),
                child: Row(
                  children: [
                    Icon(
                      Icons.qr_code_scanner_rounded,
                      color: accentColor,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Escanear QR',
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
            const SizedBox(height: 16),
            sectionCard(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Elegir actividad',
                      style: TextStyle(
                        color: headingColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Selecciona una actividad antes de abrir la cámara.',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<ActivityTrack>(
                      initialValue: _selectedActivity,
                      decoration: InputDecoration(
                        hintText: 'Select activity',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: accentColor, width: 1.4),
                        ),
                      ),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: accentColor),
                      dropdownColor: Colors.white,
                      style: const TextStyle(color: headingColor),
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
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: accentSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _statusMessage ?? 'Position the QR code inside the camera frame.',
                        style: TextStyle(
                          color: _statusMessage != null && _statusMessage!.startsWith('QR scan failed')
                              ? Colors.red.shade700
                              : const Color(0xFF166534),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            sectionCard(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: AspectRatio(
                  aspectRatio: 0.78,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _cameraAvailable
                        ? MobileScanner(
                          controller: _scannerController,
                          onDetect: (capture) {
                            for (final barcode in capture.barcodes) {
                              final rawValue = barcode.rawValue;
                              if (rawValue != null && !_scanned) {
                                _processQrData(rawValue);
                                break;
                              }
                            }
                          },
                        )
                        : const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                'Camera permission is required to scan QR codes.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: headingColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
