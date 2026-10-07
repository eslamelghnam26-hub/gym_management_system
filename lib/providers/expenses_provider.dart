import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management_system/core/config/app_config.dart';
import 'package:gym_management_system/models/expense.dart';
import 'package:gym_management_system/providers/shared_prefs_provider.dart';
import 'package:gym_management_system/repositories/demo_expense_repository.dart';
import 'package:gym_management_system/repositories/expense_repository.dart';
import 'package:gym_management_system/repositories/firebase_expense_repository.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  if (AppConfig.isFirebase) return FirebaseExpenseRepository();
  return DemoExpenseRepository(ref.read(sharedPreferencesProvider));
});

class ExpensesController extends AsyncNotifier<List<Expense>> {
  ExpenseRepository get _repo => ref.read(expenseRepositoryProvider);

  @override
  Future<List<Expense>> build() => _repo.fetchAll();

  Future<void> _reload() async {
    try {
      state = AsyncData(await _repo.fetchAll());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> add(Expense expense) async {
    await _repo.create(expense);
    await _reload();
  }

  Future<void> save(Expense expense) async {
    await _repo.update(expense);
    await _reload();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    await _reload();
  }
}

final expensesControllerProvider =
    AsyncNotifierProvider<ExpensesController, List<Expense>>(ExpensesController.new);