import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/asoniped_nav_bar.dart';
import 'activity_list_screen.dart';
import 'attendance_history_screen.dart';
import 'guest_attendance_screen.dart';
import 'qr_scanner_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    ActivityListScreen(),
    QrScannerScreen(),
    GuestAttendanceScreen(),
    AttendanceHistoryScreen(),
  ];

  static const _titles = [
    'Actividades',
    'Escanear QR',
    'Registro manual',
    'Reportes',
  ];

  Future<void> _logout(BuildContext context) async {
    await AuthService.deleteToken();
    if (context.mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AsonipedAppBar(
        sectionTitle: _titles[_selectedIndex],
        onLogout: () => _logout(context),
      ),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.event_note_outlined), selectedIcon: Icon(Icons.event_note), label: 'Actividades'),
          NavigationDestination(icon: Icon(Icons.qr_code_scanner_outlined), selectedIcon: Icon(Icons.qr_code_scanner), label: 'QR'),
          NavigationDestination(icon: Icon(Icons.person_add_outlined), selectedIcon: Icon(Icons.person_add), label: 'Manual'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Reportes'),
        ],
      ),
    );
  }
}
