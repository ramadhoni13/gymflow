import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/user_role.dart';
import 'auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

/// Menyimpan AppUser yang sedang login (null = belum login / logout).
class AuthController extends StateNotifier<AsyncValue<AppUser?>> {
  AuthController(this._repository) : super(const AsyncValue.loading()) {
    _init();
  }

  final AuthRepository _repository;

  Future<void> _init() async {
    state = AsyncValue.data(await _repository.currentUser());
    _repository.authStateChanges.listen((_) async {
      state = AsyncValue.data(await _repository.currentUser());
    });
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.login(email: email, password: password);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AsyncValue.data(null);
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<AppUser?>>(
  (ref) => AuthController(ref.watch(authRepositoryProvider)),
);

/// Shortcut: role user yang sedang login, null kalau belum login.
final currentRoleProvider = Provider<UserRole?>((ref) {
  return ref.watch(authControllerProvider).valueOrNull?.role;
});
