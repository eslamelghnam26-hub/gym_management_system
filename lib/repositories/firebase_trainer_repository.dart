import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_management_system/core/constants/firestore_schema.dart';
import 'package:gym_management_system/models/trainer.dart';
import 'package:gym_management_system/repositories/trainer_repository.dart';

class FirebaseTrainerRepository implements TrainerRepository {
  CollectionReference get _col =>
      FirebaseFirestore.instance.collection(FirestoreSchema.trainers);

  @override
  Future<List<Trainer>> fetchAll() async {
    final snapshot = await _col.orderBy('createdAt', descending: true).get();
    return [
      for (final doc in snapshot.docs)
        Trainer.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id}),
    ];
  }

  @override
  Future<Trainer> create(Trainer trainer) async {
    final doc = _col.doc();
    final created = trainer.copyWith(id: doc.id);
    await doc.set(created.toJson());
    return created;
  }

  @override
  Future<void> update(Trainer trainer) async {
    await _col.doc(trainer.id).set(trainer.toJson());
  }

  @override
  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}