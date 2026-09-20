import 'dart:typed_data';
import 'package:excel/excel.dart' as xls;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../domain/report_models.dart';
import '../../../shared/format_rupiah.dart';

String _formatDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

// ===================== LAPORAN KEUANGAN =====================

Uint8List buildFinancialReportExcel({
  required ReportDateRange range,
  required String? gymName,
  required List<RevenueTrendPoint> trend,
  required List<MethodRevenue> byMethod,
  required List<PackageRevenue> byPackage,
}) {
  final book = xls.Excel.createExcel();
  final sheet = book['Laporan Keuangan'];
  book.setDefaultSheet('Laporan Keuangan');

  int row = 0;
  void writeTitle(String text) {
    sheet.cell(xls.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
      ..value = xls.TextCellValue(text)
      ..cellStyle = xls.CellStyle(bold: true, fontSize: 13);
    row += 1;
  }

  void writeHeaderRow(List<String> headers) {
    for (int c = 0; c < headers.length; c++) {
      sheet.cell(xls.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row))
        ..value = xls.TextCellValue(headers[c])
        ..cellStyle = xls.CellStyle(bold: true);
    }
    row += 1;
  }

  void writeRow(List<Object> values) {
    for (int c = 0; c < values.length; c++) {
      final v = values[c];
      sheet.cell(xls.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row)).value =
          v is num ? xls.DoubleCellValue(v.toDouble()) : xls.TextCellValue(v.toString());
    }
    row += 1;
  }

  writeTitle('${gymName?.isNotEmpty == true ? gymName : 'Laporan'} — Laporan Keuangan');
  writeRow(['Periode', range.label]);
  writeRow(['Dicetak', _formatDate(DateTime.now())]);
  row += 1;

  writeTitle('Tren Pendapatan');
  writeHeaderRow(['Periode', 'Total (Rp)']);
  for (final t in trend) {
    writeRow([t.periodLabel, t.total]);
  }
  final totalRevenue = trend.fold<double>(0, (s, t) => s + t.total);
  writeRow(['TOTAL', totalRevenue]);
  row += 1;

  writeTitle('Pendapatan per Metode Pembayaran');
  writeHeaderRow(['Metode', 'Total (Rp)']);
  for (final m in byMethod) {
    writeRow([m.label, m.total]);
  }
  row += 1;

  writeTitle('Pendapatan per Paket Membership');
  writeHeaderRow(['Paket', 'Total (Rp)']);
  for (final p in byPackage) {
    writeRow([p.packageName, p.total]);
  }

  final bytes = book.save();
  return Uint8List.fromList(bytes!);
}

Future<Uint8List> buildFinancialReportPdf({
  required ReportDateRange range,
  required String? gymName,
  required List<RevenueTrendPoint> trend,
  required List<MethodRevenue> byMethod,
  required List<PackageRevenue> byPackage,
}) async {
  final doc = pw.Document();
  final totalRevenue = trend.fold<double>(0, (s, t) => s + t.total);

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (context) => [
        pw.Text(gymName?.isNotEmpty == true ? gymName! : 'Laporan Keuangan',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.Text('Laporan Keuangan — Periode ${range.label}', style: const pw.TextStyle(fontSize: 12)),
        pw.Text('Dicetak: ${_formatDate(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        pw.SizedBox(height: 12),
        pw.Text('Total Pendapatan Periode Ini: ${formatRupiah(totalRevenue)}',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 16),
        pw.Text('Tren Pendapatan', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          headers: ['Periode', 'Total'],
          data: trend.map((t) => [t.periodLabel, formatRupiah(t.total)]).toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          cellStyle: const pw.TextStyle(fontSize: 9),
          cellAlignments: {1: pw.Alignment.centerRight},
        ),
        pw.SizedBox(height: 16),
        pw.Text('Pendapatan per Metode Pembayaran',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          headers: ['Metode', 'Total'],
          data: byMethod.map((m) => [m.label, formatRupiah(m.total)]).toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          cellStyle: const pw.TextStyle(fontSize: 9),
          cellAlignments: {1: pw.Alignment.centerRight},
        ),
        pw.SizedBox(height: 16),
        pw.Text('Pendapatan per Paket Membership',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          headers: ['Paket', 'Total'],
          data: byPackage.map((p) => [p.packageName, formatRupiah(p.total)]).toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          cellStyle: const pw.TextStyle(fontSize: 9),
          cellAlignments: {1: pw.Alignment.centerRight},
        ),
      ],
    ),
  );

  return doc.save();
}

