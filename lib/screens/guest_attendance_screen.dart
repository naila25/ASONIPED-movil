import 'package:flutter/material.dart';
import '../models/activity_track.dart';
import '../models/attendance_record.dart';
import '../models/parking_registration.dart';
import '../services/attendance_service.dart';
import '../theme/app_theme.dart';
import '../utils/ui_helpers.dart';
import '../widgets/app_widgets.dart';

class GuestAttendanceScreen extends StatefulWidget {
  const GuestAttendanceScreen({super.key});

  @override
  State<GuestAttendanceScreen> createState() => _GuestAttendanceScreenState();
}

class _GuestAttendanceScreenState extends State<GuestAttendanceScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _message;
  bool _messageIsError = false;
  List<ActivityTrack> _activities = [];
  ActivityTrack? _selectedActivity;
  List<AttendanceRecord> _attendanceRecords = [];
  List<ParkingRegistration> _parkingRecords = [];
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _cedulaController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();

  bool get _parkingMode => _selectedActivity?.isParking == true;

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
    _plateController.dispose();
    super.dispose();
  }

  Future<void> _loadActivities() async {
    try {
      final result = await AttendanceService.fetchActivityTracks(limit: 100);
      setState(() => _activities = result.items.where((a) => !a.isArchived).toList());
    } catch (e) {
      _setMessage('No se pudieron cargar actividades: $e', isError: true);
      if (mounted) handleApiError(context, e);
    }
  }

  Future<void> _loadRecordsForActivity() async {
    final activity = _selectedActivity;
    if (activity == null) return;
    setState(() => _loading = true);
    try {
      if (activity.isParking) {
        final rows = await AttendanceService.fetchParkingRegistrations(activity.id);
        setState(() {
          _parkingRecords = rows;
          _attendanceRecords = [];
        });
      } else {
        final rows = await AttendanceService.fetchAttendanceByActivity(activity.id);
        setState(() {
          _attendanceRecords = rows.where((r) => r.attendanceType == 'guest').toList();
          _parkingRecords = [];
        });
      }
    } catch (e) {
      if (mounted) handleApiError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _setMessage(String message, {bool isError = false}) {
    setState(() {
      _message = message;
      _messageIsError = isError;
    });
  }

  String? _validateForm() {
    if (_parkingMode) {
      final plate = _plateController.text.trim();
      if (plate.length < 2) return 'La placa es obligatoria (mín. 2 caracteres).';
      if (!RegExp(r'^[A-Za-z0-9\s-]+$').hasMatch(plate)) {
        return 'Placa inválida: solo letras, números, espacios y guiones.';
      }
    } else if (_fullNameController.text.trim().isEmpty) {
      return 'El nombre completo es obligatorio.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedActivity == null) {
      _setMessage('Selecciona una actividad primero.', isError: true);
      return;
    }
    final validation = _validateForm();
    if (validation != null) {
      _setMessage(validation, isError: true);
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      if (_parkingMode) {
        await AttendanceService.submitParkingRegistration(
          activityTrackId: _selectedActivity!.id,
          plate: _plateController.text.trim(),
          fullName: _fullNameController.text.trim().isEmpty ? null : _fullNameController.text.trim(),
          cedula: _cedulaController.text.trim().isEmpty ? null : _cedulaController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        );
        _setMessage('Vehículo registrado correctamente.');
      } else {
        final record = await AttendanceService.submitGuestAttendance(
          activityTrackId: _selectedActivity!.id,
          fullName: _fullNameController.text.trim(),
          cedula: _cedulaController.text.trim().isEmpty ? null : _cedulaController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        );
        _setMessage('Asistencia registrada para ${record.fullName}.');
      }

      _fullNameController.clear();
      _cedulaController.clear();
      _phoneController.clear();
      _plateController.clear();
      await _loadRecordsForActivity();
    } catch (e) {
      _setMessage(e.toString(), isError: true);
      if (mounted) handleApiError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickActivity() async {
    final chosen = await showActivityPickerSheet<ActivityTrack>(
      context,
      activities: _activities,
      label: (a) => a.isParking ? '${a.name} (Estacionamiento)' : a.name,
      selected: _selectedActivity,
    );
    if (chosen != null && mounted) {
      setState(() => _selectedActivity = chosen);
      await _loadRecordsForActivity();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SectionCard(
              padding: const EdgeInsets.all(18),
              child: SectionHeader(
                icon: _parkingMode ? Icons.local_parking_rounded : Icons.groups_rounded,
                title: _parkingMode ? 'Estacionamiento' : 'Registro manual',
                subtitle: _parkingMode
                    ? 'Registra vehículos para actividades con estacionamiento habilitado.'
                    : 'Registra invitados para la actividad seleccionada.',
              ),
            ),
            SectionCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Actividad', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _activities.isEmpty ? null : _pickActivity,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(_selectedActivity?.name ?? 'Seleccionar actividad'),
                  ),
                ],
              ),
            ),
            SectionCard(
              padding: const EdgeInsets.all(18),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_parkingMode) ...[
                      TextFormField(
                        controller: _plateController,
                        decoration: appFieldDecoration(hintText: 'Placa *'),
                        textCapitalization: TextCapitalization.characters,
                        validator: (v) => (v == null || v.trim().length < 2) ? 'Placa requerida' : null,
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: _fullNameController,
                      decoration: appFieldDecoration(
                        hintText: _parkingMode ? 'Nombre (opcional)' : 'Nombre completo *',
                      ),
                      validator: _parkingMode
                          ? null
                          : (v) => v == null || v.trim().isEmpty ? 'Nombre requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _cedulaController,
                      decoration: appFieldDecoration(hintText: 'Cédula (opcional)'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      decoration: appFieldDecoration(hintText: 'Teléfono (opcional)'),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    if (_message != null) ...[
                      StatusBanner(message: _message!, isError: _messageIsError),
                      const SizedBox(height: 16),
                    ],
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _loading || _selectedActivity == null ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                              )
                            : Text(_parkingMode ? 'Registrar vehículo' : 'Registrar asistencia'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_selectedActivity != null) ...[
              SectionCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _parkingMode ? 'Vehículos registrados' : 'Invitados registrados',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.heading),
                    ),
                    const SizedBox(height: 10),
                    if (_loading)
                      const Center(child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ))
                    else if (_parkingMode && _parkingRecords.isEmpty)
                      const AppEmptyState(
                        icon: Icons.local_parking_outlined,
                        title: 'Sin vehículos',
                        description: 'Los registros de estacionamiento aparecerán aquí.',
                      )
                    else if (!_parkingMode && _attendanceRecords.isEmpty)
                      const AppEmptyState(
                        icon: Icons.person_outline,
                        title: 'Sin invitados',
                        description: 'Los registros manuales aparecerán aquí.',
                      )
                    else if (_parkingMode)
                      ..._parkingRecords.map(
                        (r) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(r.plateRaw, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(
                            [r.fullName, r.cedula, r.phone].where((e) => e != null && e.isNotEmpty).join(' · '),
                          ),
                        ),
                      )
                    else
                      ..._attendanceRecords.map(
                        (r) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(r.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text('${r.typeLabel} · ${r.createdAt ?? ''}'),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
