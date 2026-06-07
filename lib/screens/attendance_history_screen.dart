import 'package:flutter/material.dart';
import '../models/activity_track.dart';
import '../models/attendance_record.dart';
import '../models/parking_registration.dart';
import '../services/attendance_service.dart';
import '../theme/app_theme.dart';
import '../utils/ui_helpers.dart';
import '../widgets/app_widgets.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  bool _loading = true;
  String? _error;
  List<ActivityTrack> _activities = [];
  ActivityTrack? _selectedActivity;
  List<AttendanceRecord> _records = [];
  List<ParkingRegistration> _parkingRecords = [];
  AttendanceStats? _stats;
  String? _typeFilter;
  String? _methodFilter;

  bool get _parkingMode => _selectedActivity?.isParking == true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await AttendanceService.fetchActivityTracks(limit: 100);
      setState(() => _activities = result.items);
      await _loadRecords();
    } catch (e) {
      setState(() => _error = e.toString());
      if (mounted) handleApiError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadRecords() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_selectedActivity != null && _selectedActivity!.isParking) {
        final parking = await AttendanceService.fetchParkingRegistrations(_selectedActivity!.id);
        setState(() {
          _parkingRecords = parking;
          _records = [];
          _stats = null;
        });
      } else {
        final result = await AttendanceService.fetchAttendanceRecords(
          limit: 200,
          activityTrackId: _selectedActivity?.id,
          attendanceType: _typeFilter,
          attendanceMethod: _methodFilter,
        );
        AttendanceStats? stats;
        if (_selectedActivity != null) {
          stats = await AttendanceService.fetchAttendanceStats(_selectedActivity!.id);
        }
        setState(() {
          _records = result.items;
          _parkingRecords = [];
          _stats = stats;
        });
      }
    } catch (e) {
      setState(() => _error = e.toString());
      if (mounted) handleApiError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickActivity() async {
    final chosen = await showModalBottomSheet<ActivityTrack?>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                title: const Text('Todas las actividades'),
                onTap: () => Navigator.pop(ctx, null),
              ),
              ..._activities.map(
                (a) => ListTile(
                  title: Text(a.name),
                  subtitle: Text(a.isParking ? 'Estacionamiento' : (a.eventDate ?? '')),
                  onTap: () => Navigator.pop(ctx, a),
                ),
              ),
            ],
          ),
        );
      },
    );
    setState(() => _selectedActivity = chosen);
    await _loadRecords();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: RefreshIndicator(
          color: AppColors.accent,
          onRefresh: _loadRecords,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              SectionCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionHeader(
                      icon: Icons.receipt_long_rounded,
                      title: 'Reportes',
                      subtitle: 'Filtra por actividad, tipo y método de registro.',
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton(
                      onPressed: _pickActivity,
                      child: Text(_selectedActivity?.name ?? 'Todas las actividades'),
                    ),
                    if (!_parkingMode) ...[
                      const SizedBox(height: 12),
                      DropdownButton<String?>(
                        isExpanded: true,
                        value: _typeFilter,
                        hint: const Text('Tipo de asistencia'),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Todos los tipos')),
                          DropdownMenuItem(value: 'beneficiario', child: Text('Beneficiarios')),
                          DropdownMenuItem(value: 'guest', child: Text('Invitados')),
                        ],
                        onChanged: (v) {
                          setState(() => _typeFilter = v);
                          _loadRecords();
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButton<String?>(
                        isExpanded: true,
                        value: _methodFilter,
                        hint: const Text('Método de registro'),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Todos los métodos')),
                          DropdownMenuItem(value: 'qr_scan', child: Text('QR')),
                          DropdownMenuItem(value: 'manual_form', child: Text('Manual')),
                        ],
                        onChanged: (v) {
                          setState(() => _methodFilter = v);
                          _loadRecords();
                        },
                      ),
                    ],
                  ],
                ),
              ),
              if (_stats != null)
                SectionCard(
                  padding: const EdgeInsets.all(18),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _statChip('Total', '${_stats!.totalAttendance}'),
                      _statChip('Benef.', '${_stats!.beneficiariosCount}'),
                      _statChip('Invitados', '${_stats!.guestsCount}'),
                      _statChip('QR', '${_stats!.qrScansCount}'),
                      _statChip('Manual', '${_stats!.manualEntriesCount}'),
                    ],
                  ),
                ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                SectionCard(
                  padding: const EdgeInsets.all(16),
                  child: StatusBanner(message: _error!, isError: true),
                )
              else if (_parkingMode && _parkingRecords.isEmpty)
                SectionCard(
                  child: AppEmptyState(
                    icon: Icons.local_parking_outlined,
                    title: 'Sin vehículos registrados',
                    description: 'No hay registros de estacionamiento para esta actividad.',
                  ),
                )
              else if (!_parkingMode && _records.isEmpty)
                SectionCard(
                  child: AppEmptyState(
                    icon: Icons.history_rounded,
                    title: 'Sin registros',
                    description: 'Ajusta los filtros o selecciona otra actividad.',
                  ),
                )
              else if (_parkingMode)
                ..._parkingRecords.map(
                  (r) => SectionCard(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.plateRaw, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        if (r.fullName != null && r.fullName!.isNotEmpty)
                          Text(r.fullName!, style: const TextStyle(color: AppColors.text)),
                        Text(
                          [r.cedula, r.phone, r.createdAt].where((e) => e != null && e.isNotEmpty).join(' · '),
                          style: const TextStyle(color: AppColors.text, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._records.map(
                  (record) => SectionCard(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.accentSoft,
                          child: Icon(
                            record.attendanceType == 'beneficiario'
                                ? Icons.badge_outlined
                                : Icons.person_outline,
                            color: AppColors.accent,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                record.fullName,
                                style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.heading),
                              ),
                              Text(
                                [
                                  record.typeLabel,
                                  record.methodLabel,
                                  if (record.activityTrackName != null) record.activityTrackName,
                                  record.createdAt,
                                ].whereType<String>().join(' · '),
                                style: const TextStyle(color: AppColors.text, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text('$label: $value', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.accent)),
    );
  }
}
