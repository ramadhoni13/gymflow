import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/staff_provider.dart';
import '../domain/staff_member.dart';
import '../../auth/domain/user_role.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/responsive.dart';

class StaffScreen extends ConsumerWidget {
  const StaffScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(staffStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen Staf')),
      body: ResponsiveCenter(child: staffAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Gagal memuat data: $err')),
        data: (staffList) {
          if (staffList.isEmpty) {
            return const Center(child: Text('Belum ada akun staf/admin.'));
          }
          return ListView.separated(
            itemCount: staffList.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final s = staffList[index];
              return ListTile(
                leading: CircleAvatar(child: Text(s.name.isNotEmpty ? s.name[0].toUpperCase() : '?')),
                title: Text(s.name),
                subtitle: Text(s.email),
                trailing: Chip(
                  label: Text(s.role.label),
                  backgroundColor:
                      s.role == UserRole.admin ? AppColors.gold.withOpacity(0.18) : AppColors.emeraldBright.withOpacity(0.18),
                ),
                onTap: () => _openEditSheet(context, ref, s),
              );
            },
          );
        },
      )),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/staff-management/new'),
        icon: const Icon(Icons.person_add),
        label: const Text('Tambah Staf'),
      ),
    );
  }

  void _openEditSheet(BuildContext context, WidgetRef ref, StaffMember staff) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _EditStaffSheet(staff: staff),
    );
  }
}

class _EditStaffSheet extends ConsumerStatefulWidget {
  final StaffMember staff;
  const _EditStaffSheet({required this.staff});

  @override
  ConsumerState<_EditStaffSheet> createState() => _EditStaffSheetState();
}

class _EditStaffSheetState extends ConsumerState<_EditStaffSheet> {
  late final TextEditingController _nameController;
  late UserRole _role;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.staff.name);
    _role = widget.staff.role;
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(staffActionControllerProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.staff.email, style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nama'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<UserRole>(
            value: _role,
            decoration: const InputDecoration(labelText: 'Role'),
            items: const [
              DropdownMenuItem(value: UserRole.admin, child: Text('Admin')),
              DropdownMenuItem(value: UserRole.staf, child: Text('Staf')),
            ],
            onChanged: (v) => setState(() => _role = v!),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: actionState.isLoading ? null : _confirmDelete,
                  icon: const Icon(Icons.delete_outline, color: AppColors.statusDanger),
                  label: const Text('Hapus Akun', style: TextStyle(color: AppColors.statusDanger)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: actionState.isLoading ? null : _save,
                  child: actionState.isLoading
                      ? const SizedBox(
                          height: 18, width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink))
                      : const Text('Simpan'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final success = await ref.read(staffActionControllerProvider.notifier).updateStaff(
          id: widget.staff.id,
          name: _nameController.text.trim(),
          role: _role.name,
        );
    if (success && mounted) Navigator.pop(context);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus akun ini?'),
        content: Text(
          '${widget.staff.name} (${widget.staff.email}) tidak akan bisa login lagi. Tindakan ini permanen.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: AppColors.statusDanger)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final success =
          await ref.read(staffActionControllerProvider.notifier).deleteStaff(widget.staff.id);
      if (mounted) {
        Navigator.pop(context);
        if (!success) {
          final err = ref.read(staffActionControllerProvider).error;
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Gagal menghapus: $err')));
        }
      }
    }
  }
}
