import 'dart:convert';

import 'package:gym_management_system/core/errors/app_exception.dart';
import 'package:gym_management_system/models/expense.dart';
import 'package:gym_management_system/repositories/expense_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DemoExpenseRepository implements ExpenseRepository {
  DemoExpenseRepository(this._prefs);

  final SharedPreferences _prefs;
  static const String _key = 'demo_expenses';

  List<Expense> _load() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      final seeded = _seed();
      _save(seeded);
      return seeded;
    }
    final list = jsonDecode(raw) as List<dynamic>;
    return [for (final item in list) Expense.fromJson(item as Map<String, dynamic>)];
  }

  void _save(List<Expense> list) {
    _prefs.setString(_key, jsonEncode([for (final e in list) e.toJson()]));
  }

  List<Expense> _seed() {
    final now = DateTime.now();
    return [
      Expense(
        id: 'e_1',
        category: ExpenseCategory.salary,
        amount: 16500,
        date: now.subtract(const Duration(days: 1)),
        note: 'رواتب المدربين والاستقبال',
      ),
      Expense(
        id: 'e_2',
        category: ExpenseCategory.rent,
        amount: 8000,
        date: now.subtract(const Duration(days: 5)),
        note: 'إيجار الشهر',
      ),
      Expense(
        id: 'e_3',
        category: ExpenseCategory.utilities,
        amount: 1250,
        date: now.subtract(const Duration(days: 2)),
        note: 'كهرباء ومياه',
      ),
      Expense(
        id: 'e_4',
        category: ExpenseCategory.equipment,
        amount: 3500,
        date: now.subtract(const Duration(days: 12)),
        note: 'صيانة أجهزة',
      ),
    ];
  }

  @override
  Future<List<Expense>> fetchAll() async {
    final list = _load();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Future<Expense> create(Expense expense) async {
    final id = 'e_${DateTime.now().microsecondsSinceEpoch}';
    final created = expense.copyWith(id: id);
    final list = _load();
    list.add(created);
    _save(list);
    return created;
  }

  @override
  Future<void> update(Expense expense) async {
    final list = _load();
    final index = list.indexWhere((e) => e.id == expense.id);
    if (index == -1) throw const DataException(code: 'not_found');
    list[index] = expense;
    _save(list);
  }

  @override
  Future<void> delete(String id) async {
    _save(_load().where((e) => e.id != id).toList());
  }
}