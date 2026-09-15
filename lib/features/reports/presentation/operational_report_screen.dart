import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data/reports_provider.dart';
import '../domain/report_models.dart';

class OperationalReportScreen extends ConsumerWidget {
  const OperationalReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Operasional')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(memberStatusCountsProvider);
          ref.invalidate(checkinsLast7DaysProvider);
          ref.invalidate(popularClassesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            _MemberStatusSection(),
            SizedBox(height: 24),
            _CheckinTrendSection(),
            SizedBox(height: 24),
            _PopularClassesSection(),
          ],
        ),
      ),
    );
  }
}

class _MemberStatusSection extends ConsumerWidget {
  const _MemberStatusSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(memberStatusCountsProvider);

    return dataAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Text('Gagal memuat: $err'),
      data: (statuses) {
        int countFor(String status) =>
            statuses.firstWhere((s) => s.status == status, orElse: () => const MemberStatusCount(status: '', count: 0)).count;

        final active = countFor('active');
        final expiringSoon = countFor('expiring_soon');
        final expired = countFor('expired');
        final total = active + expiringSoon + expired;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status Member ($total total)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _StatCard(label: 'Aktif', count: active, color: Colors.green)),
                const SizedBox(width: 8),
                Expanded(child: _StatCard(label: 'Segera Habis', count: expiringSoon, color: Colors.orange)),
                const SizedBox(width: 8),
                Expanded(child: _StatCard(label: 'Kedaluwarsa', count: expired, color: Colors.red)),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatCard({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Text('$count',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _CheckinTrendSection extends ConsumerWidget {
  const _CheckinTrendSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(checkinsLast7DaysProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: dataAsync.when(
          loading: () => const SizedBox(
              height: 200, child: Center(child: CircularProgressIndicator())),
          error: (err, _) => Text('Gagal memuat: $err'),
          data: (days) {
            final todayCount = days.isEmpty ? 0 : days.last.count;
            final maxVal = days.isEmpty
                ? 0
                : days.map((d) => d.count).reduce((a, b) => a > b ? a : b);
            final maxY = (maxVal == 0 ? 5 : (maxVal * 1.3).ceil()).toDouble();
            const dayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tren Check-in 7 Hari Terakhir',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text('Hari ini: $todayCount check-in',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo)),
                const SizedBox(height: 20),
                SizedBox(
                  height: 180,
                  child: BarChart(
                    BarChartData(
                      maxY: maxY,
                      barGroups: [
                        for (int i = 0; i < days.length; i++)
                          BarChartGroupData(x: i, barRods: [
                            BarChartRodData(
                              toY: days[i].count.toDouble(),
                              color: i == days.length - 1 ? Colors.indigo : Colors.indigo.shade200,
                              width: 20,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ]),
                      ],
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= days.length) return const SizedBox();
                              final weekday = days[i].day.weekday; // 1=Senin..7=Minggu
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(dayLabels[weekday - 1], style: const TextStyle(fontSize: 10)),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PopularClassesSection extends ConsumerWidget {
  const _PopularClassesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(popularClassesProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: dataAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Text('Gagal memuat: $err'),
          data: (classes) {
            if (classes.isEmpty) {
              return const Text('Belum ada data booking kelas.');
            }
            final maxCount = classes.map((c) => c.bookingCount).reduce((a, b) => a > b ? a : b);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Kelas Paling Populer',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                for (int i = 0; i < classes.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        CircleAvatar(radius: 12, child: Text('${i + 1}', style: const TextStyle(fontSize: 12))),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(classes[i].className),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: maxCount == 0 ? 0 : classes[i].bookingCount / maxCount,
                                  minHeight: 6,
                                  backgroundColor: Colors.indigo.withOpacity(0.1),
                                  valueColor: const AlwaysStoppedAnimation(Colors.indigo),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${classes[i].bookingCount}x', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
