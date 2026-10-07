import 'package:gym_management_system/models/payment.dart';

abstract class PaymentRepository {
  Future<List<Payment>> fetchAll();
  Future<Payment> create(Payment payment);
  Future<void> update(Payment payment);
  Future<void> refund(String id);
  Future<void> delete(String id);
}