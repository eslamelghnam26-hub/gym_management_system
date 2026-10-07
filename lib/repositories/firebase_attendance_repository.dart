import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_management_system/core/constants/firestore_schema.dart';
import 'package:gym_management_system/models/attendance_record.dart';
import 'package:gym_management_system/repositories/attendance_repository.dart';

class FirebaseAttendanceRepository implements AttendanceRepository {
  CollectionReference get _col =>
      FirebaseFirestore.instance.collection(FirestoreSchema.attendance);

  @override
  Future<List<AttendanceRecord>> fetchOnDate(DateTime date) async {
    final key = AttendanceRecord.dayKey(date);
    final snapshot =
        await _col.where('date', isEqualTo: key).orderBy('checkIn').get();
    return [
      for (final doc in snapshot.docs)
        AttendanceRecord.fromJson(
            {...doc.data() as Map<String, dynamic>, 'id': doc.id}),
    ];
  }

  @override
  Future<AttendanceRecord> checkIn(String memberId) async {
    final now = DateTime.now();
    final key = AttendanceRecord.dayKey(now);
    final existing = await _col
        .where('memberId', isEqualTo: memberId)
        .where('date', isEqualTo: key)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      return AttendanceRecord.fromJson({
        ...existing.docs.first.data() as Map<String, dynamic>,
        'id': existing.docs.first.id,
      });
    }
    final doc = _col.doc();
    final record = AttendanceRecord(
      id: doc.id,
      memberId: memberId,
      date: now,
      checkIn: now,
    );
    await doc.set(record.toJson());
    return record;
  }

  @override
  Future<void> checkOut(String recordId) async {
    await _col.doc(recordId).update({'checkOut': DateTime.now().toIso8601String()});
  }

  @override
  Future<List<AttendanceRecord>> fetchByMember(String memberId) async {
    final snapshot = await _col
        .where('memberId', isEqualTo: memberId)
        .orderBy('date', descending: true)
        .get();
    return [
      for (final doc in snapshot.docs)
        AttendanceRecord.fromJson(
            {...doc.data() as Map<String, dynamic>, 'id': doc.id}),
    ];
  }
}