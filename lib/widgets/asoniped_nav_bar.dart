import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

/// Round logo matching the web NavBar (`logoasoniped.png`).
class AsonipedLogo extends StatelessWidget {
  final double size;

  const AsonipedLogo({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * 0.07),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Image.asset(
          'assets/images/asoniped_logo.png',
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          isAntiAlias: true,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.volunteer_activism,
            size: size * 0.55,
            color: AppColors.navBarBlue,
          ),
        ),
      ),
    );
  }
}

/// Brand header bar — mirrors web `NavBar.tsx` (blue bar, logo, title, user menu).
class AsonipedNavBar extends StatefulWidget {
  final String? sectionTitle;
  final bool showUserMenu;
  final Future<void> Function()? onLogout;

  const AsonipedNavBar({
    super.key,
    this.sectionTitle,
    this.showUserMenu = true,
    this.onLogout,
  });

  @override
  State<AsonipedNavBar> createState() => _AsonipedNavBarState();
}

class _AsonipedNavBarState extends State<AsonipedNavBar> {
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    if (widget.showUserMenu) _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getUserFromToken();
    if (mounted) setState(() => _user = user);
  }

  String get _displayName {
    final user = _user;
    if (user == null) return 'Usuario';
    return (user['full_name'] ?? user['username'] ?? 'Usuario').toString();
  }

  String? get _email => _user?['email']?.toString();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.navBarBlue,
      elevation: 0,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.navBarBlue,
          border: Border(
            bottom: BorderSide(color: Color(0x33FFFFFF)),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const AsonipedLogo(size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Asoniped Digital',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      height: 1.15,
                    ),
                  ),
                  if (widget.sectionTitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.sectionTitle!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (widget.showUserMenu) _UserMenuButton(
              displayName: _displayName,
              email: _email,
              onLogout: widget.onLogout,
            ),
          ],
        ),
      ),
    );
  }
}

class _UserMenuButton extends StatelessWidget {
  final String displayName;
  final String? email;
  final Future<void> Function()? onLogout;

  const _UserMenuButton({
    required this.displayName,
    this.email,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Cuenta',
      offset: const Offset(0, 44),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) async {
        if (value == 'logout' && onLogout != null) {
          await onLogout!();
        }
      },
      itemBuilder: (ctx) => [
        PopupMenuItem<String>(
          enabled: false,
          height: email != null ? 56 : 44,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.heading,
                  fontSize: 14,
                ),
              ),
              if (email != null)
                Text(
                  email!,
                  style: const TextStyle(color: AppColors.text, fontSize: 11),
                ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 8),
        const PopupMenuItem<String>(
          value: 'logout',
          height: 44,
          child: Row(
            children: [
              Icon(Icons.logout, size: 18, color: AppColors.errorText),
              SizedBox(width: 10),
              Text(
                'Cerrar sesión',
                style: TextStyle(color: AppColors.errorText, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, size: 15, color: Colors.white),
            ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 72),
              child: Text(
                displayName,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.expand_more, size: 18, color: Colors.white.withValues(alpha: 0.75)),
          ],
        ),
      ),
    );
  }
}

/// Scaffold app bar wrapper with status-bar safe area.
class AsonipedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? sectionTitle;
  final bool showUserMenu;
  final Future<void> Function()? onLogout;

  const AsonipedAppBar({
    super.key,
    this.sectionTitle,
    this.showUserMenu = true,
    this.onLogout,
  });

  @override
  Size get preferredSize {
    final sectionExtra = sectionTitle != null ? 18.0 : 0.0;
    return Size.fromHeight(kToolbarHeight + sectionExtra + 8);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: AsonipedNavBar(
        sectionTitle: sectionTitle,
        showUserMenu: showUserMenu,
        onLogout: onLogout,
      ),
    );
  }
}
