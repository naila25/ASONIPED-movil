import 'package:flutter/material.dart';
import '../models/activity_track.dart';
import 'activity_list_screen.dart';
import '../services/attendance_service.dart';

class GuestAttendanceScreen extends StatefulWidget {
  const GuestAttendanceScreen({super.key});

  @override
  State<GuestAttendanceScreen> createState() => _GuestAttendanceScreenState();
}

class _GuestAttendanceScreenState extends State<GuestAttendanceScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _message;
  List<ActivityTrack> _activities = [];
  ActivityTrack? _selectedActivity;
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _cedulaController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

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
    super.dispose();
  }

  Future<void> _loadActivities() async {
    try {
      final items = await AttendanceService.fetchActivityTracks();
      setState(() {
        _activities = items;
      });
    } catch (e) {
      setState(() {
        _message = 'Unable to load activities: $e';
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedActivity == null) {
      setState(() {
        _message = 'Please select an activity first.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final record = await AttendanceService.submitGuestAttendance(
        activityTrackId: _selectedActivity!.id,
        fullName: _fullNameController.text.trim(),
        cedula: _cedulaController.text.trim().isEmpty
            ? null
            : _cedulaController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
      );

      setState(() {
        _message = 'Guest attendance recorded for ${record.fullName}.';
        _fullNameController.clear();
        _cedulaController.clear();
        _phoneController.clear();
      });
    } catch (e) {
      setState(() {
        _message = 'Failed to record guest attendance: $e';
      });
    } finally {
      setState(() {
        _loading = false;
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
    const accentColor = Color(0xFF16A34A);
    const accentSoft = Color(0xFFE7FBF2);
    const placeholderBg = Color(0xFFF8FAFC);

    Widget sectionCard({required Widget child}) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
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

    InputDecoration fieldDecoration({required String hintText}) {
      return InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
        filled: true,
        fillColor: placeholderBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentColor, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
        ),
      );
    }

    return Container(
      color: backgroundColor,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  sectionCard(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: accentSoft,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.groups_rounded,
                              color: accentColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Registro manual',
                                  style: TextStyle(
                                    color: headingColor,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Registra invitados para la actividad seleccionada.',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 14,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
                            'Abre el selector para elegir una actividad; luego verás solo la que elegiste.',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: _loading
                                    ? null
                                    : () async {
                                        if (_activities.isEmpty) return;
                                        final chosen = await showModalBottomSheet<ActivityTrack?>(
                                          context: context,
                                          showDragHandle: true,
                                          shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                                          ),
                                          builder: (context) {
                                                return ListView.separated(
                                                  padding: const EdgeInsets.all(16),
                                                  itemCount: _activities.length,
                                                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                                                  itemBuilder: (context, index) {
                                                    final activity = _activities[index];
                                                    return ListTile(
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(14),
                                                      ),
                                                      tileColor: const Color(0xFFF8FAFC),
                                                      title: Text(activity.name),
                                                      onTap: () => Navigator.of(context).pop(activity),
                                                    );
                                                  },
                                                );
                                          },
                                        );
                                        if (chosen != null && mounted) {
                                          setState(() {
                                            _selectedActivity = chosen;
                                          });
                                        }
                                      },
                              icon: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(Icons.add, size: 20, color: Colors.white),
                              ),
                              label: Text(
                                _selectedActivity?.name ?? 'Actividades',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: accentColor,
                                disabledForegroundColor: Colors.white70,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                      ),
                    ),
                  ),
                  sectionCard(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(
                            Icons.groups_rounded,
                            size: 52,
                            color: Color(0xFFCBD5E1),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Selecciona una actividad',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: headingColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Para registrar invitados, elige una actividad en el panel superior.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _fullNameController,
                            style: const TextStyle(color: headingColor),
                            decoration: fieldDecoration(hintText: 'Full name'),
                            validator: (value) => value == null || value.trim().isEmpty
                                ? 'Enter full name'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _cedulaController,
                            style: const TextStyle(color: headingColor),
                            decoration: fieldDecoration(hintText: 'Cédula (optional)'),
                            keyboardType: TextInputType.text,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phoneController,
                            style: const TextStyle(color: headingColor),
                            decoration: fieldDecoration(hintText: 'Phone (optional)'),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),
                          if (_message != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _message!.startsWith('Failed')
                                    ? const Color(0xFFFFF1F2)
                                    : const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _message!.startsWith('Failed')
                                      ? const Color(0xFFFECACA)
                                      : const Color(0xFFBBF7D0),
                                ),
                              ),
                              child: Text(
                                _message!,
                                style: TextStyle(
                                  color: _message!.startsWith('Failed')
                                      ? Colors.red.shade700
                                      : const Color(0xFF166534),
                                  height: 1.3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _loading || _selectedActivity == null ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: accentColor,
                                disabledForegroundColor: Colors.white70,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'Record attendance',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
