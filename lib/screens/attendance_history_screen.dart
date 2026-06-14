import 'package:flutter/material.dart';
import '../models/activity_track.dart';
import '../models/attendance_record.dart';
import '../models/parking_registration.dart';
import '../services/attendance_service.dart';
import '../theme/app_theme.dart';
import '../utils/ui_helpers.dart';
import '../widgets/app_widgets.dart';
import '../widgets/attendance_charts.dart';

enum _ReportTab { resumen, registros }

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
  _ReportTab _tab = _ReportTab.resumen;
  final TextEditingController _searchCtrl = TextEditingController();

  bool get _parkingMode => _selectedActivity?.isParking == true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await AttendanceService.fetchActivityTracks(limit: 100);
      setState(() => _activities = result.items.where((a) => !a.isArchived).toList());
      await _loadRecords();
    } catch (e) {
      if (mounted) {
        final handled = await handleApiError(context, e);
        if (!handled) setState(() => _error = e.toString());
      }
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
      if (mounted) {
        final handled = await handleApiError(context, e);
        if (!handled) setState(() => _error = e.toString());
      }
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
                  trailing: a.isParking
                      ? const Icon(Icons.local_parking, color: AppColors.parking, size: 18)
                      : null,
                  onTap: () => Navigator.pop(ctx, a),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted) return;
    setState(() {
      _selectedActivity = chosen;
      _searchCtrl.clear();
    });
    await _loadRecords();
  }

  List<AttendanceRecord> get _filteredRecords {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _records;
    return _records.where((r) {
      return r.fullName.toLowerCase().contains(q) ||
          (r.cedula?.toLowerCase().contains(q) ?? false) ||
          (r.activityTrackName?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  List<ParkingRegistration> get _filteredParking {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _parkingRecords;
    return _parkingRecords.where((r) {
      return r.plateRaw.toLowerCase().contains(q) ||
          (r.fullName?.toLowerCase().contains(q) ?? false) ||
          (r.cedula?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  Widget _buildCharts() {
    if (_parkingMode) {
      return AttendanceCharts(
        isParking: true,
        parkingTotal: _parkingRecords.length,
        parkingSourceSlices: buildParkingSourceSlices(_parkingRecords),
        typeSlices: const [],
        methodSlices: const [],
      );
    }

    final typeSlices = _stats != null
        ? buildTypeSlicesFromStats(
            beneficiarios: _stats!.beneficiariosCount,
            guests: _stats!.guestsCount,
          )
        : buildTypeSlicesFromRecords(_records);

    final methodSlices = _stats != null
        ? buildMethodSlicesFromStats(
            qrScans: _stats!.qrScansCount,
            manualEntries: _stats!.manualEntriesCount,
          )
        : buildMethodSlicesFromRecords(_records);

    final hasData = typeSlices.any((s) => s.value > 0) || methodSlices.any((s) => s.value > 0);
    if (!hasData) {
      return SectionCard(
        child: AppEmptyState(
          icon: Icons.bar_chart_outlined,
          title: 'Sin datos para gráficos',
          description: 'Selecciona una actividad con registros o ajusta los filtros.',
        ),
      );
    }

    return AttendanceCharts(typeSlices: typeSlices, methodSlices: methodSlices);
  }

  Widget _buildSummaryTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_stats != null && !_parkingMode)
          SectionCard(
            padding: const EdgeInsets.all(18),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _statChip('Total', '${_stats!.totalAttendance}'),
                _statChip('Benef.', '${_stats!.beneficiariosCount}'),
                _statChip('Invitados', '${_stats!.guestsCount}'),
                _statChip('QR', '${_stats!.qrScansCount}'),
                _statChip('Manual', '${_stats!.manualEntriesCount}'),
              ],
            ),
          ),
        if (!_parkingMode && _stats == null && _records.isNotEmpty)
          SectionCard(
            padding: const EdgeInsets.all(18),
            child: Text(
              '${_records.length} registros en el rango actual',
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.heading),
            ),
          ),
        if (_parkingMode)
          SectionCard(
            padding: const EdgeInsets.all(18),
            child: Text(
              '${_parkingRecords.length} vehículo${_parkingRecords.length == 1 ? '' : 's'} registrados',
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.heading),
            ),
          ),
        const SizedBox(height: 12),
        _buildCharts(),
      ],
    );
  }

  Widget _buildRecordsTab() {
    final items = _parkingMode
        ? _filteredParking
            .map(
              (r) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.parkingSoft,
                  child: const Icon(Icons.directions_car, color: AppColors.parking, size: 18),
                ),
                title: Text(r.plateRaw, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  [r.fullName, r.cedula, r.createdAt]
                      .where((e) => e != null && e.isNotEmpty)
                      .join(' · '),
                ),
              ),
            )
            .toList()
        : _filteredRecords
            .map(
              (record) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.accentSoft,
                  child: Icon(
                    record.attendanceType == 'beneficiario' ? Icons.badge_outlined : Icons.person_outline,
                    color: AppColors.accent,
                    size: 20,
                  ),
                ),
                title: Text(record.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  [
                    record.typeLabel,
                    record.methodLabel,
                    if (record.activityTrackName != null) record.activityTrackName,
                    record.createdAt,
                  ].whereType<String>().join(' · '),
                ),
              ),
            )
            .toList();

    if (!_loading && _error == null && items.isEmpty) {
      return SectionCard(
        child: AppEmptyState(
          icon: _parkingMode ? Icons.local_parking_outlined : Icons.history_rounded,
          title: 'Sin registros',
          description: 'Prueba otro filtro o término de búsqueda.',
        ),
      );
    }

    return PaginatedListPanel(
      title: _parkingMode ? 'Detalle de vehículos' : 'Detalle de asistencias',
      totalCount: items.length,
      pageSize: 15,
      items: items,
    );
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
                      subtitle: 'Resumen visual y detalle paginado por actividad.',
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: _pickActivity,
                      icon: const Icon(Icons.filter_list),
                      label: Text(_selectedActivity?.name ?? 'Todas las actividades'),
                    ),
                    if (!_parkingMode) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilterChip(
                            label: const Text('Todos'),
                            selected: _typeFilter == null && _methodFilter == null,
                            onSelected: (_) {
                              setState(() {
                                _typeFilter = null;
                                _methodFilter = null;
                              });
                              _loadRecords();
                            },
                          ),
                          FilterChip(
                            label: const Text('Beneficiarios'),
                            selected: _typeFilter == 'beneficiario',
                            onSelected: (_) {
                              setState(() => _typeFilter = 'beneficiario');
                              _loadRecords();
                            },
                          ),
                          FilterChip(
                            label: const Text('Invitados'),
                            selected: _typeFilter == 'guest',
                            onSelected: (_) {
                              setState(() => _typeFilter = 'guest');
                              _loadRecords();
                            },
                          ),
                          FilterChip(
                            label: const Text('QR'),
                            selected: _methodFilter == 'qr_scan',
                            onSelected: (_) {
                              setState(() => _methodFilter = 'qr_scan');
                              _loadRecords();
                            },
                          ),
                          FilterChip(
                            label: const Text('Manual'),
                            selected: _methodFilter == 'manual_form',
                            onSelected: (_) {
                              setState(() => _methodFilter = 'manual_form');
                              _loadRecords();
                            },
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    SegmentedButton<_ReportTab>(
                      segments: const [
                        ButtonSegment(value: _ReportTab.resumen, label: Text('Resumen'), icon: Icon(Icons.insights)),
                        ButtonSegment(value: _ReportTab.registros, label: Text('Registros'), icon: Icon(Icons.list)),
                      ],
                      selected: {_tab},
                      onSelectionChanged: (value) => setState(() => _tab = value.first),
                    ),
                    if (_tab == _ReportTab.registros) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _searchCtrl,
                        decoration: appFieldDecoration(
                          hintText: _parkingMode ? 'Buscar placa o nombre...' : 'Buscar nombre o cédula...',
                        ).copyWith(
                          prefixIcon: const Icon(Icons.search),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
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
              else if (_tab == _ReportTab.resumen)
                _buildSummaryTab()
              else
                _buildRecordsTab(),
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
