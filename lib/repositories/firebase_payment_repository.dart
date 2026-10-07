import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_management_system/core/constants/firestore_schema.dart';
import 'package:gym_management_system/models/payment.dart';
import 'package:gym_management_system/repositories/payment_repository.dart';

class FirebasePaymentRepository implements PaymentRepository {
  CollectionReference get _col =>
      FirebaseFirestore.instance.collection(FirestoreSchema.payments);

  @override
  Future<List<Payment>> fetchAll() async {
    final snapshot = await _col.orderBy('createdAt', descending: true).get();
    return [
      for (final doc in snapshot.docs)
        Payment.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id}),
    ];
  }

  @override
  Future<Payment> create(Payment payment) async {
    final doc = _col.doc();
    final created = payment.copyWith(id: doc.id);
    await doc.set(created.toJson());
    return created;
  }

  @override
  Future<void> update(Payment payment) async {
    await _col.doc(payment.id).set(payment.toJson());
  }

  @override
  Future<void> refund(String id) async {
    await _col.doc(id).update({'status': PaymentStatus.refunded.key});
  }

  @override
  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}