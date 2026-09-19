import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/class_schedule_provider.dart';
import '../domain/class_schedule.dart';
import '../../auth/data/auth_provider.dart';
import '../../auth/domain/user_role.dart';
import '../../../shared/responsive.dart';

class ClassesScreen extends ConsumerWidget {
  const ClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupedAsync = ref.watch(classesGroupedByDayProvider);
    final role = ref.watch(currentRoleProvider);
    final canManage = role?.canAccess('classes_schedule') ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Jadwal Kelas')),
      body: ResponsiveCenter(child: groupedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Gagal memuat data: $err')),
        data: (grouped) {
          if (grouped.isEmpty) {
            return const Center(child: Text('Belum ada jadwal kelas.'));
          }
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              for (final day in DayOfWeek.values)
                if (grouped[day] != null && grouped[day]!.isNotEmpty)
                  _DaySection(
                    day: day,
                    classes: grouped[day]!,
                    canManage: canManage,
                  ),
            ],
          );
        },
      )),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/class-management/new'),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Kelas'),
            )
          : null,
    );
  }
}

class _DaySection extends StatelessWidget {
  final DayOfWeek day;
  final List<ClassSchedule> classes;
  final bool canManage;

  const _DaySection({required this.day, required this.classes, required this.canManage});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(day.label, style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              )),
          const SizedBox(height: 6),
          ...classes.map((c) => Card(
                child: ListTile(
                  title: Text(c.name),
                  subtitle: Text('${c.startTime} - ${c.endTime} · Trainer: ${c.trainerName}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/classes/${c.id}', extra: c),
                ),
              )),
        ],
      ),
    );
  }
}
