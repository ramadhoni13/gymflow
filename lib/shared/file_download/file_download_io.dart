import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';

/// Di Android, "download langsung tanpa dialog apapun" ke folder Downloads
/// publik butuh izin storage & API khusus per versi Android (kompleks dan
/// riskan salah izin). Cara paling umum & aman dipakai app Flutter adalah
/// lewat share sheet bawaan OS, yang SUDAH termasuk opsi "Simpan ke
/// File/Downloads" sebagai salah satu pilihannya — jadi tetap bisa
/// tersimpan ke perangkat, cuma lewat 1 langkah tambahan pilih tujuan.
Future<void> downloadReportFile({
  required List<int> bytes,
  required String filename,
  required String mimeType,
}) async {
  await Share.shareXFiles([
    XFile.fromData(Uint8List.fromList(bytes), name: filename, mimeType: mimeType),
  ]);
}
