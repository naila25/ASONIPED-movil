import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'services/session_service.dart';
import 'theme/app_theme.dart';
import 'widgets/asoniped_nav_bar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Asoniped Asistencia',
      theme: AppTheme.light(),
      initialRoute: '/',
      routes: {
        '/': (ctx) => const _SplashGate(),
        '/login': (ctx) {
          final message = ModalRoute.of(ctx)?.settings.arguments as String?;
          return LoginScreen(sessionMessage: message);
        },
        '/home': (ctx) => const HomeScreen(),
      },
    );
  }
}

class _SplashGate extends StatefulWidget {
  const _SplashGate();

  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final status = await resolveSession();
    if (!mounted) return;

    switch (status) {
      case SessionStatus.valid:
        Navigator.of(context).pushReplacementNamed('/home');
      case SessionStatus.expired:
        Navigator.of(context).pushReplacementNamed(
          '/login',
          arguments: AuthService.sessionExpiredMessage,
        );
      case SessionStatus.none:
        Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: AsonipedNavBar(
              sectionTitle: 'Asistencia',
              showUserMenu: false,
            ),
          ),
          const Expanded(
            child: Center(child: CircularProgressIndicator(color: AppColors.navBarBlue)),
          ),
        ],
      ),
    );
  }
}
