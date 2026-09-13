enum DiscountType { none, percentage, nominal }

extension DiscountTypeX on DiscountType {
  String get label {
    switch (this) {
      case DiscountType.none:
        return 'Tidak ada';
      case DiscountType.percentage:
        return 'Persen (%)';
      case DiscountType.nominal:
        return 'Nominal (Rp)';
    }
  }

  static DiscountType fromString(String? value) {
    switch (value) {
      case 'percentage':
        return DiscountType.percentage;
      case 'nominal':
        return DiscountType.nominal;
      default:
        return DiscountType.none;
    }
  }

  String? toDbValue() {
    switch (this) {
      case DiscountType.percentage:
        return 'percentage';
      case DiscountType.nominal:
        return 'nominal';
      case DiscountType.none:
        return null;
    }
  }
}

double _applyDiscount(double base, DiscountType type, double? value) {
  switch (type) {
    case DiscountType.percentage:
      final pct = value ?? 0;
      return base - (base * pct / 100);
    case DiscountType.nominal:
      final nominal = value ?? 0;
      return (base - nominal).clamp(0, base);
    case DiscountType.none:
      return base;
  }
}

class MembershipPackage {
  final String id;
  final String name;
  final double monthlyPrice;
  final String? bonus;

  /// Diskon reguler — berlaku baik untuk harga bulanan maupun sebagai dasar
  /// perhitungan harga tahunan (diterapkan dulu sebelum dikali 12).
  final DiscountType discountType;
  final double? discountValue;

  /// Diskon tambahan yang HANYA berlaku kalau member bayar langsung 1 tahun
  /// di muka, di atas diskon reguler yang sudah diterapkan ke harga bulanan.
  final DiscountType annualDiscountType;
  final double? annualDiscountValue;

  final String? description;

  const MembershipPackage({
    required this.id,
    required this.name,
    required this.monthlyPrice,
    this.bonus,
    this.discountType = DiscountType.none,
    this.discountValue,
    this.annualDiscountType = DiscountType.none,
    this.annualDiscountValue,
    this.description,
  });

  bool get hasDiscount => discountType != DiscountType.none && (discountValue ?? 0) > 0;
  bool get hasAnnualDiscount =>
      annualDiscountType != DiscountType.none && (annualDiscountValue ?? 0) > 0;

  /// Harga bulanan setelah diskon reguler.
  double get monthlyFinalPrice => _applyDiscount(monthlyPrice, discountType, discountValue);

  /// Dasar harga tahunan: harga bulanan (sudah kena diskon reguler) × 12,
  /// SEBELUM diskon tambahan tahunan.
  double get annualBasePrice => monthlyFinalPrice * 12;

  /// Harga tahunan final setelah diskon tambahan tahunan diterapkan
  /// di atas annualBasePrice.
  double get annualFinalPrice =>
      _applyDiscount(annualBasePrice, annualDiscountType, annualDiscountValue);

  /// Total hemat dibanding bayar bulanan 12× tanpa diskon sama sekali —
  /// berguna untuk badge "Hemat Rp xxx" di UI.
  double get annualSavingsVsFullMonthly => (monthlyPrice * 12) - annualFinalPrice;

  factory MembershipPackage.fromMap(Map<String, dynamic> map) {
    return MembershipPackage(
      id: map['id'] as String,
      name: map['name'] as String,
      monthlyPrice: (map['monthly_price'] as num).toDouble(),
      bonus: map['bonus'] as String?,
      discountType: DiscountTypeX.fromString(map['discount_type'] as String?),
      discountValue: (map['discount_value'] as num?)?.toDouble(),
      annualDiscountType: DiscountTypeX.fromString(map['annual_discount_type'] as String?),
      annualDiscountValue: (map['annual_discount_value'] as num?)?.toDouble(),
      description: map['description'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'monthly_price': monthlyPrice,
      'bonus': bonus,
      'discount_type': discountType.toDbValue(),
      'discount_value': discountType == DiscountType.none ? null : discountValue,
      'annual_discount_type': annualDiscountType.toDbValue(),
      'annual_discount_value': annualDiscountType == DiscountType.none ? null : annualDiscountValue,
      'description': description,
    };
  }
}
