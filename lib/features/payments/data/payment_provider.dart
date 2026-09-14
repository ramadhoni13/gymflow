import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../members/data/member_provider.dart';
import '../../members/domain/member.dart';
import '../domain/payment.dart';
import 'payment_repository.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) => PaymentRepository());

final paymentsStreamProvider = StreamProvider<List<Payment>>((ref) {
  return ref.watch(paymentRepositoryProvider).watchPayments();
});

/// Pencarian member khusus form pembayaran (terpisah dari modul lain
/// supaya state pencarian tidak saling tercampur antar fitur).
final paymentMemberSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final paymentMemberSearchResultsProvider = FutureProvider.autoDispose<List<Member>>((ref) async {
  final query = ref.watch(paymentMemberSearchQueryProvider);
  if (query.trim().isEmpty) return [];
  final repo = ref.watch(memberRepositoryProvider);
  return repo.fetchMembers(searchQuery: query.trim());
});

class PaymentFormController extends StateNotifier<AsyncValue<Payment?>> {
  PaymentFormController(this._repository) : super(const AsyncValue.data(null));

  final PaymentRepository _repository;

  Future<Payment?> submit({
    required Member member,
    required String packageId,
    required String packageName,
    required BillingType billingType,
    required double amount,
    required PaymentMethod method,
    required DateTime paymentDate,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      final payment = await _repository.recordPayment(
        member: member,
        packageId: packageId,
        packageName: packageName,
        billingType: billingType,
        amount: amount,
        method: method,
        paymentDate: paymentDate,
        notes: notes,
      );
      state = AsyncValue.data(payment);
      return payment;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final paymentFormControllerProvider =
    StateNotifierProvider.autoDispose<PaymentFormController, AsyncValue<Payment?>>(
  (ref) => PaymentFormController(ref.watch(paymentRepositoryProvider)),
);
