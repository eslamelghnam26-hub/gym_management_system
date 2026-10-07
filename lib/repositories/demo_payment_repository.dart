import 'dart:convert';

import 'package:gym_management_system/core/errors/app_exception.dart';
import 'package:gym_management_system/models/payment.dart';
import 'package:gym_management_system/repositories/payment_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DemoPaymentRepository implements PaymentRepository {
  DemoPaymentRepository(this._prefs);

  final SharedPreferences _prefs;
  static const String _key = 'demo_payments';

  List<Payment> _load() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      final seeded = _seed();
      _save(seeded);
      return seeded;
    }
    final list = jsonDecode(raw) as List<dynamic>;
    return [for (final item in list) Payment.fromJson(item as Map<String, dynamic>)];
  }

  void _save(List<Payment> list) {
    _prefs.setString(_key, jsonEncode([for (final p in list) p.toJson()]));
  }

  List<Payment> _seed() => [
        Payment(
          id: 'p_1',
          memberId: 'm_1',
          subscriptionId: 'sub_1',
          amount: 900,
          method: PaymentMethod.cash,
          status: PaymentStatus.paid,
          reference: 'DEMO-10001',
          note: 'كاش — استقبال',
        ),
        Payment(
          id: 'p_2',
          memberId: 'm_2',
          subscriptionId: 'sub_2',
          amount: 2400,
          method: PaymentMethod.card,
          status: PaymentStatus.paid,
          reference: 'DEMO-10002',
          note: 'فيزا •••• 4242',
        ),
        Payment(
          id: 'p_3',
          memberId: 'm_3',
          subscriptionId: 'sub_3',
          amount: 8400,
          method: PaymentMethod.bankTransfer,
          status: PaymentStatus.paid,
          reference: 'DEMO-10003',
          note: 'تحويل بنكي',
        ),
        Payment(
          id: 'p_4',
          memberId: 'm_4',
          subscriptionId: 'sub_4',
          amount: 900,
          method: PaymentMethod.wallet,
          status: PaymentStatus.pending,
          reference: 'DEMO-10004',
          note: 'محفظة 01011112223',
        ),
        Payment(
          id: 'p_5',
          memberId: 'm_6',
          subscriptionId: 'sub_6',
          amount: 900,
          method: PaymentMethod.cash,
          status: PaymentStatus.paid,
          reference: 'DEMO-10005',
          note: 'كاش',
        ),
      ];

  @override
  Future<List<Payment>> fetchAll() async {
    final list = _load();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<Payment> create(Payment payment) async {
    final id = 'p_${DateTime.now().microsecondsSinceEpoch}';
    final created = payment.copyWith(id: id);
    final list = _load();
    list.add(created);
    _save(list);
    return created;
  }

  @override
  Future<void> update(Payment payment) async {
    final list = _load();
    final index = list.indexWhere((p) => p.id == payment.id);
    if (index == -1) {
      throw const DataException(code: 'not_found');
    }
    list[index] = payment;
    _save(list);
  }

  @override
  Future<void> refund(String id) async {
    final list = _load();
    final index = list.indexWhere((p) => p.id == id);
    if (index == -1) return;
    list[index] = list[index].copyWith(status: PaymentStatus.refunded);
    _save(list);
  }

  @override
  Future<void> delete(String id) async {
    _save(_load().where((p) => p.id != id).toList());
  }
}