import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/report_models.dart';
import 'reports_repository.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) => ReportsRepository());

final revenueByMonthProvider = FutureProvider.autoDispose<List<MonthlyRevenue>>((ref) {
  return ref.watch(reportsRepositoryProvider).revenueByMonth();
});

final revenueByMethodProvider = FutureProvider.autoDispose<List<MethodRevenue>>((ref) {
  return ref.watch(reportsRepositoryProvider).revenueByMethod();
});

final revenueByPackageProvider = FutureProvider.autoDispose<List<PackageRevenue>>((ref) {
  return ref.watch(reportsRepositoryProvider).revenueByPackage();
});

final memberStatusCountsProvider = FutureProvider.autoDispose<List<MemberStatusCount>>((ref) {
  return ref.watch(reportsRepositoryProvider).memberStatusCounts();
});

final checkinsLast7DaysProvider = FutureProvider.autoDispose<List<DailyCheckinCount>>((ref) {
  return ref.watch(reportsRepositoryProvider).checkinsLast7Days();
});

final popularClassesProvider = FutureProvider.autoDispose<List<PopularClass>>((ref) {
  return ref.watch(reportsRepositoryProvider).popularClasses();
});

// ===== Filter rentang tanggal bebas =====
// State rentang dipisah per halaman supaya tidak saling memengaruhi.
// Default: 30 hari terakhir.
final financialReportRangeProvider =
    StateProvider.autoDispose<ReportDateRange>((ref) => ReportDateRange.last30Days());
final operationalReportRangeProvider =
    StateProvider.autoDispose<ReportDateRange>((ref) => ReportDateRange.last30Days());

final revenueTrendProvider = FutureProvider.autoDispose<List<RevenueTrendPoint>>((ref) {
  final range = ref.watch(financialReportRangeProvider);
  return ref.watch(reportsRepositoryProvider).revenueTrendRange(
        start: range.start,
        end: range.end,
        granularity: range.granularity,
      );
});

final revenueByMethodPeriodProvider = FutureProvider.autoDispose<List<MethodRevenue>>((ref) {
  final range = ref.watch(financialReportRangeProvider);
  return ref
      .watch(reportsRepositoryProvider)
      .revenueByMethodPeriod(start: range.start, end: range.end);
});

final revenueByPackagePeriodProvider = FutureProvider.autoDispose<List<PackageRevenue>>((ref) {
  final range = ref.watch(financialReportRangeProvider);
  return ref
      .watch(reportsRepositoryProvider)
      .revenueByPackagePeriod(start: range.start, end: range.end);
});

final checkinsTrendProvider = FutureProvider.autoDispose<List<CheckinTrendPoint>>((ref) {
  final range = ref.watch(operationalReportRangeProvider);
  return ref.watch(reportsRepositoryProvider).checkinsTrendRange(
        start: range.start,
        end: range.end,
        granularity: range.granularity,
      );
});

final popularClassesPeriodProvider = FutureProvider.autoDispose<List<PopularClass>>((ref) {
  final range = ref.watch(operationalReportRangeProvider);
  return ref
      .watch(reportsRepositoryProvider)
      .popularClassesPeriod(start: range.start, end: range.end);
});
