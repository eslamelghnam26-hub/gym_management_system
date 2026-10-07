import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_management_system/core/constants/firestore_schema.dart';
import 'package:gym_management_system/models/membership_plan.dart';
import 'package:gym_management_system/repositories/membership_plan_repository.dart';

class FirebaseMembershipPlanRepository implements MembershipPlanRepository {
  CollectionReference get _col => FirebaseFirestore.instance
      .collection(FirestoreSchema.membershipPlans);

  @override
  Future<List<MembershipPlan>> fetchAll() async {
    final snapshot = await _col.orderBy('createdAt', descending: true).get();
    return [
      for (final doc in snapshot.docs)
        MembershipPlan.fromJson(
            {...doc.data() as Map<String, dynamic>, 'id': doc.id}),
    ];
  }

  @override
  Future<MembershipPlan> create(MembershipPlan plan) async {
    final doc = _col.doc();
    final created = plan.copyWith(id: doc.id);
    await doc.set(created.toJson());
    return created;
  }

  @override
  Future<void> update(MembershipPlan plan) async {
    await _col.doc(plan.id).set(plan.toJson());
  }

  @override
  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}