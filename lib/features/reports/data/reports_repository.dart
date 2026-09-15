import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../domain/report_models.dart';

class ReportsRepository {
  final SupabaseClient _client = SupabaseService.client;

  Future<List<MonthlyRevenue>> revenueByMonth({int monthsBack = 6}) async {
    final data = await _client.rpc('rpc_revenue_by_month', params: {'months_back': monthsBack});
    return (data as List).map((e) => MonthlyRevenue.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<List<MethodRevenue>> revenueByMethod() async {
    final data = await _client.rpc('rpc_revenue_by_method');
    return (data as List).map((e) => MethodRevenue.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<List<PackageRevenue>> revenueByPackage() async {
    final data = await _client.rpc('rpc_revenue_by_package');
    return (data as List).map((e) => PackageRevenue.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<List<MemberStatusCount>> memberStatusCounts() async {
    final data = await _client.rpc('rpc_member_status_counts');
    return (data as List).map((e) => MemberStatusCount.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<List<DailyCheckinCount>> checkinsLast7Days() async {
    final data = await _client.rpc('rpc_checkins_last_7_days');
    return (data as List).map((e) => DailyCheckinCount.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<List<PopularClass>> popularClasses({int limit = 5}) async {
    final data = await _client.rpc('rpc_popular_classes', params: {'result_limit': limit});
    return (data as List).map((e) => PopularClass.fromMap(e as Map<String, dynamic>)).toList();
  }
}
