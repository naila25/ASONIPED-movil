import 'package:flutter/material.dart';
import '../models/activity_track.dart';
import '../services/attendance_service.dart';
import '../theme/app_theme.dart';
import '../utils/ui_helpers.dart';
import '../widgets/activity_form_dialog.dart';
import '../widgets/app_widgets.dart';
import '../widgets/parking_share_panel.dart';

class ActivityListScreen extends StatefulWidget {
  const ActivityListScreen({super.key});

  @override
  State<ActivityListScreen> createState() => _ActivityListScreenState();
}

class _ActivityListScreenState extends State<ActivityListScreen> {
  bool _loading = true;
  String? _error;
  List<ActivityTrack> _activities = [];
  bool _showArchived = false;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadActivities() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await AttendanceService.fetchActivityTracks(
        limit: 100,
        includeArchived: _showArchived,
        search: _searchCtrl.text,
      );
      setState(() => _activities = result.items);
    } catch (e) {
      setState(() => _error = e.toString());
      if (mounted) handleApiError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createActivity() async {
    final data = await showActivityFormDialog(context, isEdit: false);
    if (data == null || !mounted) return;

    final createdId = await saveActivityForm(context, data: data, onSaved: _loadActivities);
    if (!mounted || createdId == null) return;

    await _loadActivities();
    if (!mounted || !data.parkingEnabled) return;

    ActivityTrack? activity;
    for (final item in _activities) {
      if (item.id == createdId) {
        activity = item;
        break;
      }
    }
    await showParkingLinkDialog(
      context,
      activityId: createdId,
      activityName: activity?.name ?? data.name,
      initiallyExpanded: true,
    );
  }

  Future<void> _editActivity(ActivityTrack activity) async {
    final data = await showActivityFormDialog(context, initial: activity, isEdit: true);
    if (data == null || !mounted) return;
    await saveActivityForm(context, existing: activity, data: data, onSaved: _loadActivities);
  }

  Future<void> _toggleArchive(ActivityTrack activity) async {
    try {
      if (activity.isArchived) {
        await AttendanceService.unarchiveActivityTrack(activity.id);
        if (mounted) showAppSnackBar(context, 'Actividad restaurada');
      } else {
        await AttendanceService.archiveActivityTrack(activity.id);
        if (mounted) showAppSnackBar(context, 'Actividad archivada');
      }
      await _loadActivities();
    } catch (e) {
      if (mounted) handleApiError(context, e);
    }
  }

  Future<void> _showParkingLink(ActivityTrack activity) async {
    await showParkingLinkDialog(
      context,
      activityId: activity.id,
      activityName: activity.name,
    );
  }

  void _showActivityActions(ActivityTrack activity) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Editar'),
                onTap: () {
                  Navigator.pop(ctx);
                  _editActivity(activity);
                },
              ),
              if (activity.isParking)
                ListTile(
                  leading: const Icon(Icons.qr_code_2_outlined, color: Color(0xFFD97706)),
                  title: const Text('Ver enlace y QR de estacionamiento'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showParkingLink(activity);
                  },
                ),
              ListTile(
                leading: Icon(activity.isArchived ? Icons.unarchive : Icons.archive_outlined),
                title: Text(activity.isArchived ? 'Restaurar' : 'Archivar'),
                onTap: () {
                  Navigator.pop(ctx);
                  _toggleArchive(activity);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: _createActivity,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.accent,
          onRefresh: _loadActivities,
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
                      icon: Icons.list_alt_rounded,
                      title: 'Actividades',
                      subtitle: 'Gestiona eventos, estacionamiento y archivado.',
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _searchCtrl,
                      decoration: appFieldDecoration(hintText: 'Buscar actividad...').copyWith(
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: _loadActivities,
                        ),
                      ),
                      onSubmitted: (_) => _loadActivities(),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Mostrar archivadas'),
                      value: _showArchived,
                      onChanged: (v) {
                        setState(() => _showArchived = v);
                        _loadActivities();
                      },
                    ),
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
              else if (_activities.isEmpty)
                SectionCard(
                  child: AppEmptyState(
                    icon: Icons.event_note_rounded,
                    title: 'No hay actividades',
                    description: 'Crea una actividad o ajusta los filtros.',
                  ),
                )
              else
                ..._activities.map(
                  (activity) => _ActivityTile(
                    activity: activity,
                    onTap: () => _showActivityActions(activity),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final ActivityTrack activity;
  final VoidCallback onTap;

  const _ActivityTile({
    required this.activity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      _chip(activity.status?.toUpperCase() ?? 'ACTIVA', AppColors.accentSoft, AppColors.accent),
      if (activity.isParking) _chip('ESTACIONAMIENTO', const Color(0xFFE0F2FE), const Color(0xFF0369A1)),
      if (activity.isScanning) _chip('ESCANEANDO', AppColors.successSoft, AppColors.successText),
      if (activity.isArchived) _chip('ARCHIVADA', const Color(0xFFF1F5F9), AppColors.text),
    ];

    return SectionCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            activity.name,
                            style: const TextStyle(
                              color: AppColors.heading,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const Icon(Icons.more_horiz, color: AppColors.text),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${activity.eventDate ?? 'Sin fecha'}${activity.eventTime != null ? ' · ${activity.eventTime}' : ''}${activity.location != null ? ' · ${activity.location}' : ''}',
                      style: const TextStyle(color: AppColors.text, fontSize: 13),
                    ),
                    if (activity.totalAttendance != null && !activity.isParking) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${activity.totalAttendance} asistencias · ${activity.beneficiariosCount ?? 0} benef. · ${activity.guestsCount ?? 0} invitados',
                        style: const TextStyle(color: AppColors.text, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (activity.isParking) ...[
              const SizedBox(height: 10),
              CollapsibleParkingShareSection(
                activityId: activity.id,
                activityName: activity.name,
              ),
            ],
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 6, children: chips),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
