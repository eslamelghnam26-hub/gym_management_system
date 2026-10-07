import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management_system/core/config/app_config.dart';
import 'package:gym_management_system/models/payment.dart';
import 'package:gym_management_system/providers/shared_prefs_provider.dart';
import 'package:gym_management_system/repositories/demo_payment_repository.dart';
import 'package:gym_management_system/repositories/firebase_payment_repository.dart';
import 'package:gym_management_system/repositories/payment_repository.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  if (AppConfig.isFirebase) return FirebasePaymentRepository();
  return DemoPaymentRepository(ref.read(sharedPreferencesProvider));
});

class PaymentsController extends AsyncNotifier<List<Payment>> {
  PaymentRepository get _repo => ref.read(paymentRepositoryProvider);

  @override
  Future<List<Payment>> build() => _repo.fetchAll();

  Future<void> _reload() async {
    try {
      state = AsyncData(await _repo.fetchAll());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> add(Payment payment) async {
    await _repo.create(payment);
    await _reload();
  }

  Future<void> save(Payment payment) async {
    await _repo.update(payment);
    await _reload();
  }

  Future<void> refund(String id) async {
    await _repo.refund(id);
    await _reload();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    await _reload();
  }

  List<Payment> forMember(String memberId) {
    final list = state.value ?? const <Payment>[];
    return list.where((p) => p.memberId == memberId).toList();
  }
}

final paymentsControllerProvider =
    AsyncNotifierProvider<PaymentsController, List<Payment>>(PaymentsController.new);