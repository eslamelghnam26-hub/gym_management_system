import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_management_system/core/constants/firestore_schema.dart';
import 'package:gym_management_system/models/app_user.dart';
import 'package:gym_management_system/repositories/user_repository.dart';

class FirebaseUserRepository implements UserRepository {
  CollectionReference get _col =>
      FirebaseFirestore.instance.collection(FirestoreSchema.users);

  @override
  Future<List<AppUser>> fetchAll() async {
    final snapshot = await _col.orderBy('createdAt', descending: true).get();
    return [
      for (final doc in snapshot.docs)
        AppUser.fromJson({...doc.data() as Map<String, dynamic>, 'uid': doc.id}),
    ];
  }

  @override
  Future<void> update(AppUser user) async {
    await _col.doc(user.uid).set(user.toJson(), SetOptions(merge: true));
  }

  @override
  Future<void> delete(String uid) async {
    await _col.doc(uid).delete();
  }
}