// ===================== LAPORAN OPERASIONAL =====================

Uint8List buildOperationalReportExcel({
  required ReportDateRange range,
  required String? gymName,
  required List<MemberStatusCount> memberStatus,
  required List<CheckinTrendPoint> checkinTrend,
  required List<PopularClass> popularClasses,
}) {
  final book = xls.Excel.createExcel();
  final sheet = book['Laporan Operasional'];
  book.setDefaultSheet('Laporan Operasional');

  int row = 0;
  void writeTitle(String text) {
    sheet.cell(xls.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
      ..value = xls.TextCellValue(text)
      ..cellStyle = xls.CellStyle(bold: true, fontSize: 13);
    row += 1;
  }

  void writeHeaderRow(List<String> headers) {
    for (int c = 0; c < headers.length; c++) {
      sheet.cell(xls.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row))
        ..value = xls.TextCellValue(headers[c])
        ..cellStyle = xls.CellStyle(bold: true);
    }
    row += 1;
  }

  void writeRow(List<Object> values) {
    for (int c = 0; c < values.length; c++) {
      final v = values[c];
      sheet.cell(xls.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row)).value =
          v is num ? xls.DoubleCellValue(v.toDouble()) : xls.TextCellValue(v.toString());
    }
    row += 1;
  }

  writeTitle('${gymName?.isNotEmpty == true ? gymName : 'Laporan'} — Laporan Operasional');
  writeRow(['Periode', range.label]);
  writeRow(['Dicetak', _formatDate(DateTime.now())]);
  row += 1;

  writeTitle('Status Member (Snapshot Saat Ini)');
  writeHeaderRow(['Status', 'Jumlah']);
  for (final s in memberStatus) {
    writeRow([s.label, s.count]);
  }
  row += 1;

  writeTitle('Tren Check-in');
  writeHeaderRow(['Periode', 'Jumlah Check-in']);
  for (final c in checkinTrend) {
    writeRow([c.periodLabel, c.count]);
  }
  row += 1;

  writeTitle('Kelas Paling Populer');
  writeHeaderRow(['Kelas', 'Jumlah Booking']);
  for (final p in popularClasses) {
    writeRow([p.className, p.bookingCount]);
  }

  final bytes = book.save();
  return Uint8List.fromList(bytes!);
}

Future<Uint8List> buildOperationalReportPdf({
  required ReportDateRange range,
  required String? gymName,
  required List<MemberStatusCount> memberStatus,
  required List<CheckinTrendPoint> checkinTrend,
  required List<PopularClass> popularClasses,
}) async {
  final doc = pw.Document();

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (context) => [
        pw.Text(gymName?.isNotEmpty == true ? gymName! : 'Laporan Operasional',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.Text('Laporan Operasional — Periode ${range.label}', style: const pw.TextStyle(fontSize: 12)),
        pw.Text('Dicetak: ${_formatDate(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        pw.SizedBox(height: 16),
        pw.Text('Status Member (Snapshot Saat Ini)',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          headers: ['Status', 'Jumlah'],
          data: memberStatus.map((s) => [s.label, '${s.count}']).toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          cellStyle: const pw.TextStyle(fontSize: 9),
          cellAlignments: {1: pw.Alignment.centerRight},
        ),
        pw.SizedBox(height: 16),
        pw.Text('Tren Check-in', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          headers: ['Periode', 'Jumlah Check-in'],
          data: checkinTrend.map((c) => [c.periodLabel, '${c.count}']).toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          cellStyle: const pw.TextStyle(fontSize: 9),
          cellAlignments: {1: pw.Alignment.centerRight},
        ),
        pw.SizedBox(height: 16),
        pw.Text('Kelas Paling Populer', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          headers: ['Kelas', 'Jumlah Booking'],
          data: popularClasses.map((p) => [p.className, '${p.bookingCount}x']).toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          cellStyle: const pw.TextStyle(fontSize: 9),
          cellAlignments: {1: pw.Alignment.centerRight},
        ),
      ],
    ),
  );

  return doc.save();
}
