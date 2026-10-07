import 'dart:convert';

import 'package:gym_management_system/models/gym_settings.dart';
import 'package:gym_management_system/repositories/gym_settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DemoSettingsRepository implements GymSettingsRepository {
  DemoSettingsRepository(this._prefs);

  final SharedPreferences _prefs;
  static const String _key = 'demo_gym_settings';

  @override
  Future<GymSettings> fetch() async {
    final raw = _prefs.getString(_key);
    if (raw == null) return GymSettings.defaults;
    return GymSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> save(GymSettings settings) async {
    await _prefs.setString(_key, jsonEncode(settings.toJson()));
  }
}