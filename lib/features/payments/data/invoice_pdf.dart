import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../domain/payment.dart';
import '../../../shared/format_rupiah.dart';

Future<Uint8List> buildInvoicePdf(Payment payment) async {
  final doc = pw.Document();

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a5,
      build: (context) {
        return pw.Padding(
          padding: const pw.EdgeInsets.all(24),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('INVOICE', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text(payment.invoiceNumber, style: const pw.TextStyle(fontSize: 12)),
              pw.Divider(height: 24),
              _row('Tanggal', _formatDate(payment.paymentDate)),
              _row('Nama Member', payment.memberName),
              _row('Paket', payment.packageName),
              _row('Tipe Pembayaran',
                  payment.billingType == BillingType.monthly ? 'Bulanan' : 'Tahunan'),
              _row('Metode Pembayaran', payment.method.label),
              _row('Membership Berlaku s/d', _formatDate(payment.membershipEndDateAfter)),
              pw.Divider(height: 24),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL DIBAYAR', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                    formatRupiah(payment.amount),
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              if (payment.notes != null && payment.notes!.isNotEmpty) ...[
                pw.SizedBox(height: 16),
                pw.Text('Catatan: ${payment.notes}', style: const pw.TextStyle(fontSize: 10)),
              ],
              pw.SizedBox(height: 32),
              pw.Text('Terima kasih atas pembayaran Anda.', style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        );
      },
    ),
  );

  return doc.save();
}

pw.Widget _row(String label, String value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 3),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(color: PdfColors.grey700)),
        pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
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
