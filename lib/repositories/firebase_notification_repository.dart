import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_management_system/core/constants/firestore_schema.dart';
import 'package:gym_management_system/models/gym_notification.dart';
import 'package:gym_management_system/repositories/notification_repository.dart';

class FirebaseNotificationRepository implements NotificationRepository {
  CollectionReference get _col =>
      FirebaseFirestore.instance.collection(FirestoreSchema.notifications);

  @override
  Future<List<GymNotification>> fetchAll() async {
    final snapshot = await _col.orderBy('createdAt', descending: true).get();
    return [
      for (final doc in snapshot.docs)
        GymNotification.fromJson(
            {...doc.data() as Map<String, dynamic>, 'id': doc.id}),
    ];
  }

  @override
  Future<GymNotification> add(GymNotification notification) async {
    final doc = _col.doc();
    final created = notification.copyWith(id: doc.id);
    await doc.set(created.toJson());
    return created;
  }

  @override
  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}