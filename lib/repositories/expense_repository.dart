import 'package:gym_management_system/models/expense.dart';

abstract class ExpenseRepository {
  Future<List<Expense>> fetchAll();
  Future<Expense> create(Expense expense);
  Future<void> update(Expense expense);
  Future<void> delete(String id);
}