import 'package:flutter/material.dart';
import '../models/attendance_record.dart';
import '../services/attendance_service.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  bool _loading = true;
  String? _error;
  List<AttendanceRecord> _records = [];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final records = await AttendanceService.fetchAttendanceRecords();
      setState(() {
        _records = records;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
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
    const accentColor = Color(0xFF12A56B);

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

    return Container(
      color: backgroundColor,
      child: SafeArea(
        child: RefreshIndicator(
          color: accentColor,
          onRefresh: _loadRecords,
          child: _loading
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 180),
                    Center(child: CircularProgressIndicator()),
                  ],
                )
              : _error != null
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: [
                        sectionCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                    )
                  : _records.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          children: [
                            sectionCard(
                              child: const Padding(
                                padding: EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.history_rounded,
                                      size: 56,
                                      color: Color(0xFFCBD5E1),
                                    ),
                                    SizedBox(height: 14),
                                    Text(
                                      'No attendance records found.',
                                      style: TextStyle(
                                        color: headingColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'Pull to refresh and try again.',
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          children: [
                            sectionCard(
                              child: const Padding(
                                padding: EdgeInsets.all(18),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.receipt_long_rounded,
                                      color: accentColor,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Historial',
                                      style: TextStyle(
                                        color: headingColor,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            ..._records.map(
                              (record) => Container(
                                margin: const EdgeInsets.only(bottom: 12),
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
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  title: Text(
                                    record.fullName,
                                    style: const TextStyle(
                                      color: headingColor,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Type: ${record.attendanceType} • Method: ${record.attendanceMethod}${record.createdAt != null ? ' • ${record.createdAt}' : ''}',
                                    style: const TextStyle(color: textColor),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
        ),
      ),
    );
  }
}
