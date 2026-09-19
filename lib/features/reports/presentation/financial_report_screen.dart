import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data/reports_provider.dart';
import '../../../shared/format_rupiah.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/responsive.dart';

class FinancialReportScreen extends ConsumerWidget {
  const FinancialReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Keuangan')),
      body: ResponsiveCenter(
        child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(revenueByMonthProvider);
          ref.invalidate(revenueByMethodProvider);
          ref.invalidate(revenueByPackageProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            _RevenueMonthSection(),
            SizedBox(height: 24),
            _RevenueByMethodSection(),
            SizedBox(height: 24),
            _RevenueByPackageSection(),
          ],
        ),
        ),
      ),
    );
  }
}

class _RevenueMonthSection extends ConsumerWidget {
  const _RevenueMonthSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(revenueByMonthProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: dataAsync.when(
          loading: () => const SizedBox(
              height: 220, child: Center(child: CircularProgressIndicator())),
          error: (err, _) => Text('Gagal memuat: $err'),
          data: (months) {
            final total = months.fold<double>(0, (sum, m) => sum + m.total);
            final maxVal = months.isEmpty
                ? 0.0
                : months.map((m) => m.total).reduce((a, b) => a > b ? a : b);
            final maxY = maxVal == 0 ? 100.0 : maxVal * 1.2;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pendapatan 6 Bulan Terakhir',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text('Total: ${formatRupiah(total)}',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.emeraldBright)),
                const SizedBox(height: 20),
                SizedBox(
                  height: 220,
                  child: months.isEmpty
                      ? const Center(child: Text('Belum ada data pembayaran.'))
                      : BarChart(
                          BarChartData(
                            maxY: maxY,
                            barGroups: [
                              for (int i = 0; i < months.length; i++)
                                BarChartGroupData(x: i, barRods: [
                                  BarChartRodData(
                                    toY: months[i].total,
                                    color: AppColors.emeraldBright,
                                    width: 18,
                                    borderRadius:
                                        const BorderRadius.vertical(top: Radius.circular(4)),
                                  ),
                                ]),
                            ],
                            titlesData: FlTitlesData(
                              leftTitles:
                                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles:
                                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles:
                                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final i = value.toInt();
                                    if (i < 0 || i >= months.length) return const SizedBox();
                                    final label = months[i].monthLabel.split(' ').first;
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(label, style: const TextStyle(fontSize: 10)),
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

class _RevenueByMethodSection extends ConsumerWidget {
  const _RevenueByMethodSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(revenueByMethodProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: dataAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Text('Gagal memuat: $err'),
          data: (methods) {
            if (methods.isEmpty) return const Text('Belum ada data pembayaran.');
            final total = methods.fold<double>(0, (sum, m) => sum + m.total);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pendapatan per Metode Pembayaran',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                for (final m in methods)
                  _BreakdownBar(
                    label: m.label,
                    value: m.total,
                    fraction: total == 0 ? 0 : m.total / total,
                    color: AppColors.gold,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RevenueByPackageSection extends ConsumerWidget {
  const _RevenueByPackageSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(revenueByPackageProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: dataAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Text('Gagal memuat: $err'),
          data: (packages) {
            if (packages.isEmpty) return const Text('Belum ada data pembayaran.');
            final total = packages.fold<double>(0, (sum, p) => sum + p.total);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pendapatan per Paket Membership',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                for (final pkg in packages)
                  _BreakdownBar(
                    label: pkg.packageName,
                    value: pkg.total,
                    fraction: total == 0 ? 0 : pkg.total / total,
                    color: AppColors.emeraldBright,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BreakdownBar extends StatelessWidget {
  final String label;
  final double value;
  final double fraction;
  final Color color;

  const _BreakdownBar({
    required this.label,
    required this.value,
    required this.fraction,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Text(formatRupiah(value), style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction.clamp(0, 1),
              minHeight: 8,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}
