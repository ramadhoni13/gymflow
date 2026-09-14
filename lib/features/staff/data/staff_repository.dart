import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../domain/staff_member.dart';

class StaffFunctionException implements Exception {
  final String message;
  StaffFunctionException(this.message);
  @override
  String toString() => message;
}

class StaffRepository {
  final SupabaseClient _client = SupabaseService.client;

  /// Stream semua akun dengan role admin/staf (owner sengaja tidak
  /// ditampilkan di sini — modul ini khusus kelola staf/admin).
  Stream<List<StaffMember>> watchStaff() {
    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .order('name')
        .map((rows) => rows
            .where((r) => r['role'] == 'admin' || r['role'] == 'staf')
            .map(StaffMember.fromMap)
            .toList());
  }

  Future<void> updateStaff({required String id, required String name, required String role}) async {
    await _client.from('profiles').update({'name': name, 'role': role}).eq('id', id);
  }

  Future<void> createStaff({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    final res = await _client.functions.invoke('create-staff', body: {
      'email': email,
      'password': password,
      'name': name,
      'role': role,
    });
    _throwIfError(res);
  }

  Future<void> deleteStaff(String userId) async {
    final res = await _client.functions.invoke('delete-staff', body: {'userId': userId});
    _throwIfError(res);
  }

  void _throwIfError(FunctionResponse res) {
    final data = res.data;
    if (data is Map && data['error'] != null) {
      throw StaffFunctionException(data['error'].toString());
    }
    if (res.status != 200) {
      throw StaffFunctionException('Gagal memproses permintaan (status ${res.status})');
    }
  }
}
