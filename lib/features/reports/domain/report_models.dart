class MonthlyRevenue {
  final String monthLabel;
  final double total;
  const MonthlyRevenue({required this.monthLabel, required this.total});

  factory MonthlyRevenue.fromMap(Map<String, dynamic> map) {
    return MonthlyRevenue(
      monthLabel: map['month_label'] as String,
      total: (map['total'] as num).toDouble(),
    );
  }
}

class MethodRevenue {
  final String method; // 'cash' | 'bankTransfer' | 'qris' (raw dari DB)
  final double total;
  const MethodRevenue({required this.method, required this.total});

  String get label {
    switch (method) {
      case 'cash':
        return 'Tunai';
      case 'bankTransfer':
        return 'Transfer Bank';
      case 'qris':
        return 'QRIS';
      default:
        return method;
    }
  }

  factory MethodRevenue.fromMap(Map<String, dynamic> map) {
    return MethodRevenue(
      method: map['method'] as String,
      total: (map['total'] as num).toDouble(),
    );
  }
}

class PackageRevenue {
  final String packageName;
  final double total;
  const PackageRevenue({required this.packageName, required this.total});

  factory PackageRevenue.fromMap(Map<String, dynamic> map) {
    return PackageRevenue(
      packageName: map['package_name'] as String,
      total: (map['total'] as num).toDouble(),
    );
  }
}

class MemberStatusCount {
  final String status; // 'active' | 'expiring_soon' | 'expired'
  final int count;
  const MemberStatusCount({required this.status, required this.count});

  String get label {
    switch (status) {
      case 'active':
        return 'Aktif';
      case 'expiring_soon':
        return 'Segera Habis';
      case 'expired':
        return 'Kedaluwarsa';
      default:
        return status;
    }
  }

  factory MemberStatusCount.fromMap(Map<String, dynamic> map) {
    return MemberStatusCount(
      status: map['status'] as String,
      count: (map['member_count'] as num).toInt(),
    );
  }
}

class DailyCheckinCount {
  final DateTime day;
  final int count;
  const DailyCheckinCount({required this.day, required this.count});

  factory DailyCheckinCount.fromMap(Map<String, dynamic> map) {
    return DailyCheckinCount(
      day: DateTime.parse(map['day'] as String),
      count: (map['checkin_count'] as num).toInt(),
    );
  }
}

class PopularClass {
  final String className;
  final int bookingCount;
  const PopularClass({required this.className, required this.bookingCount});

  factory PopularClass.fromMap(Map<String, dynamic> map) {
    return PopularClass(
      className: map['class_name'] as String,
      bookingCount: (map['booking_count'] as num).toInt(),
    );
  }
}

/// Helper untuk rentang tanggal bebas (dipilih user lewat date range
/// picker) di Laporan Keuangan & Operasional.
class ReportDateRange {
  final DateTime start;
  final DateTime end;
  const ReportDateRange({required this.start, required this.end});

  int get days => end.difference(start).inDays + 1;

  /// Granularity grafik tren otomatis menyesuaikan lebar rentang yang
  /// dipilih user — supaya grafik tetap enak dibaca baik untuk rentang
  /// pendek (per hari) maupun panjang (per tahun).
  String get granularity {
    if (days <= 31) return 'day';
    if (days <= 120) return 'week';
    if (days <= 730) return 'month';
    return 'year';
  }

  String get label {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    String fmt(DateTime d) => '${d.day} ${months[d.month - 1]} ${d.year}';
    return '${fmt(start)} - ${fmt(end)}';
  }

  /// Dipakai untuk nama file saat download (mis. 2026-01-01_2026-09-20).
  String get fileTag {
    String iso(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return '${iso(start)}_${iso(end)}';
  }

  static ReportDateRange last30Days() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return ReportDateRange(start: today.subtract(const Duration(days: 29)), end: today);
  }

  static ReportDateRange today() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return ReportDateRange(start: today, end: today);
  }

  static ReportDateRange thisWeek() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return ReportDateRange(start: monday, end: today);
  }

  static ReportDateRange thisMonth() {
    final now = DateTime.now();
    return ReportDateRange(start: DateTime(now.year, now.month, 1), end: DateTime(now.year, now.month, now.day));
  }

  static ReportDateRange thisYear() {
    final now = DateTime.now();
    return ReportDateRange(start: DateTime(now.year, 1, 1), end: DateTime(now.year, now.month, now.day));
  }
}

class RevenueTrendPoint {
  final String periodLabel;
  final DateTime periodStart;
  final double total;
  const RevenueTrendPoint({required this.periodLabel, required this.periodStart, required this.total});

  factory RevenueTrendPoint.fromMap(Map<String, dynamic> map) {
    return RevenueTrendPoint(
      periodLabel: map['period_label'] as String,
      periodStart: DateTime.parse(map['period_start'] as String),
      total: (map['total'] as num).toDouble(),
    );
  }
}

class CheckinTrendPoint {
  final String periodLabel;
  final DateTime periodStart;
  final int count;
  const CheckinTrendPoint({required this.periodLabel, required this.periodStart, required this.count});

  factory CheckinTrendPoint.fromMap(Map<String, dynamic> map) {
    return CheckinTrendPoint(
      periodLabel: map['period_label'] as String,
      periodStart: DateTime.parse(map['period_start'] as String),
      count: (map['checkin_count'] as num).toInt(),
    );
  }
}
