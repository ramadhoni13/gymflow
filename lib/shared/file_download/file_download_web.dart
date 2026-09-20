import 'dart:html' as html;
import 'dart:typed_data';

/// Di Web, ini men-trigger download file langsung lewat browser (link
/// <a download>), PERSIS seperti klik link download biasa — bukan dialog
/// share/print.
Future<void> downloadReportFile({
  required List<int> bytes,
  required String filename,
  required String mimeType,
}) async {
  final blob = html.Blob([Uint8List.fromList(bytes)], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}
