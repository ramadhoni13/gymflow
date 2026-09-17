class GymSettings {
  final String gymName;
  final String? operationalHours;
  final String? address;
  final String? whatsappNumber;
  final String? operationalEmail;
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankAccountHolder;
  final String? qrisMerchantName;
  final String? notes;

  const GymSettings({
    required this.gymName,
    this.operationalHours,
    this.address,
    this.whatsappNumber,
    this.operationalEmail,
    this.bankName,
    this.bankAccountNumber,
    this.bankAccountHolder,
    this.qrisMerchantName,
    this.notes,
  });

  factory GymSettings.fromMap(Map<String, dynamic> map) {
    return GymSettings(
      gymName: map['gym_name'] as String? ?? '',
      operationalHours: map['operational_hours'] as String?,
      address: map['address'] as String?,
      whatsappNumber: map['whatsapp_number'] as String?,
      operationalEmail: map['operational_email'] as String?,
      bankName: map['bank_name'] as String?,
      bankAccountNumber: map['bank_account_number'] as String?,
      bankAccountHolder: map['bank_account_holder'] as String?,
      qrisMerchantName: map['qris_merchant_name'] as String?,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'gym_name': gymName,
      'operational_hours': operationalHours,
      'address': address,
      'whatsapp_number': whatsappNumber,
      'operational_email': operationalEmail,
      'bank_name': bankName,
      'bank_account_number': bankAccountNumber,
      'bank_account_holder': bankAccountHolder,
      'qris_merchant_name': qrisMerchantName,
      'notes': notes,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
