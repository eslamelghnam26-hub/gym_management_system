import 'dart:convert';

import 'package:gym_management_system/core/errors/app_exception.dart';
import 'package:gym_management_system/models/trainer.dart';
import 'package:gym_management_system/repositories/trainer_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DemoTrainerRepository implements TrainerRepository {
  DemoTrainerRepository(this._prefs);

  final SharedPreferences _prefs;
  static const String _key = 'demo_trainers';

  List<Trainer> _load() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      final seeded = _seed();
      _save(seeded);
      return seeded;
    }
    final list = jsonDecode(raw) as List<dynamic>;
    return [
      for (final item in list)
        Trainer.fromJson(item as Map<String, dynamic>),
    ];
  }

  void _save(List<Trainer> trainers) {
    _prefs.setString(_key, jsonEncode([for (final t in trainers) t.toJson()]));
  }

  List<Trainer> _seed() => [
        Trainer(
          id: 't_1',
          name: 'أحمد حسن',
          phone: '01011122233',
          email: 'ahmed@gym.com',
          specialization: 'قوة وبناء أجسام',
          salary: 6000,
          schedule: 'كل يوم 10 ص - 6 م',
        ),
        Trainer(
          id: 't_2',
          name: 'سارة علي',
          phone: '01022233344',
          email: 'sara@gym.com',
          specialization: 'كارديو ولياقة',
          salary: 5000,
          schedule: 'سبت - أربعاء 12 ظ - 9 م',
        ),
        Trainer(
          id: 't_3',
          name: 'كريم سامي',
          phone: '01033344455',
          email: 'karim@gym.com',
          specialization: 'كروس فت',
          salary: 5500,
          schedule: 'كل يوم 2 ظ - 10 م',
        ),
      ];

  @override
  Future<List<Trainer>> fetchAll() async {
    final list = _load();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<Trainer> create(Trainer trainer) async {
    final id = 't_${DateTime.now().microsecondsSinceEpoch}';
    final created = trainer.copyWith(id: id);
    final list = _load();
    list.add(created);
    _save(list);
    return created;
  }

  @override
  Future<void> update(Trainer trainer) async {
    final list = _load();
    final index = list.indexWhere((t) => t.id == trainer.id);
    if (index == -1) {
      throw const DataException(code: 'not_found');
    }
    list[index] = trainer;
    _save(list);
  }

  @override
  Future<void> delete(String id) async {
    _save(_load().where((t) => t.id != id).toList());
  }
}