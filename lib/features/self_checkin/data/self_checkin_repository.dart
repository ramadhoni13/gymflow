import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../domain/self_checkin_result.dart';

class SelfCheckinRepository {
  final SupabaseClient _client = SupabaseService.client;

  Future<SelfCheckinResult> checkIn(String phone, {String? pin}) async {
    final res = await _client.functions
        .invoke('self-checkin', body: {'phone': phone, 'pin': pin ?? ''});

    final data = res.data;
    if (data is Map && data['error'] != null) {
      final message = data['error'].toString();
      if (res.status == 404) {
        throw MemberNotFoundException(message);
      }
      throw Exception(message);
    }
    if (res.status != 200) {
      throw Exception('Gagal memproses check-in (status ${res.status})');
    }

    return SelfCheckinResult.fromMap(data as Map<String, dynamic>);
  }
}
