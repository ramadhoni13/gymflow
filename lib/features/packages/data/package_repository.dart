import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../domain/membership_package.dart';

class PackageRepository {
  final SupabaseClient _client = SupabaseService.client;
  static const _table = 'membership_packages';

  Stream<List<MembershipPackage>> watchPackages() {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('monthly_price')
        .map((rows) => rows.map(MembershipPackage.fromMap).toList());
  }

  Future<MembershipPackage> addPackage(MembershipPackage package) async {
    final data = await _client.from(_table).insert(package.toMap()).select().single();
    return MembershipPackage.fromMap(data);
  }

  Future<MembershipPackage> updatePackage(MembershipPackage package) async {
    final data = await _client
        .from(_table)
        .update(package.toMap())
        .eq('id', package.id)
        .select()
        .single();
    return MembershipPackage.fromMap(data);
  }

  Future<void> deletePackage(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }
}
