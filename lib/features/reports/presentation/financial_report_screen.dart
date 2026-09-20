import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data/reports_provider.dart';
import '../data/report_export.dart';
import '../domain/report_models.dart';
import '../../settings/data/gym_settings_provider.dart';
import '../../../shared/format_rupiah.dart';
import '../../../shared/file_download/file_download.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/responsive.dart';

class FinancialReportScreen extends ConsumerWidget {
  const FinancialReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(financialReportRangeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Keuangan')),
      body: ResponsiveCenter(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(revenueTrendProvider);
            ref.invalidate(revenueByMethodPeriodProvider);
            ref.invalidate(revenueByPackagePeriodProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _RangePicker(
                range: range,
                onChanged: (r) => ref.read(financialReportRangeProvider.notifier).state = r,
              ),
              const SizedBox(height: 16),
              const _DownloadButtons(),
              const SizedBox(height: 16),
              const _RevenueTrendSection(),
              const SizedBox(height: 24),
              const _RevenueByMethodSection(),
              const SizedBox(height: 24),
              const _RevenueByPackageSection(),
            ],
          ),
        ),
      ),
    );
  }
}

class _RangePicker extends StatelessWidget {
  final ReportDateRange range;
  final ValueChanged<ReportDateRange> onChanged;
  const _RangePicker({required this.range, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _pickRange(context),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.date_range, size: 18, color: AppColors.emeraldBright),
                const SizedBox(width: 10),
                Expanded(child: Text(range.label, style: const TextStyle(fontWeight: FontWeight.w600))),
                const Icon(Icons.expand_more, size: 18, color: AppColors.muted),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _QuickChip(label: 'Hari Ini', onTap: () => onChanged(ReportDateRange.today())),
            _QuickChip(label: 'Minggu Ini', onTap: () => onChanged(ReportDateRange.thisWeek())),
            _QuickChip(label: 'Bulan Ini', onTap: () => onChanged(ReportDateRange.thisMonth())),
            _QuickChip(label: 'Tahun Ini', onTap: () => onChanged(ReportDateRange.thisYear())),
            _QuickChip(label: '30 Hari Terakhir', onTap: () => onChanged(ReportDateRange.last30Days())),
          ],
        ),
      ],
    );
  }

  Future<void> _pickRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: DateTimeRange(start: range.start, end: range.end),
    );
    if (picked != null) {
      onChanged(ReportDateRange(start: picked.start, end: picked.end));
    }
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: onTap,
      backgroundColor: AppColors.surfaceVariant,
    );
  }
}

class _DownloadButtons extends ConsumerWidget {
  const _DownloadButtons();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _download(context, ref, asExcel: true),
            icon: const Icon(Icons.grid_on, size: 18),
            label: const Text('Excel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _download(context, ref, asExcel: false),
            icon: const Icon(Icons.picture_as_pdf, size: 18),
            label: const Text('PDF'),
          ),
        ),
      ],
    );
  }

  Future<void> _download(BuildContext context, WidgetRef ref, {required bool asExcel}) async {
    final range = ref.read(financialReportRangeProvider);
    final gymName = ref.read(gymSettingsStreamProvider).valueOrNull?.gymName;

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Menyiapkan file...'), duration: Duration(seconds: 2)));

    try {
      final trend = await ref.read(revenueTrendProvider.future);
      final byMethod = await ref.read(revenueByMethodPeriodProvider.future);
      final byPackage = await ref.read(revenueByPackagePeriodProvider.future);

      if (asExcel) {
        final bytes = buildFinancialReportExcel(
          range: range,
          gymName: gymName,
          trend: trend,
          byMethod: byMethod,
          byPackage: byPackage,
        );
        await downloadReportFile(
          bytes: bytes,
          filename: 'laporan-keuangan-${range.fileTag}.xlsx',
          mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        );
      } else {
        final bytes = await buildFinancialReportPdf(
          range: range,
          gymName: gymName,
          trend: trend,
          byMethod: byMethod,
          byPackage: byPackage,
        );
        await downloadReportFile(
          bytes: bytes,
          filename: 'laporan-keuangan-${range.fileTag}.pdf',
          mimeType: 'application/pdf',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membuat file: $e')));
      }
    }
  }
}

class _RevenueTrendSection extends ConsumerWidget {
  const _RevenueTrendSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(revenueTrendProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: dataAsync.when(
          loading: () => const SizedBox(
              height: 220, child: Center(child: CircularProgressIndicator())),
          error: (err, _) => Text('Gagal memuat: $err'),
          data: (trend) {
            final total = trend.fold<double>(0, (sum, t) => sum + t.total);
            final maxVal = trend.isEmpty ? 0.0 : trend.map((t) => t.total).reduce((a, b) => a > b ? a : b);
            final maxY = maxVal == 0 ? 100.0 : maxVal * 1.2;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tren Pendapatan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text('Total periode ini: ${formatRupiah(total)}',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.emeraldBright)),
                const SizedBox(height: 20),
                SizedBox(
                  height: 220,
                  child: trend.isEmpty
                      ? const Center(child: Text('Belum ada data pembayaran.'))
                      : BarChart(
                          BarChartData(
                            maxY: maxY,
                            barGroups: [
                              for (int i = 0; i < trend.length; i++)
                                BarChartGroupData(x: i, barRods: [
                                  BarChartRodData(
                                    toY: trend[i].total,
                                    color: AppColors.emeraldBright,
                                    width: trend.length > 20 ? 4 : 14,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
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
                                  interval: (trend.length / 6).clamp(1, trend.length).toDouble(),
                                  getTitlesWidget: (value, meta) {
                                    final i = value.toInt();
                                    if (i < 0 || i >= trend.length) return const SizedBox();
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(trend[i].periodLabel,
                                          style: const TextStyle(fontSize: 9)),
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
    final dataAsync = ref.watch(revenueByMethodPeriodProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: dataAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Text('Gagal memuat: $err'),
          data: (methods) {
            if (methods.isEmpty) return const Text('Belum ada data pembayaran di rentang ini.');
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
    final dataAsync = ref.watch(revenueByPackagePeriodProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: dataAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Text('Gagal memuat: $err'),
          data: (packages) {
            if (packages.isEmpty) return const Text('Belum ada data pembayaran di rentang ini.');
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
              Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
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
