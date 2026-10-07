import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_management_system/core/constants/firestore_schema.dart';
import 'package:gym_management_system/models/member.dart';
import 'package:gym_management_system/repositories/member_repository.dart';

class FirebaseMemberRepository implements MemberRepository {
  CollectionReference get _col =>
      FirebaseFirestore.instance.collection(FirestoreSchema.members);

  @override
  Future<List<Member>> fetchAll() async {
    final snapshot = await _col.orderBy('createdAt', descending: true).get();
    return [
      for (final doc in snapshot.docs)
        Member.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id}),
    ];
  }

  @override
  Future<Member> create(Member member) async {
    final doc = _col.doc();
    final created = member.copyWith(id: doc.id);
    await doc.set(created.toJson());
    return created;
  }

  @override
  Future<void> update(Member member) async {
    await _col.doc(member.id).set(member.toJson());
  }

  @override
  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}