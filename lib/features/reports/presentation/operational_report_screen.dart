import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data/reports_provider.dart';
import '../data/report_export.dart';
import '../domain/report_models.dart';
import '../../settings/data/gym_settings_provider.dart';
import '../../../shared/file_download/file_download.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/responsive.dart';

class OperationalReportScreen extends ConsumerWidget {
  const OperationalReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(operationalReportRangeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Operasional')),
      body: ResponsiveCenter(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(memberStatusCountsProvider);
            ref.invalidate(checkinsTrendProvider);
            ref.invalidate(popularClassesPeriodProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _RangePicker(
                range: range,
                onChanged: (r) => ref.read(operationalReportRangeProvider.notifier).state = r,
              ),
              const SizedBox(height: 16),
              const _DownloadButtons(),
              const SizedBox(height: 16),
              const _MemberStatusSection(),
              const SizedBox(height: 24),
              const _CheckinTrendSection(),
              const SizedBox(height: 24),
              const _PopularClassesSection(),
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
    final range = ref.read(operationalReportRangeProvider);
    final gymName = ref.read(gymSettingsStreamProvider).valueOrNull?.gymName;

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Menyiapkan file...'), duration: Duration(seconds: 2)));

    try {
      final memberStatus = await ref.read(memberStatusCountsProvider.future);
      final checkinTrend = await ref.read(checkinsTrendProvider.future);
      final popularClasses = await ref.read(popularClassesPeriodProvider.future);

      if (asExcel) {
        final bytes = buildOperationalReportExcel(
          range: range,
          gymName: gymName,
          memberStatus: memberStatus,
          checkinTrend: checkinTrend,
          popularClasses: popularClasses,
        );
        await downloadReportFile(
          bytes: bytes,
          filename: 'laporan-operasional-${range.fileTag}.xlsx',
          mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        );
      } else {
        final bytes = await buildOperationalReportPdf(
          range: range,
          gymName: gymName,
          memberStatus: memberStatus,
          checkinTrend: checkinTrend,
          popularClasses: popularClasses,
        );
        await downloadReportFile(
          bytes: bytes,
          filename: 'laporan-operasional-${range.fileTag}.pdf',
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

class _MemberStatusSection extends ConsumerWidget {
  const _MemberStatusSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(memberStatusCountsProvider);

    return dataAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Text('Gagal memuat: $err'),
      data: (statuses) {
        int countFor(String status) => statuses
            .firstWhere((s) => s.status == status, orElse: () => const MemberStatusCount(status: '', count: 0))
            .count;

        final active = countFor('active');
        final expiringSoon = countFor('expiring_soon');
        final expired = countFor('expired');
        final total = active + expiringSoon + expired;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status Member ($total total) — snapshot saat ini',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _StatCard(label: 'Aktif', count: active, color: AppColors.statusActive)),
                const SizedBox(width: 8),
                Expanded(
                    child: _StatCard(
                        label: 'Segera Habis', count: expiringSoon, color: AppColors.statusWarning)),
                const SizedBox(width: 8),
                Expanded(
                    child:
                        _StatCard(label: 'Kedaluwarsa', count: expired, color: AppColors.statusDanger)),
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
    final dataAsync = ref.watch(checkinsTrendProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: dataAsync.when(
          loading: () => const SizedBox(
              height: 200, child: Center(child: CircularProgressIndicator())),
          error: (err, _) => Text('Gagal memuat: $err'),
          data: (trend) {
            final total = trend.fold<int>(0, (sum, t) => sum + t.count);
            final maxVal = trend.isEmpty ? 0 : trend.map((t) => t.count).reduce((a, b) => a > b ? a : b);
            final maxY = (maxVal == 0 ? 5 : (maxVal * 1.3).ceil()).toDouble();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tren Check-in',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text('Total periode ini: $total check-in',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.emeraldBright)),
                const SizedBox(height: 20),
                SizedBox(
                  height: 180,
                  child: BarChart(
                    BarChartData(
                      maxY: maxY,
                      barGroups: [
                        for (int i = 0; i < trend.length; i++)
                          BarChartGroupData(x: i, barRods: [
                            BarChartRodData(
                              toY: trend[i].count.toDouble(),
                              color: i == trend.length - 1
                                  ? AppColors.emeraldBright
                                  : AppColors.emeraldDeep,
                              width: trend.length > 20 ? 4 : 16,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
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
                            interval: (trend.length / 6).clamp(1, trend.length).toDouble(),
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= trend.length) return const SizedBox();
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(trend[i].periodLabel, style: const TextStyle(fontSize: 9)),
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
    final dataAsync = ref.watch(popularClassesPeriodProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: dataAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Text('Gagal memuat: $err'),
          data: (classes) {
            if (classes.isEmpty) {
              return const Text('Belum ada data booking kelas di rentang ini.');
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
                                  backgroundColor: AppColors.emeraldBright.withOpacity(0.15),
                                  valueColor: const AlwaysStoppedAnimation(AppColors.emeraldBright),
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
