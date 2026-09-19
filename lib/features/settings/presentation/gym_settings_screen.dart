import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/gym_settings_provider.dart';
import '../domain/gym_settings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/responsive.dart';

class GymSettingsScreen extends ConsumerWidget {
  const GymSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(gymSettingsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan Gym')),
      body: ResponsiveCenter(
        maxWidth: 640,
        child: settingsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Gagal memuat data: $err')),
          data: (settings) => _GymSettingsForm(settings: settings),
        ),
      ),
    );
  }
}

class _GymSettingsForm extends ConsumerStatefulWidget {
  final GymSettings settings;
  const _GymSettingsForm({required this.settings});

  @override
  ConsumerState<_GymSettingsForm> createState() => _GymSettingsFormState();
}

class _GymSettingsFormState extends ConsumerState<_GymSettingsForm> {
  late final TextEditingController _gymName;
  late final TextEditingController _operationalHours;
  late final TextEditingController _address;
  late final TextEditingController _whatsapp;
  late final TextEditingController _email;
  late final TextEditingController _bankName;
  late final TextEditingController _bankAccountNumber;
  late final TextEditingController _bankAccountHolder;
  late final TextEditingController _qrisMerchantName;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    final s = widget.settings;
    _gymName = TextEditingController(text: s.gymName);
    _operationalHours = TextEditingController(text: s.operationalHours ?? '');
    _address = TextEditingController(text: s.address ?? '');
    _whatsapp = TextEditingController(text: s.whatsappNumber ?? '');
    _email = TextEditingController(text: s.operationalEmail ?? '');
    _bankName = TextEditingController(text: s.bankName ?? '');
    _bankAccountNumber = TextEditingController(text: s.bankAccountNumber ?? '');
    _bankAccountHolder = TextEditingController(text: s.bankAccountHolder ?? '');
    _qrisMerchantName = TextEditingController(text: s.qrisMerchantName ?? '');
    _notes = TextEditingController(text: s.notes ?? '');
  }

  @override
  void dispose() {
    for (final c in [
      _gymName, _operationalHours, _address, _whatsapp, _email,
      _bankName, _bankAccountNumber, _bankAccountHolder, _qrisMerchantName, _notes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(gymSettingsFormControllerProvider);

    ref.listen(gymSettingsFormControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (err, _) => ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal menyimpan: $err'))),
        data: (_) {
          if (previous is AsyncLoading) {
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Pengaturan tersimpan ✅')));
          }
        },
      );
    });

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionTitle('Informasi Umum'),
        TextField(
          controller: _gymName,
          decoration: const InputDecoration(labelText: 'Nama Gym'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _operationalHours,
          decoration: const InputDecoration(
            labelText: 'Jam Operasional',
            hintText: 'Misal: Senin-Sabtu 06.00-22.00, Minggu 08.00-20.00',
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _address,
          decoration: const InputDecoration(labelText: 'Alamat Lengkap'),
          maxLines: 3,
        ),

        const Divider(height: 32),
        _SectionTitle('Kontak'),
        TextField(
          controller: _whatsapp,
          decoration: const InputDecoration(
            labelText: 'Nomor WhatsApp',
            hintText: 'Misal: 6281234567890',
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _email,
          decoration: const InputDecoration(labelText: 'Email Operasional'),
          keyboardType: TextInputType.emailAddress,
        ),

        const Divider(height: 32),
        _SectionTitle('Pembayaran'),
        TextField(
          controller: _bankName,
          decoration: const InputDecoration(labelText: 'Nama Bank', hintText: 'Misal: BCA'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _bankAccountNumber,
          decoration: const InputDecoration(labelText: 'Nomor Rekening'),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _bankAccountHolder,
          decoration: const InputDecoration(labelText: 'Atas Nama Rekening'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _qrisMerchantName,
          decoration: const InputDecoration(
            labelText: 'Nama Merchant QRIS',
            helperText: 'Nama yang muncul di aplikasi pembayaran saat member scan QRIS',
          ),
        ),

        const Divider(height: 32),
        _SectionTitle('Lainnya'),
        TextField(
          controller: _notes,
          decoration: const InputDecoration(
            labelText: 'Catatan Tambahan (opsional)',
            hintText: 'Info lain yang perlu dicatat, mis. media sosial, kebijakan khusus, dll',
          ),
          maxLines: 3,
        ),

        const SizedBox(height: 24),
        FilledButton(
          onPressed: formState.isLoading ? null : _submit,
          child: formState.isLoading
              ? const SizedBox(
                  height: 18, width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink))
              : const Text('Simpan Pengaturan'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final settings = GymSettings(
      gymName: _gymName.text.trim(),
      operationalHours: _operationalHours.text.trim().isEmpty ? null : _operationalHours.text.trim(),
      address: _address.text.trim().isEmpty ? null : _address.text.trim(),
      whatsappNumber: _whatsapp.text.trim().isEmpty ? null : _whatsapp.text.trim(),
      operationalEmail: _email.text.trim().isEmpty ? null : _email.text.trim(),
      bankName: _bankName.text.trim().isEmpty ? null : _bankName.text.trim(),
      bankAccountNumber: _bankAccountNumber.text.trim().isEmpty ? null : _bankAccountNumber.text.trim(),
      bankAccountHolder: _bankAccountHolder.text.trim().isEmpty ? null : _bankAccountHolder.text.trim(),
      qrisMerchantName: _qrisMerchantName.text.trim().isEmpty ? null : _qrisMerchantName.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );

    await ref.read(gymSettingsFormControllerProvider.notifier).save(settings);
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }
}
