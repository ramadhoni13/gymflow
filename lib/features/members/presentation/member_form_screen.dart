import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/member_provider.dart';
import '../domain/member.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/responsive.dart';

class MemberFormScreen extends ConsumerStatefulWidget {
  final Member? existingMember;

  const MemberFormScreen({super.key, this.existingMember});

  @override
  ConsumerState<MemberFormScreen> createState() => _MemberFormScreenState();
}

class _MemberFormScreenState extends ConsumerState<MemberFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _packageController;
  late final TextEditingController _pinController;
  late DateTime _joinDate;
  late DateTime _endDate;

  bool get _isNew => widget.existingMember == null;

  @override
  void initState() {
    super.initState();
    final m = widget.existingMember;
    _nameController = TextEditingController(text: m?.name ?? '');
    _phoneController = TextEditingController(text: m?.phone ?? '');
    _emailController = TextEditingController(text: m?.email ?? '');
    _packageController = TextEditingController(text: m?.packageName ?? '');
    _pinController = TextEditingController(text: m?.pin ?? '');
    _joinDate = m?.joinDate ?? DateTime.now();
    _endDate = m?.membershipEndDate ?? DateTime.now().add(const Duration(days: 30));
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(memberFormControllerProvider);

    ref.listen(memberFormControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (err, _) => ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal menyimpan: $err'))),
      );
    });

    return Scaffold(
      appBar: AppBar(title: Text(_isNew ? 'Tambah Member' : 'Edit Member')),
      body: ResponsiveCenter(
        maxWidth: 640,
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Nomor Telepon'),
                keyboardType: TextInputType.phone,
                validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email (opsional)'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _packageController,
                decoration: const InputDecoration(labelText: 'Paket Membership'),
                validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pinController,
                decoration: const InputDecoration(
                  labelText: 'PIN Check-in Mandiri (4 digit, opsional)',
                  helperText:
                      'Kalau diisi, member wajib masukkan PIN ini (selain HP) saat self check-in tanpa login. Kosongkan kalau tidak perlu PIN.',
                  helperMaxLines: 3,
                  counterText: '',
                ),
                keyboardType: TextInputType.number,
                maxLength: 4,
                validator: (v) {
                  if (v == null || v.isEmpty) return null; // opsional
                  if (v.length != 4 || int.tryParse(v) == null) {
                    return 'PIN harus 4 digit angka';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _DatePickerField(
                label: 'Tanggal Bergabung',
                date: _joinDate,
                onChanged: (d) => setState(() => _joinDate = d),
              ),
              const SizedBox(height: 12),
              _DatePickerField(
                label: 'Membership Berakhir',
                date: _endDate,
                onChanged: (d) => setState(() => _endDate = d),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: formState.isLoading ? null : _submit,
                child: formState.isLoading
                    ? const SizedBox(
                        height: 18, width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink),
                      )
                    : Text(_isNew ? 'Simpan Member' : 'Simpan Perubahan'),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final member = Member(
      id: widget.existingMember?.id ?? '',
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      joinDate: _joinDate,
      packageName: _packageController.text.trim(),
      membershipEndDate: _endDate,
      pin: _pinController.text.trim().isEmpty ? null : _pinController.text.trim(),
    );

    final success = await ref
        .read(memberFormControllerProvider.notifier)
        .save(member, isNew: _isNew);

    if (success && mounted) context.pop();
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  const _DatePickerField({required this.label, required this.date, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        child: Text('${date.day}/${date.month}/${date.year}'),
      ),
    );
  }
}
