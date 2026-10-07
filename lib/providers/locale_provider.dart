import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management_system/providers/shared_prefs_provider.dart';

class LocaleController extends Notifier<Locale> {
  static const String _key = 'locale';

  @override
  Locale build() {
    final code = ref.read(sharedPreferencesProvider).getString(_key) ?? 'ar';
    return Locale(code);
  }

  void setLocale(String languageCode) {
    if (languageCode == state.languageCode) return;
    state = Locale(languageCode);
    ref.read(sharedPreferencesProvider).setString(_key, languageCode);
  }
}

final localeProvider = NotifierProvider<LocaleController, Locale>(LocaleController.new);