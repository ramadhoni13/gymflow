import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/membership_package.dart';
import 'package_repository.dart';

final packageRepositoryProvider = Provider<PackageRepository>((ref) => PackageRepository());

final packagesStreamProvider = StreamProvider<List<MembershipPackage>>((ref) {
  return ref.watch(packageRepositoryProvider).watchPackages();
});

class PackageFormController extends StateNotifier<AsyncValue<void>> {
  PackageFormController(this._repository) : super(const AsyncValue.data(null));

  final PackageRepository _repository;

  Future<bool> save(MembershipPackage package, {required bool isNew}) async {
    state = const AsyncValue.loading();
    try {
      if (isNew) {
        await _repository.addPackage(package);
      } else {
        await _repository.updatePackage(package);
      }
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> delete(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deletePackage(id);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final packageFormControllerProvider =
    StateNotifierProvider.autoDispose<PackageFormController, AsyncValue<void>>(
  (ref) => PackageFormController(ref.watch(packageRepositoryProvider)),
);
