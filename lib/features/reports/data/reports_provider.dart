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
