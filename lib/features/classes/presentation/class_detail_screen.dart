import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/class_booking_provider.dart';
import '../data/class_booking_repository.dart';
import '../domain/class_booking.dart';
import '../domain/class_schedule.dart';
import '../../auth/data/auth_provider.dart';
import '../../auth/domain/user_role.dart';
import '../../members/domain/member.dart';

class ClassDetailScreen extends ConsumerStatefulWidget {
  final ClassSchedule schedule;

  const ClassDetailScreen({super.key, required this.schedule});

  @override
  ConsumerState<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends ConsumerState<ClassDetailScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.schedule.nextOccurrenceDate;
  }

  bool _isSameDate(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final schedule = widget.schedule;
    final role = ref.watch(currentRoleProvider);
    final canManage = role?.canAccess('classes_schedule') ?? false;
    final bookingsAsync = ref.watch(classBookingsStreamProvider(schedule.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(schedule.name),
        actions: [
          if (canManage)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.push('/class-management/${schedule.id}', extra: schedule),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${schedule.dayOfWeek.label}, ${schedule.startTime} - ${schedule.endTime}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text('Trainer: ${schedule.trainerName}'),
                if (schedule.description != null && schedule.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(schedule.description!, style: const TextStyle(color: Colors.grey)),
                  ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickDate,
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(_selectedDate),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: bookingsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Gagal memuat booking: $err')),
              data: (allBookings) {
                final bookingsForDate =
                    allBookings.where((b) => _isSameDate(b.classDate, _selectedDate)).toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text(
                        'Booking (${bookingsForDate.length}/${schedule.capacity})',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Expanded(
                      child: bookingsForDate.isEmpty
                          ? const Center(child: Text('Belum ada booking untuk tanggal ini.'))
                          : ListView.separated(
                              itemCount: bookingsForDate.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final b = bookingsForDate[index];
                                return ListTile(
                                  leading: const Icon(Icons.person),
                                  title: Text(b.memberName),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () => _cancelBooking(b),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openBookingSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Booking'),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      selectableDayPredicate: (date) => date.weekday == widget.schedule.dayOfWeek.isoWeekday,
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _cancelBooking(ClassBooking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan booking?'),
        content: Text('Booking atas nama ${booking.memberName} akan dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Tidak')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Batalkan')),
        ],
      ),
    );
    if (confirmed == true) {
      final success = await ref.read(bookingActionControllerProvider.notifier).cancel(booking.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Booking dibatalkan' : 'Gagal membatalkan booking'),
          ),
        );
      }
    }
  }

  void _openBookingSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _BookingSheet(schedule: widget.schedule, classDate: _selectedDate),
    );
  }

  String _formatDate(DateTime d) {
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

class _BookingSheet extends ConsumerWidget {
  final ClassSchedule schedule;
  final DateTime classDate;

  const _BookingSheet({required this.schedule, required this.classDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(bookingSearchResultsProvider);
    final actionState = ref.watch(bookingActionControllerProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tambah Booking', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Cari nama atau nomor telepon member...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) => ref.read(bookingSearchQueryProvider.notifier).state = value,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: resultsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Gagal mencari: $err')),
                data: (members) {
                  if (members.isEmpty) {
                    return const Center(child: Text('Ketik nama untuk mencari member.'));
                  }
                  return ListView.separated(
                    itemCount: members.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final member = members[index];
                      return ListTile(
                        title: Text(member.name),
                        subtitle: Text(member.phone),
                        trailing: FilledButton(
                          onPressed: actionState.isLoading ? null : () => _book(context, ref, member),
                          child: const Text('Booking'),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _book(BuildContext context, WidgetRef ref, Member member) async {
    final success = await ref.read(bookingActionControllerProvider.notifier).book(
          schedule: schedule,
          member: member,
          classDate: classDate,
        );

    if (context.mounted) {
      final errorObj = ref.read(bookingActionControllerProvider).error;
      final message = success
          ? '${member.name} berhasil di-booking ✅'
          : (errorObj is BookingFullException || errorObj is AlreadyBookedException
              ? errorObj.toString()
              : 'Gagal booking: $errorObj');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      if (success) {
        ref.read(bookingSearchQueryProvider.notifier).state = '';
        Navigator.pop(context);
      }
    }
  }
}
