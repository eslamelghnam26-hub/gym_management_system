import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management_system/providers/shared_prefs_provider.dart';

enum AppThemeMode { light, dark, system }

extension AppThemeModeX on AppThemeMode {
  ThemeMode get toFlutterThemeMode => switch (this) {
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
        AppThemeMode.system => ThemeMode.system,
      };
}

class ThemeController extends Notifier<AppThemeMode> {
  static const String _key = 'theme_mode';

  @override
  AppThemeMode build() {
    final raw = ref.read(sharedPreferencesProvider).getString(_key);
    return AppThemeMode.values.firstWhere(
      (mode) => mode.name == raw,
      orElse: () => AppThemeMode.system,
    );
  }

  void setMode(AppThemeMode mode) {
    if (state == mode) return;
    state = mode;
    ref.read(sharedPreferencesProvider).setString(_key, mode.name);
  }
}

final themeModeProvider =
    NotifierProvider<ThemeController, AppThemeMode>(ThemeController.new);