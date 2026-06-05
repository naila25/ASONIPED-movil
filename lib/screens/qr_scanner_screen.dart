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
  ActivityTrack? _activeScanningTrack;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
    _loadActivities();
    _loadActiveScanningTrack();
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

  Future<void> _loadActiveScanningTrack() async {
    try {
      final activeTrack = await AttendanceService.fetchActiveScanningTrack();
      if (activeTrack != null) {
        setState(() {
          _activeScanningTrack = activeTrack;
          _selectedActivity = activeTrack;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Unable to load active scanning track: $e';
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

    if (_activeScanningTrack != null && _selectedActivity!.id != _activeScanningTrack!.id) {
      setState(() {
        _statusMessage =
            'La actividad seleccionada no coincide con la actividad activa de escaneo. Selecciona ${_activeScanningTrack!.name} o detén el escaneo activo en el backend.';
      });
      return;
    }

    setState(() {
      _scanned = true;
      _statusMessage = 'Processing QR code...';
    });

    try {
      final decoded = jsonDecode(rawValue) as Map<String, dynamic>;
      final recordId = decoded['record_id'] ?? decoded['recordId'];
      final name = decoded['name'] ?? decoded['full_name'] ?? decoded['fullName'];

      if (recordId == null || name == null) {
        throw Exception('QR payload missing required fields.');
      }

      final parsedRecordId = recordId is int
          ? recordId
          : int.tryParse(recordId?.toString() ?? '');
      final parsedName = name?.toString();

      if (parsedRecordId == null || parsedName == null || parsedName.isEmpty) {
        throw Exception('QR payload missing required fields.');
      }

      await AttendanceService.submitQrScan(
        activityTrackId: _selectedActivity!.id,
        recordId: parsedRecordId,
        name: parsedName,
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

  void _showActivityPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Color(0xFF64748B),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _activities.length,
                  separatorBuilder: (context, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final activity = _activities[index];
                    final selected = _selectedActivity?.id == activity.id;
                    return ListTile(
                      title: Text(activity.name),
                      selected: selected,
                      selectedTileColor: const Color(0xFFF3F4F6),
                      onTap: () {
                        setState(() {
                          _selectedActivity = activity;
                        });
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
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
                    Icon(Icons.qr_code_scanner_rounded, color: accentColor),
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
                    GestureDetector(
                      onTap: () => _showActivityPicker(context),
                      child: Container(
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _selectedActivity?.name ??
                                    'Selecciona una actividad',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_activeScanningTrack != null)
                      Container(
                        decoration: BoxDecoration(
                          color: accentSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Color(0xFF256D47),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Actividad activa de escaneo: ${_activeScanningTrack!.name}. Selecciona esta actividad para evitar errores de incompatibilidad.',
                                style: const TextStyle(
                                  color: Color(0xFF164E2A),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: accentSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _statusMessage ??
                            (_activeScanningTrack == null
                                ? 'No hay actividad de escaneo activa. Inicia el escaneo en el backend antes de usar la cámara.'
                                : 'Position the QR code inside the camera frame.'),
                        style: TextStyle(
                          color:
                              _statusMessage != null &&
                                  _statusMessage!.startsWith('QR scan failed')
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
