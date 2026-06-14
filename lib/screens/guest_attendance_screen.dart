import 'package:flutter/material.dart';
import '../models/activity_track.dart';
import '../models/attendance_record.dart';
import '../models/parking_registration.dart';
import '../services/attendance_service.dart';
import '../theme/app_theme.dart';
import '../utils/ui_helpers.dart';
import '../widgets/app_widgets.dart';
import '../widgets/parking_share_panel.dart';

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

  void _clearFormFields() {
    _fullNameController.clear();
    _cedulaController.clear();
    _phoneController.clear();
    _plateController.clear();
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

  Future<void> _selectActivity(ActivityTrack activity) async {
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      final fresh = await AttendanceService.fetchActivityById(activity.id);
      final resolved = fresh ?? activity;
      if (!mounted) return;
      setState(() {
        _selectedActivity = resolved;
      });
      _clearFormFields();
      _formKey.currentState?.reset();
      await _loadRecordsForActivity();
    } catch (e) {
      if (mounted) handleApiError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedActivity == null) {
      _setMessage('Selecciona una actividad primero.', isError: true);
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

      _clearFormFields();
      _formKey.currentState?.reset();
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
      label: (a) => a.isParking ? '${a.name} · Estacionamiento' : a.name,
      selected: _selectedActivity,
    );
    if (chosen != null && mounted) {
      await _selectActivity(chosen);
    }
  }

  Widget _buildRegistrationForm() {
    if (_selectedActivity == null) {
      return SectionCard(
        child: AppEmptyState(
          icon: Icons.touch_app_outlined,
          title: 'Selecciona una actividad',
          description: 'El formulario cambiará según sea estacionamiento o registro de invitados.',
        ),
      );
    }

    return SectionCard(
      padding: const EdgeInsets.all(18),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _parkingMode ? 'Registro de vehículo' : 'Registro de invitado',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.heading),
                  ),
                ),
                if (_parkingMode)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.parkingSoft,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: const Text(
                      'Parking',
                      style: TextStyle(
                        color: AppColors.parking,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_parkingMode) ...[
              TextFormField(
                key: const ValueKey('parking-plate'),
                controller: _plateController,
                decoration: appFieldDecoration(
                  labelText: 'Placa del vehículo *',
                  hintText: 'Ej: ABC123',
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (v) {
                  if (v == null || v.trim().length < 2) return 'La placa es obligatoria';
                  if (!RegExp(r'^[A-Za-z0-9\s-]+$').hasMatch(v.trim())) {
                    return 'Solo letras, números, espacios y guiones';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('parking-name'),
                controller: _fullNameController,
                decoration: appFieldDecoration(
                  labelText: 'Nombre completo (opcional)',
                  hintText: 'Ej: Juan Pérez',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('parking-cedula'),
                controller: _cedulaController,
                decoration: appFieldDecoration(
                  labelText: 'Cédula (opcional)',
                  hintText: 'Solo números',
                ),
                keyboardType: TextInputType.number,
              ),
            ] else ...[
              TextFormField(
                key: const ValueKey('guest-name'),
                controller: _fullNameController,
                decoration: appFieldDecoration(
                  labelText: 'Nombre completo *',
                  hintText: 'Ej: Juan Pérez',
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Nombre requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('guest-cedula'),
                controller: _cedulaController,
                decoration: appFieldDecoration(
                  labelText: 'Cédula (opcional)',
                  hintText: 'Solo números',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('guest-phone'),
                controller: _phoneController,
                decoration: appFieldDecoration(
                  labelText: 'Teléfono (opcional)',
                  hintText: 'Ej: 5551234',
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
            const SizedBox(height: 16),
            if (_message != null) ...[
              StatusBanner(message: _message!, isError: _messageIsError),
              const SizedBox(height: 16),
            ],
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: appPrimaryButtonStyle(
                  color: _parkingMode ? AppColors.parking : AppColors.accent,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                      )
                    : Text(_parkingMode ? 'Guardar registro' : 'Registrar asistencia'),
              ),
            ),
          ],
        ),
      ),
    );
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
                    ? 'Comparte el QR/enlace o registra vehículos manualmente.'
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
                  OutlinedButton.icon(
                    onPressed: _activities.isEmpty ? null : _pickActivity,
                    icon: const Icon(Icons.event),
                    label: Text(_selectedActivity?.name ?? 'Seleccionar actividad'),
                  ),
                ],
              ),
            ),
            if (_parkingMode && _selectedActivity != null)
              SectionCard(
                padding: const EdgeInsets.all(18),
                child: CollapsibleParkingShareSection(
                  key: ValueKey('share-${_selectedActivity!.id}'),
                  activityId: _selectedActivity!.id,
                  activityName: _selectedActivity!.name,
                ),
              ),
            _buildRegistrationForm(),
            if (_selectedActivity != null)
              PaginatedListPanel(
                title: _parkingMode ? 'Vehículos registrados' : 'Invitados registrados',
                totalCount: _parkingMode ? _parkingRecords.length : _attendanceRecords.length,
                items: _loading
                    ? [const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))]
                    : _parkingMode
                        ? _parkingRecords.isEmpty
                            ? [
                                const AppEmptyState(
                                  icon: Icons.local_parking_outlined,
                                  title: 'Sin vehículos',
                                  description: 'Los registros aparecerán aquí.',
                                ),
                              ]
                            : _parkingRecords
                                .map(
                                  (r) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      backgroundColor: AppColors.parkingSoft,
                                      child: const Icon(Icons.directions_car, color: AppColors.parking, size: 18),
                                    ),
                                    title: Text(r.plateRaw, style: const TextStyle(fontWeight: FontWeight.w700)),
                                    subtitle: Text(
                                      [r.fullName, r.cedula != null ? 'ID ${r.cedula}' : null]
                                          .whereType<String>()
                                          .where((e) => e.isNotEmpty)
                                          .join(' · '),
                                    ),
                                  ),
                                )
                                .toList()
                        : _attendanceRecords.isEmpty
                            ? [
                                const AppEmptyState(
                                  icon: Icons.person_outline,
                                  title: 'Sin invitados',
                                  description: 'Los registros manuales aparecerán aquí.',
                                ),
                              ]
                            : _attendanceRecords
                                .map(
                                  (r) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      backgroundColor: AppColors.accentSoft,
                                      child: const Icon(Icons.person_outline, color: AppColors.accent, size: 18),
                                    ),
                                    title: Text(r.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
                                    subtitle: Text('${r.typeLabel} · ${r.createdAt ?? ''}'),
                                  ),
                                )
                                .toList(),
              ),
          ],
        ),
      ),
    );
  }
}
