import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/staff_member.dart';
import 'staff_repository.dart';

final staffRepositoryProvider = Provider<StaffRepository>((ref) => StaffRepository());

final staffStreamProvider = StreamProvider<List<StaffMember>>((ref) {
  return ref.watch(staffRepositoryProvider).watchStaff();
});

class StaffActionController extends StateNotifier<AsyncValue<void>> {
  StaffActionController(this._repository) : super(const AsyncValue.data(null));

  final StaffRepository _repository;

  Future<bool> createStaff({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createStaff(email: email, password: password, name: name, role: role);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateStaff({required String id, required String name, required String role}) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateStaff(id: id, name: name, role: role);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteStaff(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteStaff(id);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final staffActionControllerProvider =
    StateNotifierProvider.autoDispose<StaffActionController, AsyncValue<void>>(
  (ref) => StaffActionController(ref.watch(staffRepositoryProvider)),
);
