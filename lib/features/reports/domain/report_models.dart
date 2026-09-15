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
