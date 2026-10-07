import 'dart:convert';

import 'package:gym_management_system/core/errors/app_exception.dart';
import 'package:gym_management_system/models/app_user.dart';
import 'package:gym_management_system/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DemoAccount {
  const DemoAccount({
    required this.email,
    required this.password,
    required this.role,
  });

  final String email;
  final String password;
  final UserRole role;
}

/// Offline authentication used in demo/local mode so the portfolio app runs
/// out of the box. Mirrors the same contract as the Firebase implementation —
/// swapping data source does not touch UI code.
class DemoAuthRepository implements AuthRepository {
  DemoAuthRepository(this._prefs);

  final SharedPreferences _prefs;

  static const String _usersKey = 'demo_users';
  static const String _passwordsKey = 'demo_passwords';
  static const String _currentUidKey = 'demo_current_uid';

  static const List<DemoAccount> demoAccounts = [
    DemoAccount(email: 'admin@gym.com', password: 'password123', role: UserRole.admin),
    DemoAccount(email: 'reception@gym.com', password: 'password123', role: UserRole.receptionist),
    DemoAccount(email: 'trainer@gym.com', password: 'password123', role: UserRole.trainer),
    DemoAccount(email: 'member@gym.com', password: 'password123', role: UserRole.member),
  ];

  List<AppUser> _loadUsers() {
    final raw = _prefs.getString(_usersKey);
    if (raw == null) {
      final seeded = [
        for (final d in demoAccounts)
          AppUser(uid: d.email, email: d.email, name: '${d.role.labelEn} User', role: d.role),
      ];
      _saveUsers(seeded);
      return seeded;
    }
    final list = jsonDecode(raw) as List<dynamic>;
    return [for (final item in list) AppUser.fromJson(item as Map<String, dynamic>)];
  }

  void _saveUsers(List<AppUser> users) {
    _prefs.setString(_usersKey, jsonEncode([for (final u in users) u.toJson()]));
  }

  Map<String, String> _loadPasswords() {
    final defaults = {for (final d in demoAccounts) d.email.toLowerCase(): d.password};
    final raw = _prefs.getString(_passwordsKey);
    if (raw == null) return defaults;
    return {...defaults, ...(jsonDecode(raw) as Map<String, dynamic>).cast<String, String>()};
  }

  void _savePassword(String email, String password) {
    final map = _loadPasswords();
    map[email.toLowerCase()] = password;
    _prefs.setString(_passwordsKey, jsonEncode(map));
  }

  @override
  Future<AppUser?> currentUser() async {
    final uid = _prefs.getString(_currentUidKey);
    if (uid == null) return null;
    final users = _loadUsers();
    for (final user in users) {
      if (user.uid == uid) return user;
    }
    return null;
  }

  @override
  Future<AppUser> signIn(String email, String password) async {
    final normalized = email.trim().toLowerCase();
    final users = _loadUsers();
    AppUser? match;
    for (final user in users) {
      if (user.email.toLowerCase() == normalized) {
        match = user;
        break;
      }
    }
    if (match == null) {
      throw const AuthException(code: 'invalid_credentials');
    }
    if (_loadPasswords()[normalized] != password) {
      throw const AuthException(code: 'invalid_credentials');
    }
    await _prefs.setString(_currentUidKey, match.uid);
    return match;
  }

  @override
  Future<AppUser> signUp(AppUser user, String password) async {
    final normalized = user.email.trim().toLowerCase();
    final users = _loadUsers();
    for (final existing in users) {
      if (existing.email.toLowerCase() == normalized) {
        throw const AuthException(code: 'email_in_use');
      }
    }
    final created = AppUser(
      uid: normalized,
      email: normalized,
      name: user.name,
      phone: user.phone,
      photoUrl: user.photoUrl,
      role: user.role,
    );
    users.add(created);
    _saveUsers(users);
    _savePassword(normalized, password);
    await _prefs.setString(_currentUidKey, created.uid);
    return created;
  }

  @override
  Future<void> signOut() async {
    await _prefs.remove(_currentUidKey);
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    final normalized = email.trim().toLowerCase();
    final exists = _loadUsers().any((u) => u.email.toLowerCase() == normalized);
    if (!exists) {
      throw const AuthException(code: 'user_not_found');
    }
    _savePassword(normalized, 'password123');
  }
}