import 'package:flutter/material.dart';
import '../models/activity_track.dart';
import '../services/attendance_service.dart';
import '../theme/app_theme.dart';
import '../utils/ui_helpers.dart';
import 'app_widgets.dart';

Future<bool> showParkingRegistrationDialog(
  BuildContext context, {
  required ActivityTrack activity,
  VoidCallback? onRegistered,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => _ParkingRegistrationDialog(activity: activity),
  );
  if (result == true) onRegistered?.call();
  return result == true;
}

class _ParkingRegistrationDialog extends StatefulWidget {
  final ActivityTrack activity;

  const _ParkingRegistrationDialog({required this.activity});

  @override
  State<_ParkingRegistrationDialog> createState() => _ParkingRegistrationDialogState();
}

class _ParkingRegistrationDialogState extends State<_ParkingRegistrationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _plateCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _cedulaCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _plateCtrl.dispose();
    _nameCtrl.dispose();
    _cedulaCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AttendanceService.submitParkingRegistration(
        activityTrackId: widget.activity.id,
        plate: _plateCtrl.text.trim(),
        fullName: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
        cedula: _cedulaCtrl.text.trim().isEmpty ? null : _cedulaCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      showAppSnackBar(context, 'Vehículo registrado');
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
      if (mounted) handleApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar vehículo'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.activity.name,
                  style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _plateCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: appFieldDecoration(hintText: 'Placa *'),
                  validator: (v) {
                    if (v == null || v.trim().length < 2) return 'Placa requerida';
                    if (!RegExp(r'^[A-Za-z0-9\s-]+$').hasMatch(v.trim())) {
                      return 'Solo letras, números, espacios y guiones';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: appFieldDecoration(hintText: 'Nombre (opcional)'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _cedulaCtrl,
                  decoration: appFieldDecoration(hintText: 'Cédula (opcional)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: appFieldDecoration(hintText: 'Teléfono (opcional)'),
                  keyboardType: TextInputType.phone,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  StatusBanner(message: _error!, isError: true),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white),
          child: _loading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Registrar'),
        ),
      ],
    );
  }
}
