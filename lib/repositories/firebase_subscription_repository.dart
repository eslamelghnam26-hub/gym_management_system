import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_management_system/core/constants/firestore_schema.dart';
import 'package:gym_management_system/models/subscription.dart';
import 'package:gym_management_system/repositories/subscription_repository.dart';

class FirebaseSubscriptionRepository implements SubscriptionRepository {
  CollectionReference get _col =>
      FirebaseFirestore.instance.collection(FirestoreSchema.subscriptions);

  @override
  Future<List<Subscription>> fetchAll() async {
    final snapshot = await _col.orderBy('createdAt', descending: true).get();
    return [
      for (final doc in snapshot.docs)
        Subscription.fromJson(
            {...doc.data() as Map<String, dynamic>, 'id': doc.id}),
    ];
  }

  @override
  Future<Subscription> create(Subscription subscription) async {
    final doc = _col.doc();
    final created = subscription.copyWith(id: doc.id);
    await doc.set(created.toJson());
    return created;
  }

  @override
  Future<void> update(Subscription subscription) async {
    await _col.doc(subscription.id).set(subscription.toJson());
  }

  @override
  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}