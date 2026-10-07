import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_management_system/core/constants/firestore_schema.dart';
import 'package:gym_management_system/models/announcement.dart';
import 'package:gym_management_system/repositories/announcement_repository.dart';

class FirebaseAnnouncementRepository implements AnnouncementRepository {
  CollectionReference get _col =>
      FirebaseFirestore.instance.collection(FirestoreSchema.announcements);

  @override
  Future<List<Announcement>> fetchAll() async {
    final snapshot = await _col.orderBy('createdAt', descending: true).get();
    return [
      for (final doc in snapshot.docs)
        Announcement.fromJson(
            {...doc.data() as Map<String, dynamic>, 'id': doc.id}),
    ];
  }

  @override
  Future<Announcement> create(Announcement announcement) async {
    final doc = _col.doc();
    final created = announcement.copyWith(id: doc.id);
    await doc.set(created.toJson());
    return created;
  }

  @override
  Future<void> update(Announcement announcement) async {
    await _col.doc(announcement.id).set(announcement.toJson());
  }

  @override
  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}