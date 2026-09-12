import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../domain/user_role.dart';

class AuthRepository {
  final SupabaseClient _client = SupabaseService.client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AppUser> login({required String email, required String password}) async {
    final res = await _client.auth.signInWithPassword(email: email, password: password);
    final userId = res.user?.id;
    if (userId == null) {
      throw Exception('Login gagal: user tidak ditemukan');
    }
    return _fetchProfile(userId);
  }

  Future<void> logout() => _client.auth.signOut();

  /// Ambil profil + role dari tabel `profiles` (dibuat terpisah dari auth.users
  /// bawaan Supabase, supaya bisa simpan field tambahan seperti nama & role).
  Future<AppUser> _fetchProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select('id, email, name, role')
        .eq('id', userId)
        .single();
    return AppUser.fromMap(data);
  }

  Future<AppUser?> currentUser() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    try {
      return await _fetchProfile(userId);
    } catch (_) {
      return null;
    }
  }
}
