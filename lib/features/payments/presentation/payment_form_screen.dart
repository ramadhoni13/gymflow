import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import '../data/payment_provider.dart';
import '../data/invoice_pdf.dart';
import '../domain/payment.dart';
import '../../members/domain/member.dart';
import '../../packages/data/package_provider.dart';
import '../../packages/domain/membership_package.dart';
import '../../../shared/format_rupiah.dart';
import '../../settings/data/gym_settings_provider.dart';
import '../../../shared/responsive.dart';
import '../../../core/theme/app_theme.dart';

class PaymentFormScreen extends ConsumerStatefulWidget {
  const PaymentFormScreen({super.key});

  @override
  ConsumerState<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends ConsumerState<PaymentFormScreen> {
  Member? _selectedMember;
  MembershipPackage? _selectedPackage;
  BillingType _billingType = BillingType.monthly;
  PaymentMethod _method = PaymentMethod.cash;
  DateTime _paymentDate = DateTime.now();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  double get _suggestedAmount {
    if (_selectedPackage == null) return 0;
    return _billingType == BillingType.monthly
        ? _selectedPackage!.monthlyFinalPrice
        : _selectedPackage!.annualFinalPrice;
  }

  void _recalculateAmount() {
    _amountController.text = _suggestedAmount.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(paymentFormControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Catat Pembayaran')),
      body: ResponsiveCenter(
        maxWidth: 640,
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text('Member', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _selectedMember == null
                ? _MemberSearchField(
                    onSelected: (m) => setState(() => _selectedMember = m),
                  )
                : Card(
                    child: ListTile(
                      title: Text(_selectedMember!.name),
                      subtitle: Text(_selectedMember!.phone),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _selectedMember = null),
                      ),
                    ),
                  ),
            const Divider(height: 32),
            const Text('Paket Membership', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _PackageDropdown(
              selected: _selectedPackage,
              onChanged: (pkg) {
                setState(() => _selectedPackage = pkg);
                _recalculateAmount();
              },
            ),
            if (_selectedPackage != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<BillingType>(
                    segments: [
                      ButtonSegment(
                        value: BillingType.monthly,
                        label: Text('Bulanan\n${formatRupiah(_selectedPackage!.monthlyFinalPrice)}',
                            textAlign: TextAlign.center),
                      ),
                      ButtonSegment(
                        value: BillingType.annual,
                        label: Text('Tahunan\n${formatRupiah(_selectedPackage!.annualFinalPrice)}',
                            textAlign: TextAlign.center),
                      ),
                    ],
                    selected: {_billingType},
                    onSelectionChanged: (selection) {
                      setState(() => _billingType = selection.first);
                      _recalculateAmount();
                    },
                  ),
                ),
              ),
            ],
            const Divider(height: 32),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Jumlah Dibayar (Rp)',
                prefixText: 'Rp ',
                helperText: 'Otomatis terisi dari paket, bisa diedit kalau perlu penyesuaian',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PaymentMethod>(
              value: _method,
              decoration: const InputDecoration(labelText: 'Metode Pembayaran'),
              items: PaymentMethod.values
                  .map((m) => DropdownMenuItem(value: m, child: Text(m.label)))
                  .toList(),
              onChanged: (v) => setState(() => _method = v!),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Tanggal Pembayaran'),
                child: Text(_formatDate(_paymentDate)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: formState.isLoading ? null : _submit,
              child: formState.isLoading
                  ? const SizedBox(
                      height: 18, width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink))
                  : const Text('Simpan & Buat Invoice'),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _paymentDate = picked);
  }

  Future<void> _submit() async {
    if (_selectedMember == null) {
      _showError('Pilih member dulu');
      return;
    }
    if (_selectedPackage == null) {
      _showError('Pilih paket membership dulu');
      return;
    }
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _showError('Jumlah pembayaran tidak valid');
      return;
    }

    final payment = await ref.read(paymentFormControllerProvider.notifier).submit(
          member: _selectedMember!,
          packageId: _selectedPackage!.id,
          packageName: _selectedPackage!.name,
          billingType: _billingType,
          amount: amount,
          method: _method,
          paymentDate: _paymentDate,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );

    if (payment != null && mounted) {
      _showSuccessDialog(payment);
    } else if (mounted) {
      final err = ref.read(paymentFormControllerProvider).error;
      _showError('Gagal menyimpan: $err');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showSuccessDialog(Payment payment) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Pembayaran berhasil dicatat ✅'),
        content: Text(
          'Invoice ${payment.invoiceNumber}\nMembership ${payment.memberName} diperpanjang sampai ${_formatDate(payment.membershipEndDateAfter)}.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            child: const Text('Tutup'),
          ),
          FilledButton.icon(
            onPressed: () {
              final settings = ref.read(gymSettingsStreamProvider).valueOrNull;
              Printing.layoutPdf(
                  onLayout: (format) => buildInvoicePdf(payment, gymSettings: settings));
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Lihat/Cetak Invoice'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

class _MemberSearchField extends ConsumerWidget {
  final ValueChanged<Member> onSelected;
  const _MemberSearchField({required this.onSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(paymentMemberSearchResultsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: const InputDecoration(
            hintText: 'Cari nama atau nomor telepon member...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (value) => ref.read(paymentMemberSearchQueryProvider.notifier).state = value,
        ),
        resultsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(8),
            child: LinearProgressIndicator(),
          ),
          error: (err, _) => Padding(padding: const EdgeInsets.all(8), child: Text('Error: $err')),
          data: (members) => Column(
            children: members
                .map((m) => ListTile(
                      title: Text(m.name),
                      subtitle: Text(m.phone),
                      onTap: () => onSelected(m),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _PackageDropdown extends ConsumerWidget {
  final MembershipPackage? selected;
  final ValueChanged<MembershipPackage?> onChanged;

  const _PackageDropdown({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packagesAsync = ref.watch(packagesStreamProvider);

    return packagesAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (err, _) => Text('Gagal memuat paket: $err'),
      data: (packages) {
        return DropdownButtonFormField<MembershipPackage>(
          value: selected,
          decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
          hint: const Text('Pilih paket'),
          items: packages
              .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
              .toList(),
          onChanged: onChanged,
        );
      },
    );
  }
}
