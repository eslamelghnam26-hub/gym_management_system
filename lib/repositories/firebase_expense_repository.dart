import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_management_system/core/constants/firestore_schema.dart';
import 'package:gym_management_system/models/expense.dart';
import 'package:gym_management_system/repositories/expense_repository.dart';

class FirebaseExpenseRepository implements ExpenseRepository {
  CollectionReference get _col =>
      FirebaseFirestore.instance.collection(FirestoreSchema.expenses);

  @override
  Future<List<Expense>> fetchAll() async {
    final snapshot = await _col.orderBy('date', descending: true).get();
    return [
      for (final doc in snapshot.docs)
        Expense.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id}),
    ];
  }

  @override
  Future<Expense> create(Expense expense) async {
    final doc = _col.doc();
    final created = expense.copyWith(id: doc.id);
    await doc.set(created.toJson());
    return created;
  }

  @override
  Future<void> update(Expense expense) async {
    await _col.doc(expense.id).set(expense.toJson());
  }

  @override
  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}