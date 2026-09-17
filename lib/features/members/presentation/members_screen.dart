import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/member_provider.dart';
import '../domain/member.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/responsive.dart';

class MembersScreen extends ConsumerWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(filteredMembersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Member')),
      body: ResponsiveCenter(
        child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Cari nama atau nomor telepon...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) =>
                  ref.read(memberSearchQueryProvider.notifier).state = value,
            ),
          ),
          Expanded(
            child: membersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Gagal memuat data: $err')),
              data: (members) {
                if (members.isEmpty) {
                  return const Center(child: Text('Belum ada member.'));
                }
                return ListView.separated(
                  itemCount: members.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final member = members[index];
                    return _MemberTile(
                      member: member,
                      onTap: () => context.push('/members/${member.id}', extra: member),
                      onDelete: () => _confirmDelete(context, ref, member),
                    );
                  },
                );
              },
            ),
          ),
        ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/members/new'),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Member'),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Member member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus member?'),
        content: Text('Data ${member.name} akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              ref.read(memberFormControllerProvider.notifier).delete(member.id);
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final Member member;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _MemberTile({required this.member, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (member.status) {
      MembershipStatus.active => ('Aktif', AppColors.statusActive),
      MembershipStatus.expiringSoon => ('Segera Habis', AppColors.statusWarning),
      MembershipStatus.expired => ('Kedaluwarsa', AppColors.statusDanger),
    };

    return ListTile(
      onTap: onTap,
      title: Text(member.name),
      subtitle: Text('${member.packageName} · ${member.phone}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Chip(
            label: Text(label, style: const TextStyle(color: AppColors.ink, fontSize: 12, fontWeight: FontWeight.w600)),
            backgroundColor: color,
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: onDelete),
        ],
      ),
    );
  }
}
