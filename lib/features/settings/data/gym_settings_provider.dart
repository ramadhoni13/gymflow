import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/gym_settings.dart';
import 'gym_settings_repository.dart';

final gymSettingsRepositoryProvider = Provider<GymSettingsRepository>(
  (ref) => GymSettingsRepository(),
);

final gymSettingsStreamProvider = StreamProvider<GymSettings>((ref) {
  return ref.watch(gymSettingsRepositoryProvider).watchSettings();
});

class GymSettingsFormController extends StateNotifier<AsyncValue<void>> {
  GymSettingsFormController(this._repository) : super(const AsyncValue.data(null));

  final GymSettingsRepository _repository;

  Future<bool> save(GymSettings settings) async {
    state = const AsyncValue.loading();
    try {
      await _repository.saveSettings(settings);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final gymSettingsFormControllerProvider =
    StateNotifierProvider.autoDispose<GymSettingsFormController, AsyncValue<void>>(
  (ref) => GymSettingsFormController(ref.watch(gymSettingsRepositoryProvider)),
);
