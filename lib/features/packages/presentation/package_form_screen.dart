import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/package_provider.dart';
import '../domain/membership_package.dart';
import '../../../shared/format_rupiah.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/responsive.dart';

class PackageFormScreen extends ConsumerStatefulWidget {
  final MembershipPackage? existingPackage;

  const PackageFormScreen({super.key, this.existingPackage});

  @override
  ConsumerState<PackageFormScreen> createState() => _PackageFormScreenState();
}

class _PackageFormScreenState extends ConsumerState<PackageFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _monthlyPriceController;
  late final TextEditingController _bonusController;
  late final TextEditingController _discountValueController;
  late final TextEditingController _annualDiscountValueController;
  late final TextEditingController _descriptionController;
  late DiscountType _discountType;
  late DiscountType _annualDiscountType;

  bool get _isNew => widget.existingPackage == null;

  @override
  void initState() {
    super.initState();
    final p = widget.existingPackage;
    _nameController = TextEditingController(text: p?.name ?? '');
    _monthlyPriceController =
        TextEditingController(text: p != null ? p.monthlyPrice.toStringAsFixed(0) : '');
    _bonusController = TextEditingController(text: p?.bonus ?? '');
    _discountValueController = TextEditingController(
      text: p?.discountValue != null ? p!.discountValue!.toStringAsFixed(0) : '',
    );
    _annualDiscountValueController = TextEditingController(
      text: p?.annualDiscountValue != null ? p!.annualDiscountValue!.toStringAsFixed(0) : '',
    );
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _discountType = p?.discountType ?? DiscountType.none;
    _annualDiscountType = p?.annualDiscountType ?? DiscountType.none;
  }

  double get _previewMonthlyPrice => double.tryParse(_monthlyPriceController.text) ?? 0;
  double get _previewDiscountValue => double.tryParse(_discountValueController.text) ?? 0;
  double get _previewAnnualDiscountValue => double.tryParse(_annualDiscountValueController.text) ?? 0;

  double get _previewMonthlyFinal {
    switch (_discountType) {
      case DiscountType.percentage:
        return _previewMonthlyPrice - (_previewMonthlyPrice * _previewDiscountValue / 100);
      case DiscountType.nominal:
        return (_previewMonthlyPrice - _previewDiscountValue).clamp(0, _previewMonthlyPrice);
      case DiscountType.none:
        return _previewMonthlyPrice;
    }
  }

  double get _previewAnnualBase => _previewMonthlyFinal * 12;

  double get _previewAnnualFinal {
    switch (_annualDiscountType) {
      case DiscountType.percentage:
        return _previewAnnualBase - (_previewAnnualBase * _previewAnnualDiscountValue / 100);
      case DiscountType.nominal:
        return (_previewAnnualBase - _previewAnnualDiscountValue).clamp(0, _previewAnnualBase);
      case DiscountType.none:
        return _previewAnnualBase;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(packageFormControllerProvider);

    ref.listen(packageFormControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (err, _) => ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal menyimpan: $err'))),
      );
    });

    return Scaffold(
      appBar: AppBar(title: Text(_isNew ? 'Tambah Paket' : 'Edit Paket')),
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
                decoration: const InputDecoration(labelText: 'Nama Paket'),
                validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _monthlyPriceController,
                decoration: const InputDecoration(labelText: 'Harga per Bulan (Rp)', prefixText: 'Rp '),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Wajib diisi';
                  if (double.tryParse(v) == null) return 'Harus berupa angka';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bonusController,
                decoration: const InputDecoration(
                  labelText: 'Bonus (opsional)',
                  hintText: 'Misal: Gratis 1x personal training',
                ),
              ),
              const Divider(height: 32),
              const Text('Diskon Reguler', style: TextStyle(fontWeight: FontWeight.bold)),
              const Text(
                'Berlaku untuk harga bulanan, dan jadi dasar perhitungan harga tahunan.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<DiscountType>(
                value: _discountType,
                decoration: const InputDecoration(labelText: 'Jenis Diskon Reguler'),
                items: DiscountType.values
                    .map((d) => DropdownMenuItem(value: d, child: Text(d.label)))
                    .toList(),
                onChanged: (v) => setState(() => _discountType = v!),
              ),
              if (_discountType != DiscountType.none) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _discountValueController,
                  decoration: InputDecoration(
                    labelText: _discountType == DiscountType.percentage
                        ? 'Nilai Diskon (%)'
                        : 'Nilai Diskon (Rp)',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    if (_discountType == DiscountType.none) return null;
                    if (v == null || v.isEmpty) return 'Wajib diisi';
                    if (double.tryParse(v) == null) return 'Harus berupa angka';
                    return null;
                  },
                ),
              ],
              const Divider(height: 32),
              const Text('Diskon Tambahan Bayar Tahunan', style: TextStyle(fontWeight: FontWeight.bold)),
              const Text(
                'Diskon ekstra yang hanya berlaku kalau member bayar 12 bulan sekaligus di muka, di atas diskon reguler.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<DiscountType>(
                value: _annualDiscountType,
                decoration: const InputDecoration(labelText: 'Jenis Diskon Tahunan'),
                items: DiscountType.values
                    .map((d) => DropdownMenuItem(value: d, child: Text(d.label)))
                    .toList(),
                onChanged: (v) => setState(() => _annualDiscountType = v!),
              ),
              if (_annualDiscountType != DiscountType.none) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _annualDiscountValueController,
                  decoration: InputDecoration(
                    labelText: _annualDiscountType == DiscountType.percentage
                        ? 'Nilai Diskon Tahunan (%)'
                        : 'Nilai Diskon Tahunan (Rp)',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    if (_annualDiscountType == DiscountType.none) return null;
                    if (v == null || v.isEmpty) return 'Wajib diisi';
                    if (double.tryParse(v) == null) return 'Harus berupa angka';
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi Fitur (opsional)',
                  hintText: 'Misal: Akses semua kelas, gym buka 24 jam',
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              if (_previewMonthlyPrice > 0) _PreviewCard(
                monthlyFinal: _previewMonthlyFinal,
                annualBase: _previewAnnualBase,
                annualFinal: _previewAnnualFinal,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: formState.isLoading ? null : _submit,
                child: formState.isLoading
                    ? const SizedBox(
                        height: 18, width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink),
                      )
                    : Text(_isNew ? 'Simpan Paket' : 'Simpan Perubahan'),
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

    final package = MembershipPackage(
      id: widget.existingPackage?.id ?? '',
      name: _nameController.text.trim(),
      monthlyPrice: double.parse(_monthlyPriceController.text.trim()),
      bonus: _bonusController.text.trim().isEmpty ? null : _bonusController.text.trim(),
      discountType: _discountType,
      discountValue:
          _discountType == DiscountType.none ? null : double.parse(_discountValueController.text.trim()),
      annualDiscountType: _annualDiscountType,
      annualDiscountValue: _annualDiscountType == DiscountType.none
          ? null
          : double.parse(_annualDiscountValueController.text.trim()),
      description:
          _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
    );

    final success = await ref
        .read(packageFormControllerProvider.notifier)
        .save(package, isNew: _isNew);

    if (success && mounted) context.pop();
  }
}

class _PreviewCard extends StatelessWidget {
  final double monthlyFinal;
  final double annualBase;
  final double annualFinal;

  const _PreviewCard({required this.monthlyFinal, required this.annualBase, required this.annualFinal});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.indigo.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Preview Harga', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Per bulan: ${formatRupiah(monthlyFinal)}'),
            Text('Per tahun (12 bulan × harga bulanan setelah diskon): ${formatRupiah(annualBase)}'),
            Text(
              'Per tahun setelah diskon tambahan: ${formatRupiah(annualFinal)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
