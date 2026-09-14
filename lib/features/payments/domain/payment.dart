enum PaymentMethod { cash, bankTransfer, qris }

extension PaymentMethodX on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Tunai';
      case PaymentMethod.bankTransfer:
        return 'Transfer Bank';
      case PaymentMethod.qris:
        return 'QRIS';
    }
  }

  String toDbValue() => name;

  static PaymentMethod fromString(String value) {
    return PaymentMethod.values.firstWhere((m) => m.name == value);
  }
}

enum BillingType { monthly, annual }

extension BillingTypeX on BillingType {
  String get label => this == BillingType.monthly ? 'Bulanan' : 'Tahunan';
  String toDbValue() => name;

  static BillingType fromString(String value) {
    return value == 'annual' ? BillingType.annual : BillingType.monthly;
  }
}

class Payment {
  final String id;
  final String invoiceNumber;
  final String memberId;
  final String memberName;
  final String packageId;
  final String packageName;
  final BillingType billingType;
  final double amount;
  final PaymentMethod method;
  final DateTime paymentDate;
  final DateTime membershipEndDateAfter;
  final String? notes;

  const Payment({
    required this.id,
    required this.invoiceNumber,
    required this.memberId,
    required this.memberName,
    required this.packageId,
    required this.packageName,
    required this.billingType,
    required this.amount,
    required this.method,
    required this.paymentDate,
    required this.membershipEndDateAfter,
    this.notes,
  });

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as String,
      invoiceNumber: map['invoice_number'] as String,
      memberId: map['member_id'] as String,
      memberName: map['member_name'] as String,
      packageId: map['package_id'] as String,
      packageName: map['package_name'] as String,
      billingType: BillingTypeX.fromString(map['billing_type'] as String),
      amount: (map['amount'] as num).toDouble(),
      method: PaymentMethodX.fromString(map['method'] as String),
      paymentDate: DateTime.parse(map['payment_date'] as String),
      membershipEndDateAfter: DateTime.parse(map['membership_end_date_after'] as String),
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'invoice_number': invoiceNumber,
      'member_id': memberId,
      'member_name': memberName,
      'package_id': packageId,
      'package_name': packageName,
      'billing_type': billingType.toDbValue(),
      'amount': amount,
      'method': method.toDbValue(),
      'payment_date': paymentDate.toIso8601String(),
      'membership_end_date_after': membershipEndDateAfter.toIso8601String(),
      'notes': notes,
    };
  }
}
