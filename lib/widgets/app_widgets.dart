import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const SectionCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: padding != null ? Padding(padding: padding!, child: child) : child,
    );
  }
}

class SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const SectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.accent),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.heading,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}

class StatusBanner extends StatelessWidget {
  final String message;
  final bool isError;
  final bool isWarning;

  const StatusBanner({
    super.key,
    required this.message,
    this.isError = false,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Color border;
    if (isError) {
      bg = AppColors.errorSoft;
      fg = AppColors.errorText;
      border = const Color(0xFFFECACA);
    } else if (isWarning) {
      bg = AppColors.warningSoft;
      fg = AppColors.warningText;
      border = const Color(0xFFFED7AA);
    } else {
      bg = AppColors.successSoft;
      fg = AppColors.successText;
      border = const Color(0xFFBBF7D0);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Text(
        message,
        style: TextStyle(color: fg, height: 1.3),
      ),
    );
  }
}

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(icon, size: 56, color: const Color(0xFFCBD5E1)),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.heading,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.text, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

InputDecoration appFieldDecoration({required String hintText}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.accent, width: 1.4),
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

Future<T?> showActivityPickerSheet<T extends Object>(
  BuildContext context, {
  required List<T> activities,
  required String Function(T) label,
  T? selected,
  bool Function(T)? filter,
}) {
  final items = filter == null ? activities : activities.where(filter).toList();
  return showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: items.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Text('No hay actividades disponibles.'),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: items.length,
                separatorBuilder: (_, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final activity = items[index];
                  final isSelected = selected != null && selected == activity;
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: isSelected ? AppColors.accent : AppColors.border,
                      ),
                    ),
                    tileColor: isSelected ? AppColors.accentSoft : const Color(0xFFF8FAFC),
                    title: Text(label(activity)),
                    trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.accent) : null,
                    onTap: () => Navigator.of(context).pop(activity),
                  );
                },
              ),
      );
    },
  );
}
