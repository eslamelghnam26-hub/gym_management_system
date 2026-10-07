import 'dart:convert';

import 'package:gym_management_system/models/gym_notification.dart';
import 'package:gym_management_system/repositories/notification_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DemoNotificationRepository implements NotificationRepository {
  DemoNotificationRepository(this._prefs);

  final SharedPreferences _prefs;
  static const String _key = 'demo_notifications';

  List<GymNotification> _load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return [
      for (final item in list)
        GymNotification.fromJson(item as Map<String, dynamic>),
    ];
  }

  void _save(List<GymNotification> list) {
    _prefs.setString(_key, jsonEncode([for (final n in list) n.toJson()]));
  }

  @override
  Future<List<GymNotification>> fetchAll() async {
    final list = _load();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<GymNotification> add(GymNotification notification) async {
    final id = 'n_${DateTime.now().microsecondsSinceEpoch}';
    final created = notification.copyWith(id: id);
    final list = _load();
    list.add(created);
    _save(list);
    return created;
  }

  @override
  Future<void> delete(String id) async {
    _save(_load().where((n) => n.id != id).toList());
  }
}