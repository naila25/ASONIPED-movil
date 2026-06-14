import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../config.dart';
import '../services/attendance_service.dart';
import '../theme/app_theme.dart';
import '../utils/ui_helpers.dart';
import 'app_widgets.dart';

String formatParkingExpiry(String iso) {
  try {
    final dt = DateTime.parse(iso).toLocal();
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  } catch (_) {
    return iso;
  }
}

/// Inline panel: public parking link + QR for others to scan.
class ParkingSharePanel extends StatefulWidget {
  final int activityId;
  final String activityName;

  const ParkingSharePanel({
    super.key,
    required this.activityId,
    required this.activityName,
  });

  @override
  State<ParkingSharePanel> createState() => _ParkingSharePanelState();
}

class _ParkingSharePanelState extends State<ParkingSharePanel> {
  bool _loading = true;
  String? _error;
  String? _url;
  String? _expiresAt;

  @override
  void initState() {
    super.initState();
    _loadLink();
  }

  Future<void> _loadLink() async {
    setState(() {
      _loading = true;
      _error = null;
      _url = null;
      _expiresAt = null;
    });
    try {
      final link = await AttendanceService.fetchParkingLink(widget.activityId);
      if (!mounted) return;
      setState(() {
        _url = parkingPublicUrl(link.token);
        _expiresAt = link.expiresAt;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _copyUrl() {
    if (_url == null) return;
    Clipboard.setData(ClipboardData(text: _url!));
    showAppSnackBar(context, 'Enlace copiado');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.activityName,
          style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        const Text(
          'Comparte este enlace o QR para que los visitantes registren su vehículo en la actividad.',
          style: TextStyle(color: AppColors.text, fontSize: 13, height: 1.35),
        ),
        const SizedBox(height: 14),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null) ...[
          StatusBanner(message: _error!, isError: true),
          const SizedBox(height: 10),
          OutlinedButton(onPressed: _loadLink, child: const Text('Reintentar')),
        ] else if (_url != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: QrImageView(
                    data: _url!,
                    size: 200,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF92400E),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Escanea para abrir el registro de estacionamiento',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                ),
                if (_expiresAt != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Válido hasta ${formatParkingExpiry(_expiresAt!)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'ENLACE PARA COMPARTIR',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: SelectableText(
              _url!,
              style: const TextStyle(fontSize: 13, color: AppColors.heading),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _copyUrl,
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copiar enlace'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ],
    );
  }
}

/// Collapsible wrapper — QR/link hidden by default; loads only when expanded.
class CollapsibleParkingShareSection extends StatefulWidget {
  final int activityId;
  final String activityName;
  final bool initiallyExpanded;

  const CollapsibleParkingShareSection({
    super.key,
    required this.activityId,
    required this.activityName,
    this.initiallyExpanded = false,
  });

  @override
  State<CollapsibleParkingShareSection> createState() => _CollapsibleParkingShareSectionState();
}

class _CollapsibleParkingShareSectionState extends State<CollapsibleParkingShareSection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.qr_code_2, color: AppColors.parking, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Enlace y QR de estacionamiento',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.heading,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          _expanded ? 'Toca para ocultar' : 'Toca para mostrar y compartir',
                          style: const TextStyle(color: AppColors.text, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.parking,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 14),
          ParkingSharePanel(
            key: ValueKey('parking-share-${widget.activityId}'),
            activityId: widget.activityId,
            activityName: widget.activityName,
          ),
        ],
      ],
    );
  }
}

Future<void> showParkingLinkDialog(
  BuildContext context, {
  required int activityId,
  required String activityName,
  bool initiallyExpanded = true,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Estacionamiento público'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: CollapsibleParkingShareSection(
            activityId: activityId,
            activityName: activityName,
            initiallyExpanded: initiallyExpanded,
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cerrar')),
      ],
    ),
  );
}
