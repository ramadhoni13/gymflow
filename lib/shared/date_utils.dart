/// Menambahkan sejumlah bulan ke [date], dengan tanggal otomatis disesuaikan
/// (clamp) kalau bulan tujuan tidak punya tanggal sebanyak itu.
/// Contoh: 31 Jan + 1 bulan = 28 Feb (atau 29 Feb kalau kabisat).
DateTime addMonths(DateTime date, int months) {
  final totalMonths = date.month - 1 + months;
  final year = date.year + totalMonths ~/ 12;
  final month = totalMonths % 12 + 1;
  final lastDayOfTargetMonth = DateTime(year, month + 1, 0).day;
  final day = date.day > lastDayOfTargetMonth ? lastDayOfTargetMonth : date.day;
  return DateTime(year, month, day);
}
