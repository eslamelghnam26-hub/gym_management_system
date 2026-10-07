import 'dart:convert';

import 'package:gym_management_system/core/errors/app_exception.dart';
import 'package:gym_management_system/models/subscription.dart';
import 'package:gym_management_system/repositories/subscription_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DemoSubscriptionRepository implements SubscriptionRepository {
  DemoSubscriptionRepository(this._prefs);

  final SharedPreferences _prefs;
  static const String _key = 'demo_subscriptions';

  List<Subscription> _load() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      final seeded = _seed();
      _save(seeded);
      return seeded;
    }
    final list = jsonDecode(raw) as List<dynamic>;
    return [
      for (final item in list) Subscription.fromJson(item as Map<String, dynamic>)
    ];
  }

  void _save(List<Subscription> list) {
    _prefs.setString(_key, jsonEncode([for (final s in list) s.toJson()]));
  }

  List<Subscription> _seed() {
    final now = DateTime.now();
    return [
      Subscription(
        id: 'sub_1',
        memberId: 'm_1',
        planId: 'plan_1',
        startDate: now.subtract(const Duration(days: 20)),
        endDate: now.add(const Duration(days: 10)),
        price: 900,
        method: 'cash',
        status: SubscriptionStatus.active,
      ),
      Subscription(
        id: 'sub_2',
        memberId: 'm_2',
        planId: 'plan_2',
        startDate: now.subtract(const Duration(days: 30)),
        endDate: now.add(const Duration(days: 60)),
        price: 2400,
        method: 'card',
        status: SubscriptionStatus.active,
      ),
      Subscription(
        id: 'sub_3',
        memberId: 'm_3',
        planId: 'plan_3',
        startDate: now.subtract(const Duration(days: 100)),
        endDate: now.subtract(const Duration(days: 5)),
        price: 8400,
        method: 'bank_transfer',
        status: SubscriptionStatus.expired,
      ),
      Subscription(
        id: 'sub_4',
        memberId: 'm_4',
        planId: 'plan_1',
        startDate: now.add(const Duration(days: 3)),
        endDate: now.add(const Duration(days: 33)),
        price: 900,
        method: 'wallet',
        status: SubscriptionStatus.active,
      ),
      Subscription(
        id: 'sub_5',
        memberId: 'm_5',
        planId: 'plan_2',
        startDate: now.subtract(const Duration(days: 90)),
        endDate: now.subtract(const Duration(days: 60)),
        price: 2400,
        method: 'cash',
        status: SubscriptionStatus.cancelled,
      ),
      Subscription(
        id: 'sub_6',
        memberId: 'm_6',
        planId: 'plan_1',
        startDate: now.subtract(const Duration(days: 10)),
        endDate: now.subtract(const Duration(days: 1)),
        price: 900,
        method: 'cash',
        status: SubscriptionStatus.expired,
      ),
    ];
  }

  @override
  Future<List<Subscription>> fetchAll() async {
    final list = _load();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<Subscription> create(Subscription subscription) async {
    final id = 'sub_${DateTime.now().microsecondsSinceEpoch}';
    final created = subscription.copyWith(id: id);
    final list = _load();
    list.add(created);
    _save(list);
    return created;
  }

  @override
  Future<void> update(Subscription subscription) async {
    final list = _load();
    final index = list.indexWhere((s) => s.id == subscription.id);
    if (index == -1) throw const DataException(code: 'not_found');
    list[index] = subscription;
    _save(list);
  }

  @override
  Future<void> delete(String id) async {
    _save(_load().where((s) => s.id != id).toList());
  }
}