import 'dart:convert';

import 'package:gym_management_system/core/errors/app_exception.dart';
import 'package:gym_management_system/models/membership_plan.dart';
import 'package:gym_management_system/repositories/membership_plan_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DemoMembershipPlanRepository implements MembershipPlanRepository {
  DemoMembershipPlanRepository(this._prefs);

  final SharedPreferences _prefs;
  static const String _key = 'demo_plans';

  List<MembershipPlan> _load() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      final seeded = _seed();
      _save(seeded);
      return seeded;
    }
    final list = jsonDecode(raw) as List<dynamic>;
    return [
      for (final item in list)
        MembershipPlan.fromJson(item as Map<String, dynamic>),
    ];
  }

  void _save(List<MembershipPlan> plans) {
    _prefs.setString(_key, jsonEncode([for (final p in plans) p.toJson()]));
  }

  List<MembershipPlan> _seed() => [
        MembershipPlan(
          id: 'plan_1',
          name: 'باقة شهرية',
          durationDays: 30,
          price: 900,
          sessions: 12,
          features: ['تجديف ومنطقة الكارديو', 'حمام وبخار', 'تمارين حرة'],
        ),
        MembershipPlan(
          id: 'plan_2',
          name: 'باقة ربع سنوية',
          durationDays: 90,
          price: 2400,
          sessions: 36,
          features: ['كل مميزات الشهرية', 'جلسة تقييم بدني', 'خصم 15% على المكملات'],
        ),
        MembershipPlan(
          id: 'plan_3',
          name: 'باقة سنوية',
          durationDays: 365,
          price: 8400,
          sessions: 0,
          features: ['دخول غير محدود', 'عضوية VIP', 'مدرب أسبوعي', 'حجز الساونا'],
        ),
      ];

  @override
  Future<List<MembershipPlan>> fetchAll() async {
    final list = _load();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<MembershipPlan> create(MembershipPlan plan) async {
    final id = 'plan_${DateTime.now().microsecondsSinceEpoch}';
    final created = plan.copyWith(id: id);
    final list = _load();
    list.add(created);
    _save(list);
    return created;
  }

  @override
  Future<void> update(MembershipPlan plan) async {
    final list = _load();
    final index = list.indexWhere((p) => p.id == plan.id);
    if (index == -1) {
      throw const DataException(code: 'not_found');
    }
    list[index] = plan;
    _save(list);
  }

  @override
  Future<void> delete(String id) async {
    _save(_load().where((p) => p.id != id).toList());
  }
}