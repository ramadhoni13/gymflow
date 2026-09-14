import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/date_utils.dart';
import '../../members/data/member_repository.dart';
import '../../members/domain/member.dart';
import '../domain/payment.dart';

class PaymentRepository {
  final SupabaseClient _client = SupabaseService.client;
  final MemberRepository _memberRepository;
  static const _table = 'payments';

  PaymentRepository({MemberRepository? memberRepository})
      : _memberRepository = memberRepository ?? MemberRepository();

  Stream<List<Payment>> watchPayments() {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('payment_date', ascending: false)
        .map((rows) => rows.map(Payment.fromMap).toList());
  }

  String _generateInvoiceNumber(DateTime date) {
    final datePart =
        '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
    final timePart =
        '${date.hour.toString().padLeft(2, '0')}${date.minute.toString().padLeft(2, '0')}${date.second.toString().padLeft(2, '0')}';
    return 'INV-$datePart-$timePart';
  }

  /// Mencatat pembayaran baru DAN otomatis memperpanjang membership_end_date
  /// member yang bersangkutan. Kalau membership member masih aktif, durasi
  /// baru ditambahkan dari tanggal berakhir saat ini (bukan dari hari ini) —
  /// supaya member yang bayar lebih awal tidak dirugikan.
  Future<Payment> recordPayment({
    required Member member,
    required String packageId,
    required String packageName,
    required BillingType billingType,
    required double amount,
    required PaymentMethod method,
    required DateTime paymentDate,
    String? notes,
  }) async {
    final baseDate =
        member.membershipEndDate.isAfter(paymentDate) ? member.membershipEndDate : paymentDate;
    final newEndDate = billingType == BillingType.monthly
        ? addMonths(baseDate, 1)
        : addMonths(baseDate, 12);

    // 1. Perpanjang membership member dulu.
    await _memberRepository.extendMembership(memberId: member.id, newEndDate: newEndDate);

    // 2. Baru catat riwayat pembayarannya.
    final payment = Payment(
      id: '',
      invoiceNumber: _generateInvoiceNumber(paymentDate),
      memberId: member.id,
      memberName: member.name,
      packageId: packageId,
      packageName: packageName,
      billingType: billingType,
      amount: amount,
      method: method,
      paymentDate: paymentDate,
      membershipEndDateAfter: newEndDate,
      notes: notes,
    );

    final data = await _client.from(_table).insert(payment.toMap()).select().single();
    return Payment.fromMap(data);
  }
}
