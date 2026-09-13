import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/member.dart';
import 'member_repository.dart';

final memberRepositoryProvider = Provider<MemberRepository>((ref) => MemberRepository());

/// Stream realtime semua member — dipakai untuk list utama.
final membersStreamProvider = StreamProvider<List<Member>>((ref) {
  return ref.watch(memberRepositoryProvider).watchMembers();
});

/// Search query yang diketik user di kotak pencarian.
final memberSearchQueryProvider = StateProvider<String>((ref) => '');

/// Daftar member yang sudah difilter oleh search query, di sisi client.
/// (Untuk dataset besar, lebih baik pindah ke fetchMembers(searchQuery: ...) di server.)
final filteredMembersProvider = Provider<AsyncValue<List<Member>>>((ref) {
  final membersAsync = ref.watch(membersStreamProvider);
  final query = ref.watch(memberSearchQueryProvider).toLowerCase();

  return membersAsync.whenData((members) {
    if (query.isEmpty) return members;
    return members
        .where((m) => m.name.toLowerCase().contains(query) || m.phone.contains(query))
        .toList();
  });
});

class MemberFormController extends StateNotifier<AsyncValue<void>> {
  MemberFormController(this._repository) : super(const AsyncValue.data(null));

  final MemberRepository _repository;

  Future<bool> save(Member member, {required bool isNew}) async {
    state = const AsyncValue.loading();
    try {
      if (isNew) {
        await _repository.addMember(member);
      } else {
        await _repository.updateMember(member);
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
      await _repository.deleteMember(id);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final memberFormControllerProvider =
    StateNotifierProvider.autoDispose<MemberFormController, AsyncValue<void>>(
  (ref) => MemberFormController(ref.watch(memberRepositoryProvider)),
);
