import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../domain/member.dart';

class MemberRepository {
  final SupabaseClient _client = SupabaseService.client;
  static const _table = 'members';

  /// Stream realtime daftar member, urut berdasarkan nama.
  Stream<List<Member>> watchMembers() {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('name')
        .map((rows) => rows.map(Member.fromMap).toList());
  }

  Future<List<Member>> fetchMembers({String? searchQuery}) async {
    var query = _client.from(_table).select();
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.ilike('name', '%$searchQuery%');
    }
    final data = await query.order('name');
    return (data as List).map((e) => Member.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<Member> addMember(Member member) async {
    final data = await _client.from(_table).insert(member.toMap()).select().single();
    return Member.fromMap(data);
  }

  Future<Member> updateMember(Member member) async {
    final data = await _client
        .from(_table)
        .update(member.toMap())
        .eq('id', member.id)
        .select()
        .single();
    return Member.fromMap(data);
  }

  Future<void> deleteMember(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }
}
