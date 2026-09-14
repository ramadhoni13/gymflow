import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/class_schedule_provider.dart';
import '../domain/class_schedule.dart';

class ClassFormScreen extends ConsumerStatefulWidget {
  final ClassSchedule? existingClass;

  const ClassFormScreen({super.key, this.existingClass});

  @override
  ConsumerState<ClassFormScreen> createState() => _ClassFormScreenState();
}

class _ClassFormScreenState extends ConsumerState<ClassFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _trainerController;
  late final TextEditingController _capacityController;
  late final TextEditingController _descriptionController;
  late DayOfWeek _dayOfWeek;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  bool get _isNew => widget.existingClass == null;

  @override
  void initState() {
    super.initState();
    final c = widget.existingClass;
    _nameController = TextEditingController(text: c?.name ?? '');
    _trainerController = TextEditingController(text: c?.trainerName ?? '');
    _capacityController = TextEditingController(text: (c?.capacity ?? 10).toString());
    _descriptionController = TextEditingController(text: c?.description ?? '');
    _dayOfWeek = c?.dayOfWeek ?? DayOfWeek.monday;
    _startTime = c != null ? _parseTime(c.startTime) : const TimeOfDay(hour: 7, minute: 0);
    _endTime = c != null ? _parseTime(c.endTime) : const TimeOfDay(hour: 8, minute: 0);
  }

  TimeOfDay _parseTime(String hhmm) {
    final parts = hhmm.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(classScheduleFormControllerProvider);

    ref.listen(classScheduleFormControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (err, _) => ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal menyimpan: $err'))),
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'Tambah Kelas' : 'Edit Kelas'),
        actions: [
          if (!_isNew)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Kelas'),
                validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _trainerController,
                decoration: const InputDecoration(labelText: 'Nama Trainer'),
                validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<DayOfWeek>(
                value: _dayOfWeek,
                decoration: const InputDecoration(labelText: 'Hari'),
                items: DayOfWeek.values
                    .map((d) => DropdownMenuItem(value: d, child: Text(d.label)))
                    .toList(),
                onChanged: (v) => setState(() => _dayOfWeek = v!),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _TimeField(
                      label: 'Jam Mulai',
                      time: _startTime,
                      onChanged: (t) => setState(() => _startTime = t),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimeField(
                      label: 'Jam Selesai',
                      time: _endTime,
                      onChanged: (t) => setState(() => _endTime = t),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _capacityController,
                decoration: const InputDecoration(labelText: 'Kapasitas (jumlah peserta)'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Wajib diisi';
                  if (int.tryParse(v) == null || int.parse(v) <= 0) return 'Harus angka lebih dari 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi (opsional)',
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: formState.isLoading ? null : _submit,
                child: formState.isLoading
                    ? const SizedBox(
                        height: 18, width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_isNew ? 'Simpan Kelas' : 'Simpan Perubahan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_endTime.hour < _startTime.hour ||
        (_endTime.hour == _startTime.hour && _endTime.minute <= _startTime.minute)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Jam selesai harus setelah jam mulai')));
      return;
    }

    final schedule = ClassSchedule(
      id: widget.existingClass?.id ?? '',
      name: _nameController.text.trim(),
      trainerName: _trainerController.text.trim(),
      dayOfWeek: _dayOfWeek,
      startTime: _formatTime(_startTime),
      endTime: _formatTime(_endTime),
      capacity: int.parse(_capacityController.text.trim()),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
    );

    final success = await ref
        .read(classScheduleFormControllerProvider.notifier)
        .save(schedule, isNew: _isNew);

    if (success && mounted) context.pop();
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus kelas?'),
        content: const Text('Jadwal kelas ini beserta riwayat bookingnya akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(classScheduleFormControllerProvider.notifier)
                  .delete(widget.existingClass!.id);
              if (success && mounted) context.pop();
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onChanged;

  const _TimeField({required this.label, required this.time, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(context: context, initialTime: time);
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        child: Text(
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
        ),
      ),
    );
  }
}
