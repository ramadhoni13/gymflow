import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/self_checkin_result.dart';
import 'self_checkin_repository.dart';

final selfCheckinRepositoryProvider = Provider<SelfCheckinRepository>(
  (ref) => SelfCheckinRepository(),
);

class SelfCheckinController extends StateNotifier<AsyncValue<SelfCheckinResult?>> {
  SelfCheckinController(this._repository) : super(const AsyncValue.data(null));

  final SelfCheckinRepository _repository;

  Future<void> checkIn(String phone, {String? pin}) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.checkIn(phone, pin: pin);
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reset() => state = const AsyncValue.data(null);
}

final selfCheckinControllerProvider =
    StateNotifierProvider.autoDispose<SelfCheckinController, AsyncValue<SelfCheckinResult?>>(
  (ref) => SelfCheckinController(ref.watch(selfCheckinRepositoryProvider)),
);
