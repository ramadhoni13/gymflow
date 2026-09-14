import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/checkin_provider.dart';
import '../domain/check_in.dart';
import '../../members/domain/member.dart';

class CheckinScreen extends ConsumerWidget {
  const CheckinScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check-in Member')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Cari nama atau nomor telepon member...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) => ref.read(checkinSearchQueryProvider.notifier).state = value,
            ),
          ),
          Expanded(child: _SearchResultsOrHistory(ref: ref)),
        ],
      ),
    );
  }
}

class _SearchResultsOrHistory extends ConsumerWidget {
  final WidgetRef ref;
  const _SearchResultsOrHistory({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(checkinSearchQueryProvider);

    if (query.trim().isEmpty) {
      return const _TodayCheckinList();
    }

    final resultsAsync = ref.watch(checkinSearchResultsProvider);
    return resultsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Gagal mencari: $err')),
      data: (members) {
        if (members.isEmpty) {
          return const Center(child: Text('Member tidak ditemukan.'));
        }
        return ListView.separated(
          itemCount: members.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) => _MemberSearchTile(member: members[index]),
        );
      },
    );
  }
}

class _MemberSearchTile extends ConsumerWidget {
  final Member member;
  const _MemberSearchTile({required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionState = ref.watch(checkinActionControllerProvider);
    final (label, color) = switch (member.status) {
      MembershipStatus.active => ('Aktif', Colors.green),
      MembershipStatus.expiringSoon => ('Segera Habis', Colors.orange),
      MembershipStatus.expired => ('Kedaluwarsa', Colors.red),
    };

    return ListTile(
      title: Text(member.name),
      subtitle: Text('${member.packageName} · ${member.phone} · $label'),
      trailing: FilledButton(
        onPressed: actionState.isLoading ? null : () => _handleCheckIn(context, ref),
        style: FilledButton.styleFrom(
          backgroundColor: member.status == MembershipStatus.expired ? Colors.grey : color,
        ),
        child: const Text('Check-in'),
      ),
    );
  }

  Future<void> _handleCheckIn(BuildContext context, WidgetRef ref) async {
    if (member.status == MembershipStatus.expired) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Membership sudah kedaluwarsa'),
          content: Text(
            '${member.name} membership-nya sudah berakhir. Tetap catat check-in?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Tetap Check-in'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    final success = await ref.read(checkinActionControllerProvider.notifier).checkIn(member);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '${member.name} berhasil check-in ✅' : 'Gagal mencatat check-in'),
        ),
      );
      if (success) {
        ref.read(checkinSearchQueryProvider.notifier).state = '';
      }
    }
  }
}

class _TodayCheckinList extends ConsumerWidget {
  const _TodayCheckinList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkinsAsync = ref.watch(todayCheckinsProvider);

    return checkinsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Gagal memuat riwayat: $err')),
      data: (checkins) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'Check-in Hari Ini (${checkins.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Expanded(
              child: checkins.isEmpty
                  ? const Center(child: Text('Belum ada check-in hari ini.'))
                  : ListView.separated(
                      itemCount: checkins.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final c = checkins[index];
                        return ListTile(
                          leading: const Icon(Icons.check_circle, color: Colors.green),
                          title: Text(c.memberName),
                          trailing: Text(_formatTime(c.checkedInAt)),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
