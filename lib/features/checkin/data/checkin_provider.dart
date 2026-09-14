import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../members/data/member_provider.dart';
import '../../members/data/member_repository.dart';
import '../../members/domain/member.dart';
import '../domain/check_in.dart';
import 'checkin_repository.dart';

final checkinRepositoryProvider = Provider<CheckinRepository>((ref) => CheckinRepository());

/// Stream semua check-in terbaru, difilter jadi "hari ini" saja di sini.
final todayCheckinsProvider = Provider<AsyncValue<List<CheckIn>>>((ref) {
  final recentAsync = ref.watch(_recentCheckinsStreamProvider);
  return recentAsync.whenData((list) {
    final now = DateTime.now();
    return list.where((c) =>
        c.checkedInAt.year == now.year &&
        c.checkedInAt.month == now.month &&
        c.checkedInAt.day == now.day).toList();
  });
});

final _recentCheckinsStreamProvider = StreamProvider<List<CheckIn>>((ref) {
  return ref.watch(checkinRepositoryProvider).watchRecentCheckins();
});

/// Query pencarian member untuk proses check-in.
final checkinSearchQueryProvider = StateProvider<String>((ref) => '');

/// Hasil pencarian member (memakai MemberRepository yang sudah ada).
final checkinSearchResultsProvider = FutureProvider.autoDispose<List<Member>>((ref) async {
  final query = ref.watch(checkinSearchQueryProvider);
  if (query.trim().isEmpty) return [];
  final repo = ref.watch(memberRepositoryProvider);
  return repo.fetchMembers(searchQuery: query.trim());
});

class CheckinActionController extends StateNotifier<AsyncValue<void>> {
  CheckinActionController(this._repository) : super(const AsyncValue.data(null));

  final CheckinRepository _repository;

  Future<bool> checkIn(Member member) async {
    state = const AsyncValue.loading();
    try {
      await _repository.addCheckIn(memberId: member.id, memberName: member.name);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final checkinActionControllerProvider =
    StateNotifierProvider.autoDispose<CheckinActionController, AsyncValue<void>>(
  (ref) => CheckinActionController(ref.watch(checkinRepositoryProvider)),
);
