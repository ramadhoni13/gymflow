import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../domain/check_in.dart';

class CheckinRepository {
  final SupabaseClient _client = SupabaseService.client;
  static const _table = 'check_ins';

  /// Stream semua check-in (diurutkan terbaru dulu), sudah join nama member.
  /// Filter "hari ini" dilakukan di sisi client (lihat checkin_provider.dart)
  /// karena realtime stream Supabase tidak mendukung filter tanggal dinamis.
  Stream<List<CheckIn>> watchRecentCheckins() {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('checked_in_at', ascending: false)
        .limit(200)
        .map((rows) => rows.map(CheckIn.fromMap).toList());
  }

  Future<CheckIn> addCheckIn({
    required String memberId,
    required String memberName,
    String? notes,
  }) async {
    final data = await _client
        .from(_table)
        .insert({
          'member_id': memberId,
          'member_name': memberName,
          'checked_in_by': _client.auth.currentUser?.id,
          'notes': notes,
        })
        .select()
        .single();
    return CheckIn.fromMap(data);
  }
}
