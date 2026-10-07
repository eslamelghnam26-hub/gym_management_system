import 'dart:convert';

import 'package:gym_management_system/core/errors/app_exception.dart';
import 'package:gym_management_system/models/app_user.dart';
import 'package:gym_management_system/repositories/demo_auth_repository.dart';
import 'package:gym_management_system/repositories/user_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Demo user store shares the same `demo_users` prefs key used by
/// [DemoAuthRepository], so role changes made from the web admin remain
/// consistent with the offline auth used by the app.
class DemoUserRepository implements UserRepository {
  DemoUserRepository(this._prefs);

  final SharedPreferences _prefs;
  static const String _usersKey = 'demo_users';

  List<AppUser> _load() {
    final raw = _prefs.getString(_usersKey);
    if (raw == null) return _seed();
    final list = jsonDecode(raw) as List<dynamic>;
    return [for (final item in list) AppUser.fromJson(item as Map<String, dynamic>)];
  }

  List<AppUser> _seed() {
    final seeded = [
      for (final d in DemoAuthRepository.demoAccounts)
        AppUser(uid: d.email, email: d.email, name: '${d.role.labelEn} User', role: d.role),
    ];
    _save(seeded);
    return seeded;
  }

  void _save(List<AppUser> users) {
    _prefs.setString(_usersKey, jsonEncode([for (final u in users) u.toJson()]));
  }

  @override
  Future<List<AppUser>> fetchAll() async => _load();

  @override
  Future<void> update(AppUser user) async {
    final list = _load();
    final index = list.indexWhere((u) => u.uid == user.uid);
    if (index == -1) throw const DataException(code: 'not_found');
    list[index] = user;
    _save(list);
  }

  @override
  Future<void> delete(String uid) async {
    _save(_load().where((u) => u.uid != uid).toList());
  }
}