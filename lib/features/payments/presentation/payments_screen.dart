import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import '../data/payment_provider.dart';
import '../data/invoice_pdf.dart';
import '../domain/payment.dart';
import '../../../shared/format_rupiah.dart';
import '../../settings/data/gym_settings_provider.dart';

class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(paymentsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')),
      body: paymentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Gagal memuat data: $err')),
        data: (payments) {
          if (payments.isEmpty) {
            return const Center(child: Text('Belum ada riwayat pembayaran.'));
          }
          return ListView.separated(
            itemCount: payments.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final p = payments[index];
              return ListTile(
                title: Text(p.memberName),
                subtitle: Text(
                  '${p.packageName} · ${p.billingType.label} · ${p.method.label}\n${p.invoiceNumber}',
                ),
                isThreeLine: true,
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(formatRupiah(p.amount), style: const TextStyle(fontWeight: FontWeight.w600)),
                    TextButton.icon(
                      onPressed: () => _viewInvoice(ref, p),
                      icon: const Icon(Icons.picture_as_pdf, size: 16),
                      label: const Text('Invoice'),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/payments/new'),
        icon: const Icon(Icons.add),
        label: const Text('Catat Pembayaran'),
      ),
    );
  }

  void _viewInvoice(WidgetRef ref, Payment payment) {
    final settings = ref.read(gymSettingsStreamProvider).valueOrNull;
    Printing.layoutPdf(onLayout: (format) => buildInvoicePdf(payment, gymSettings: settings));
  }
}
