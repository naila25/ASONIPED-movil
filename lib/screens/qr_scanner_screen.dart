import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/activity_track.dart';
import '../models/attendance_record.dart';
import '../services/attendance_service.dart';
import '../theme/app_theme.dart';
import '../utils/api_error.dart';
import '../utils/ui_helpers.dart';
import '../widgets/app_widgets.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _cameraAvailable = false;
  bool _scanned = false;
  bool _isScanning = false;
  bool _loading = false;
  String? _statusMessage;
  bool _statusIsError = false;
  List<ActivityTrack> _activities = [];
  ActivityTrack? _selectedActivity;
  ActivityTrack? _activeScanningTrack;
  List<AttendanceRecord> _sessionRecords = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
    _bootstrap();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await Future.wait([_loadActivities(), _syncScanningState()]);
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (mounted) setState(() => _cameraAvailable = status.isGranted);
  }

  Future<void> _loadActivities() async {
    try {
      final result = await AttendanceService.fetchActivityTracks(limit: 100);
      final nonParking = result.items.where((a) => !a.isParking && !a.isArchived).toList();
      setState(() {
        _activities = nonParking;
        final current = _selectedActivity;
        if (current == null || current.isParking || !nonParking.any((a) => a.id == current.id)) {
          _selectedActivity = nonParking.isNotEmpty ? nonParking.first : null;
        }
      });
    } catch (e) {
      _setStatus('No se pudieron cargar actividades: $e', isError: true);
      if (mounted) handleApiError(context, e);
    }
  }

  Future<void> _syncScanningState() async {
    try {
      final activeTrack = await AttendanceService.fetchActiveScanningTrack();
      final validTrack = activeTrack != null && !activeTrack.isParking ? activeTrack : null;
      setState(() {
        _activeScanningTrack = validTrack;
        _isScanning = validTrack != null;
        if (validTrack != null) {
          _selectedActivity = validTrack;
        }
      });
      if (validTrack != null) {
        await _loadSessionRecords(validTrack.id);
        _startAutoRefresh();
      } else {
        _stopAutoRefresh();
      }
    } catch (e) {
      _setStatus('Error al sincronizar sesión: $e', isError: true);
    }
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_selectedActivity != null && _isScanning) {
        _loadSessionRecords(_selectedActivity!.id, silent: true);
      }
    });
  }

  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> _loadSessionRecords(int activityId, {bool silent = false}) async {
    try {
      final records = await AttendanceService.fetchAttendanceByActivity(activityId, limit: 100);
      if (mounted) setState(() => _sessionRecords = records);
    } catch (e) {
      if (!silent && mounted) handleApiError(context, e);
    }
  }

  void _setStatus(String message, {bool isError = false}) {
    setState(() {
      _statusMessage = message;
      _statusIsError = isError;
    });
  }

  Future<void> _startScanning() async {
    if (_selectedActivity == null) {
      _setStatus('Selecciona una actividad primero.', isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await AttendanceService.startScanning(_selectedActivity!.id);
      await _syncScanningState();
      _setStatus('Escaneo iniciado para ${_selectedActivity!.name}.');
    } catch (e) {
      _setStatus(e.toString(), isError: true);
      if (mounted) handleApiError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _stopScanning() async {
    final id = _selectedActivity?.id ?? _activeScanningTrack?.id;
    if (id == null) return;
    setState(() => _loading = true);
    try {
      await AttendanceService.stopScanning(id);
      _stopAutoRefresh();
      setState(() {
        _isScanning = false;
        _activeScanningTrack = null;
      });
      _setStatus('Escaneo detenido.');
    } catch (e) {
      setState(() => _isScanning = false);
      _setStatus(e.toString(), isError: true);
      if (mounted) handleApiError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _processQrData(String rawValue) async {
    if (_scanned || !_isScanning) return;
    if (_selectedActivity == null) {
      _setStatus('Selecciona una actividad antes de escanear.', isError: true);
      return;
    }
    if (_activeScanningTrack != null && _selectedActivity!.id != _activeScanningTrack!.id) {
      _setStatus(
        'La actividad no coincide con la sesión activa (${_activeScanningTrack!.name}).',
        isError: true,
      );
      return;
    }

    setState(() {
      _scanned = true;
      _statusMessage = 'Procesando código QR...';
      _statusIsError = false;
    });

    try {
      final decoded = jsonDecode(rawValue) as Map<String, dynamic>;
      final recordId = decoded['record_id'] ?? decoded['recordId'];
      final name = decoded['name'] ?? decoded['full_name'] ?? decoded['fullName'];
      final parsedRecordId = recordId is int ? recordId : int.tryParse(recordId?.toString() ?? '');
      final parsedName = name?.toString();

      if (parsedRecordId == null || parsedName == null || parsedName.isEmpty) {
        throw Exception('El QR no contiene record_id y name.');
      }

      final record = await AttendanceService.submitQrScan(
        activityTrackId: _selectedActivity!.id,
        recordId: parsedRecordId,
        name: parsedName,
      );

      setState(() {
        _sessionRecords = [record, ..._sessionRecords.where((r) => r.id != record.id)];
      });
      _setStatus('Asistencia registrada: ${record.fullName}.');
    } on ApiException catch (e) {
      if (mounted) {
        final handled = await handleApiError(context, e);
        if (!handled) _setStatus(e.message, isError: true);
      }
    } catch (e) {
      _setStatus(e.toString(), isError: true);
      if (mounted) await handleApiError(context, e);
    } finally {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _scanned = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: RefreshIndicator(
          color: AppColors.accent,
          onRefresh: _bootstrap,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              SectionCard(
                padding: const EdgeInsets.all(18),
                child: const SectionHeader(
                  icon: Icons.qr_code_scanner_rounded,
                  title: 'Escanear QR',
                  subtitle: 'Solo actividades sin estacionamiento. Escanea beneficiarios con QR de expediente.',
                ),
              ),
              if (_activities.isEmpty)
                SectionCard(
                  child: AppEmptyState(
                    icon: Icons.qr_code_scanner_outlined,
                    title: 'No hay actividades para escanear',
                    description:
                        'Las actividades con estacionamiento no aparecen aquí. Crea o selecciona una actividad sin parking.',
                  ),
                )
              else ...[
              SectionCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Actividad',
                      style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.heading),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () async {
                        final chosen = await showActivityPickerSheet<ActivityTrack>(
                          context,
                          activities: _activities,
                          label: (a) => a.name,
                          selected: _selectedActivity,
                          filter: (a) => !a.isParking,
                        );
                        if (chosen != null && mounted) {
                          setState(() => _selectedActivity = chosen);
                        }
                      },
                      style: appPrimaryButtonStyle(),
                      child: Text(_selectedActivity?.name ?? 'Seleccionar actividad'),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _loading || _isScanning ? null : _startScanning,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Iniciar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _loading || !_isScanning ? null : _stopScanning,
                            icon: const Icon(Icons.stop),
                            label: const Text('Detener'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_activeScanningTrack != null)
                      StatusBanner(
                        message: _isScanning
                            ? 'Sesión activa: ${_activeScanningTrack!.name}'
                            : 'No hay sesión activa.',
                        isWarning: !_isScanning,
                      ),
                    if (_statusMessage != null) ...[
                      const SizedBox(height: 10),
                      StatusBanner(
                        message: _statusMessage!,
                        isError: _statusIsError,
                      ),
                    ],
                  ],
                ),
              ),
              SectionCard(
                padding: const EdgeInsets.all(12),
                child: AspectRatio(
                  aspectRatio: 0.85,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: !_cameraAvailable
                        ? const Center(child: Text('Se requiere permiso de cámara.'))
                        : MobileScanner(
                            controller: _scannerController,
                            onDetect: (capture) {
                              if (!_isScanning) return;
                              for (final barcode in capture.barcodes) {
                                final rawValue = barcode.rawValue;
                                if (rawValue != null && !_scanned) {
                                  _processQrData(rawValue);
                                  break;
                                }
                              }
                            },
                          ),
                  ),
                ),
              ),
              if (_selectedActivity != null)
                PaginatedListPanel(
                  title: 'Asistencias en vivo',
                  totalCount: _sessionRecords.length,
                  pageSize: 10,
                  items: _sessionRecords.isEmpty
                      ? [
                          const AppEmptyState(
                            icon: Icons.people_outline,
                            title: 'Sin registros aún',
                            description: 'Los escaneos válidos aparecerán aquí.',
                          ),
                        ]
                      : _sessionRecords
                          .map(
                            (record) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: AppColors.accentSoft,
                                child: Icon(
                                  record.attendanceType == 'beneficiario'
                                      ? Icons.badge_outlined
                                      : Icons.person_outline,
                                  color: AppColors.accent,
                                  size: 20,
                                ),
                              ),
                              title: Text(record.fullName),
                              subtitle: Text('${record.typeLabel} · ${record.methodLabel}'),
                            ),
                          )
                          .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
