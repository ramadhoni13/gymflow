import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../members/data/member_provider.dart';
import '../../members/domain/member.dart';
import '../domain/class_booking.dart';
import '../domain/class_schedule.dart';
import 'class_booking_repository.dart';

final classBookingRepositoryProvider = Provider<ClassBookingRepository>(
  (ref) => ClassBookingRepository(),
);

/// Stream semua booking untuk satu jadwal kelas (lintas tanggal), dipakai
/// oleh halaman detail kelas untuk difilter ke tanggal yang sedang dipilih.
final classBookingsStreamProvider =
    StreamProvider.family.autoDispose<List<ClassBooking>, String>((ref, classScheduleId) {
  return ref.watch(classBookingRepositoryProvider).watchBookingsForClass(classScheduleId);
});

/// Query pencarian member khusus untuk proses booking kelas
/// (terpisah dari pencarian di modul Check-in supaya state-nya tidak campur).
final bookingSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final bookingSearchResultsProvider = FutureProvider.autoDispose<List<Member>>((ref) async {
  final query = ref.watch(bookingSearchQueryProvider);
  if (query.trim().isEmpty) return [];
  final repo = ref.watch(memberRepositoryProvider);
  return repo.fetchMembers(searchQuery: query.trim());
});

class BookingActionController extends StateNotifier<AsyncValue<void>> {
  BookingActionController(this._repository) : super(const AsyncValue.data(null));

  final ClassBookingRepository _repository;

  Future<bool> book({
    required ClassSchedule schedule,
    required Member member,
    required DateTime classDate,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.addBooking(
        classScheduleId: schedule.id,
        memberId: member.id,
        memberName: member.name,
        classDate: classDate,
        capacity: schedule.capacity,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> cancel(String bookingId) async {
    try {
      await _repository.cancelBooking(bookingId);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final bookingActionControllerProvider =
    StateNotifierProvider.autoDispose<BookingActionController, AsyncValue<void>>(
  (ref) => BookingActionController(ref.watch(classBookingRepositoryProvider)),
);
