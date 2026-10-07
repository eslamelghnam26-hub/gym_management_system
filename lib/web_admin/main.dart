import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management_system/core/config/app_config.dart';
import 'package:gym_management_system/providers/shared_prefs_provider.dart';
import 'package:gym_management_system/services/firebase_bootstrap.dart';
import 'package:gym_management_system/web_admin/web_admin_app.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Web admin dashboard entrypoint.
///
/// Run with:
///   flutter run -d chrome -t lib/web_admin/main.dart --dart-define=DATA_SOURCE=firebase
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final firebaseReady = await FirebaseBootstrap.initialize();
  AppConfig.dataSource =
      firebaseReady ? AppDataSource.firebase : AppDataSource.local;
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const WebAdminApp(),
    ),
  );
}