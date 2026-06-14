import 'package:flutter/material.dart';
import '../models/activity_track.dart';
import '../services/attendance_service.dart';
import '../utils/ui_helpers.dart';
import '../widgets/app_widgets.dart';

class ActivityFormData {
  final String name;
  final String description;
  final String eventDate;
  final String? eventTime;
  final String location;
  final bool parkingEnabled;
  final bool repeatAttendanceEnabled;
  final int repeatCooldownHours;

  const ActivityFormData({
    required this.name,
    required this.description,
    required this.eventDate,
    this.eventTime,
    required this.location,
    required this.parkingEnabled,
    required this.repeatAttendanceEnabled,
    required this.repeatCooldownHours,
  });
}

Future<ActivityFormData?> showActivityFormDialog(
  BuildContext context, {
  ActivityTrack? initial,
  required bool isEdit,
}) async {
  final formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController(text: initial?.name ?? '');
  final descCtrl = TextEditingController(text: initial?.description ?? '');
  final locationCtrl = TextEditingController(text: initial?.location ?? '');
  DateTime? pickedDate = initial?.eventDate != null ? DateTime.tryParse(initial!.eventDate!) : null;
  TimeOfDay? pickedTime;
  if (initial?.eventTime != null && initial!.eventTime!.isNotEmpty) {
    final parts = initial.eventTime!.split(':');
    if (parts.length >= 2) {
      pickedTime = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 0,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    }
  }
  var parkingEnabled = initial?.parkingEnabled ?? false;
  var repeatEnabled = initial?.repeatAttendanceEnabled ?? false;
  var cooldown = initial?.repeatAttendanceCooldownHours ?? 3;
  if (![3, 6, 12, 24].contains(cooldown)) cooldown = 3;

  return showDialog<ActivityFormData>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text(isEdit ? 'Editar actividad' : 'Crear actividad'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: appFieldDecoration(hintText: 'Nombre *'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: descCtrl,
                      decoration: appFieldDecoration(hintText: 'Descripción'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: locationCtrl,
                      decoration: appFieldDecoration(hintText: 'Ubicación'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            pickedDate?.toIso8601String().split('T').first ?? 'Fecha *',
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: pickedDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (d != null) setState(() => pickedDate = d);
                          },
                          child: const Text('Elegir'),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(pickedTime?.format(context) ?? 'Hora (opcional)'),
                        ),
                        TextButton(
                          onPressed: () async {
                            final t = await showTimePicker(
                              context: context,
                              initialTime: pickedTime ?? TimeOfDay.now(),
                            );
                            if (t != null) setState(() => pickedTime = t);
                          },
                          child: const Text('Elegir'),
                        ),
                      ],
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Estacionamiento'),
                      subtitle: const Text('Registro por placa (sin QR de beneficiarios)'),
                      value: parkingEnabled,
                      onChanged: (v) => setState(() {
                        parkingEnabled = v;
                        if (v) repeatEnabled = false;
                      }),
                    ),
                    if (!parkingEnabled)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Repetir asistencia'),
                        subtitle: const Text('Permite re-escaneo con cooldown'),
                        value: repeatEnabled,
                        onChanged: (v) => setState(() => repeatEnabled = v),
                      ),
                    if (!parkingEnabled && repeatEnabled)
                      DropdownButtonFormField<int>(
                        initialValue: cooldown,
                        decoration: appFieldDecoration(hintText: 'Cooldown (horas)'),
                        items: const [
                          DropdownMenuItem(value: 3, child: Text('3 horas')),
                          DropdownMenuItem(value: 6, child: Text('6 horas')),
                          DropdownMenuItem(value: 12, child: Text('12 horas')),
                          DropdownMenuItem(value: 24, child: Text('24 horas')),
                        ],
                        onChanged: (v) => setState(() => cooldown = v ?? 3),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              if (pickedDate == null) {
                showAppSnackBar(context, 'La fecha es obligatoria', isError: true);
                return;
              }
              final eventTime = pickedTime == null
                  ? null
                  : '${pickedTime!.hour.toString().padLeft(2, '0')}:${pickedTime!.minute.toString().padLeft(2, '0')}';
              Navigator.of(ctx).pop(
                ActivityFormData(
                  name: nameCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  eventDate: pickedDate!.toIso8601String().split('T').first,
                  eventTime: eventTime,
                  location: locationCtrl.text.trim(),
                  parkingEnabled: parkingEnabled,
                  repeatAttendanceEnabled: repeatEnabled,
                  repeatCooldownHours: cooldown,
                ),
              );
            },
            child: Text(isEdit ? 'Guardar' : 'Crear'),
          ),
        ],
      );
    },
  );
}

Future<int?> saveActivityForm(
  BuildContext context, {
  ActivityTrack? existing,
  required ActivityFormData data,
  required VoidCallback onSaved,
}) async {
  try {
    if (existing == null) {
      final id = await AttendanceService.createActivityTrack(
        name: data.name,
        eventDate: data.eventDate,
        description: data.description.isEmpty ? null : data.description,
        eventTime: data.eventTime,
        location: data.location.isEmpty ? null : data.location,
        parkingEnabled: data.parkingEnabled,
        repeatAttendanceEnabled: data.repeatAttendanceEnabled,
        repeatAttendanceCooldownHours:
            data.repeatAttendanceEnabled ? data.repeatCooldownHours : null,
      );
      if (context.mounted) showAppSnackBar(context, 'Actividad creada');
      onSaved();
      return id;
    } else {
      await AttendanceService.updateActivityTrack(existing.id, {
        'name': data.name,
        'description': data.description.isEmpty ? null : data.description,
        'event_date': data.eventDate,
        'event_time': data.eventTime,
        'location': data.location.isEmpty ? null : data.location,
        'parking_enabled': data.parkingEnabled,
        'repeat_attendance_enabled': data.repeatAttendanceEnabled,
        'repeat_attendance_cooldown_hours':
            data.repeatAttendanceEnabled ? data.repeatCooldownHours : null,
      });
      if (context.mounted) showAppSnackBar(context, 'Actividad actualizada');
      onSaved();
      return existing.id;
    }
  } catch (e) {
    if (context.mounted) handleApiError(context, e);
    return null;
  }
}
