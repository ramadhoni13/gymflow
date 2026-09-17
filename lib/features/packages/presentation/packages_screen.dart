import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/package_provider.dart';
import '../domain/membership_package.dart';
import '../../../shared/format_rupiah.dart';
import '../../../core/theme/app_theme.dart';

class PackagesScreen extends ConsumerWidget {
  const PackagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packagesAsync = ref.watch(packagesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Paket Membership')),
      body: packagesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Gagal memuat data: $err')),
        data: (packages) {
          if (packages.isEmpty) {
            return const Center(child: Text('Belum ada paket membership.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: packages.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _PackageCard(
              package: packages[index],
              onTap: () => context.push('/packages/${packages[index].id}', extra: packages[index]),
              onDelete: () => _confirmDelete(context, ref, packages[index]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/packages/new'),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Paket'),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, MembershipPackage package) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus paket?'),
        content: Text('Paket "${package.name}" akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              ref.read(packageFormControllerProvider.notifier).delete(package.id);
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: AppColors.statusDanger)),
          ),
        ],
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final MembershipPackage package;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PackageCard({required this.package, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(package.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  IconButton(icon: const Icon(Icons.delete_outline), onPressed: onDelete),
                ],
              ),
              const SizedBox(height: 8),
              // Baris harga bulanan
              _PriceRow(
                label: 'Per bulan',
                originalPrice: package.hasDiscount ? package.monthlyPrice : null,
                finalPrice: package.monthlyFinalPrice,
                discountBadge: package.hasDiscount
                    ? (package.discountType == DiscountType.percentage
                        ? '${package.discountValue!.toStringAsFixed(0)}%'
                        : formatRupiah(package.discountValue!))
                    : null,
              ),
              const SizedBox(height: 6),
              // Baris harga tahunan
              _PriceRow(
                label: 'Per tahun (bayar di muka)',
                originalPrice: package.annualBasePrice,
                finalPrice: package.annualFinalPrice,
                discountBadge: package.hasAnnualDiscount
                    ? 'Ekstra ${package.annualDiscountType == DiscountType.percentage ? '${package.annualDiscountValue!.toStringAsFixed(0)}%' : formatRupiah(package.annualDiscountValue!)}'
                    : null,
                badgeColor: AppColors.emeraldBright,
              ),
              if (package.hasAnnualDiscount && package.annualSavingsVsFullMonthly > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Hemat ${formatRupiah(package.annualSavingsVsFullMonthly)} dibanding bayar bulanan',
                    style: const TextStyle(fontSize: 12, color: AppColors.emeraldBright, fontWeight: FontWeight.w500),
                  ),
                ),
              if (package.bonus != null && package.bonus!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Bonus: ${package.bonus}', style: const TextStyle(fontSize: 12)),
                ),
              if (package.description != null && package.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    package.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final double? originalPrice;
  final double finalPrice;
  final String? discountBadge;
  final Color badgeColor;

  const _PriceRow({
    required this.label,
    this.originalPrice,
    required this.finalPrice,
    this.discountBadge,
    this.badgeColor = AppColors.gold,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        SizedBox(
          width: 140,
          child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
        ),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          children: [
            if (originalPrice != null && originalPrice != finalPrice)
              Text(
                formatRupiah(originalPrice!),
                style: const TextStyle(
                    decoration: TextDecoration.lineThrough, color: AppColors.muted, fontSize: 13),
              ),
            Text(formatRupiah(finalPrice), style: const TextStyle(fontWeight: FontWeight.w600)),
            if (discountBadge != null)
              Chip(
                label: Text(discountBadge!,
                    style: const TextStyle(
                        color: AppColors.ink, fontSize: 10, fontWeight: FontWeight.w600)),
                backgroundColor: badgeColor,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
          ],
        ),
      ],
    );
  }
}
