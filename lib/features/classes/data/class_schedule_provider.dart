import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/class_schedule.dart';
import 'class_schedule_repository.dart';

final classScheduleRepositoryProvider = Provider<ClassScheduleRepository>(
  (ref) => ClassScheduleRepository(),
);

final classSchedulesStreamProvider = StreamProvider<List<ClassSchedule>>((ref) {
  return ref.watch(classScheduleRepositoryProvider).watchClasses();
});

/// Daftar kelas terurut per hari (Senin..Minggu) lalu jam mulai —
/// dihitung dari classSchedulesStreamProvider di sisi client.
final classesGroupedByDayProvider = Provider<AsyncValue<Map<DayOfWeek, List<ClassSchedule>>>>((ref) {
  final classesAsync = ref.watch(classSchedulesStreamProvider);
  return classesAsync.whenData((classes) {
    final sorted = [...classes]..sort((a, b) {
        final dayCompare = a.dayOfWeek.isoWeekday.compareTo(b.dayOfWeek.isoWeekday);
        if (dayCompare != 0) return dayCompare;
        return a.startTime.compareTo(b.startTime);
      });
    final grouped = <DayOfWeek, List<ClassSchedule>>{};
    for (final c in sorted) {
      grouped.putIfAbsent(c.dayOfWeek, () => []).add(c);
    }
    return grouped;
  });
});

class ClassScheduleFormController extends StateNotifier<AsyncValue<void>> {
  ClassScheduleFormController(this._repository) : super(const AsyncValue.data(null));

  final ClassScheduleRepository _repository;

  Future<bool> save(ClassSchedule schedule, {required bool isNew}) async {
    state = const AsyncValue.loading();
    try {
      if (isNew) {
        await _repository.addClass(schedule);
      } else {
        await _repository.updateClass(schedule);
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
      await _repository.deleteClass(id);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final classScheduleFormControllerProvider =
    StateNotifierProvider.autoDispose<ClassScheduleFormController, AsyncValue<void>>(
  (ref) => ClassScheduleFormController(ref.watch(classScheduleRepositoryProvider)),
);
