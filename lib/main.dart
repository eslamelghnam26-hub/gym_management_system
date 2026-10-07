import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management_system/app/app.dart';
import 'package:gym_management_system/core/config/app_config.dart';
import 'package:gym_management_system/providers/shared_prefs_provider.dart';
import 'package:gym_management_system/services/firebase_bootstrap.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final firebaseReady = await FirebaseBootstrap.initialize();
  AppConfig.dataSource =
      firebaseReady ? AppDataSource.firebase : AppDataSource.local;
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const GymApp(),
    ),
  );
}