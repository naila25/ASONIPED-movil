import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/attendance_record.dart';
import '../models/parking_registration.dart';
import '../theme/app_theme.dart';
import 'app_widgets.dart';

class ChartSlice {
  final String label;
  final double value;
  final Color color;

  const ChartSlice({required this.label, required this.value, required this.color});
}

class AttendanceCharts extends StatelessWidget {
  final List<ChartSlice> typeSlices;
  final List<ChartSlice> methodSlices;
  final bool isParking;
  final int parkingTotal;
  final List<ChartSlice>? parkingSourceSlices;

  const AttendanceCharts({
    super.key,
    required this.typeSlices,
    required this.methodSlices,
    this.isParking = false,
    this.parkingTotal = 0,
    this.parkingSourceSlices,
  });

  bool get _hasTypeData => typeSlices.any((s) => s.value > 0);
  bool get _hasMethodData => methodSlices.any((s) => s.value > 0);
  bool get _hasParkingSource =>
      parkingSourceSlices != null && parkingSourceSlices!.any((s) => s.value > 0);

  @override
  Widget build(BuildContext context) {
    if (isParking) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vehículos registrados',
                  style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.heading),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 180,
                  child: BarChart(
                    BarChartData(
                      maxY: parkingTotal == 0 ? 1 : parkingTotal.toDouble() * 1.2,
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) => const Text(
                              'Total',
                              style: TextStyle(fontSize: 12, color: AppColors.text),
                            ),
                          ),
                        ),
                      ),
                      barGroups: [
                        BarChartGroupData(
                          x: 0,
                          barRods: [
                            BarChartRodData(
                              toY: parkingTotal.toDouble(),
                              color: const Color(0xFF0369A1),
                              width: 48,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    '$parkingTotal vehículo${parkingTotal == 1 ? '' : 's'}',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.heading),
                  ),
                ),
              ],
            ),
          ),
          if (_hasParkingSource) ...[
            const SizedBox(height: 12),
            _PieCard(title: 'Origen del registro', slices: parkingSourceSlices!),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_hasTypeData) _PieCard(title: 'Beneficiarios vs invitados', slices: typeSlices),
        if (_hasTypeData && _hasMethodData) const SizedBox(height: 12),
        if (_hasMethodData) _BarCard(title: 'QR vs registro manual', slices: methodSlices),
      ],
    );
  }
}

class _PieCard extends StatelessWidget {
  final String title;
  final List<ChartSlice> slices;

  const _PieCard({required this.title, required this.slices});

  @override
  Widget build(BuildContext context) {
    final total = slices.fold<double>(0, (sum, s) => sum + s.value);
    return SectionCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.heading)),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 36,
                      sections: slices
                          .where((s) => s.value > 0)
                          .map(
                            (s) => PieChartSectionData(
                              value: s.value,
                              title: total > 0 ? '${((s.value / total) * 100).round()}%' : '0%',
                              color: s.color,
                              radius: 52,
                              titleStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: slices
                      .where((s) => s.value > 0)
                      .map(
                        (s) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(color: s.color, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              Text('${s.label}: ${s.value.toInt()}'),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BarCard extends StatelessWidget {
  final String title;
  final List<ChartSlice> slices;

  const _BarCard({required this.title, required this.slices});

  @override
  Widget build(BuildContext context) {
    final maxY = slices.fold<double>(0, (m, s) => s.value > m ? s.value : m);
    return SectionCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.heading)),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: maxY == 0 ? 1 : maxY * 1.25,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= slices.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            slices[index].label,
                            style: const TextStyle(fontSize: 11, color: AppColors.text),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < slices.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: slices[i].value,
                          color: slices[i].color,
                          width: 36,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<ChartSlice> buildTypeSlicesFromRecords(List<AttendanceRecord> records) {
  final benef = records.where((r) => r.attendanceType == 'beneficiario').length;
  final guest = records.where((r) => r.attendanceType == 'guest').length;
  return [
    ChartSlice(label: 'Beneficiarios', value: benef.toDouble(), color: AppColors.accent),
    ChartSlice(label: 'Invitados', value: guest.toDouble(), color: const Color(0xFF3B82F6)),
  ];
}

List<ChartSlice> buildMethodSlicesFromRecords(List<AttendanceRecord> records) {
  final qr = records.where((r) => r.attendanceMethod == 'qr_scan').length;
  final manual = records.where((r) => r.attendanceMethod == 'manual_form').length;
  return [
    ChartSlice(label: 'QR', value: qr.toDouble(), color: const Color(0xFF8B5CF6)),
    ChartSlice(label: 'Manual', value: manual.toDouble(), color: const Color(0xFFF59E0B)),
  ];
}

List<ChartSlice> buildTypeSlicesFromStats({
  required int beneficiarios,
  required int guests,
}) {
  return [
    ChartSlice(label: 'Beneficiarios', value: beneficiarios.toDouble(), color: AppColors.accent),
    ChartSlice(label: 'Invitados', value: guests.toDouble(), color: const Color(0xFF3B82F6)),
  ];
}

List<ChartSlice> buildMethodSlicesFromStats({
  required int qrScans,
  required int manualEntries,
}) {
  return [
    ChartSlice(label: 'QR', value: qrScans.toDouble(), color: const Color(0xFF8B5CF6)),
    ChartSlice(label: 'Manual', value: manualEntries.toDouble(), color: const Color(0xFFF59E0B)),
  ];
}

List<ChartSlice> buildParkingSourceSlices(List<ParkingRegistration> records) {
  final public = records.where((r) => r.source == 'public_link').length;
  final admin = records.where((r) => r.source == 'admin').length;
  return [
    ChartSlice(label: 'Enlace público', value: public.toDouble(), color: const Color(0xFF0369A1)),
    ChartSlice(label: 'Admin', value: admin.toDouble(), color: const Color(0xFFD97706)),
  ];
}
