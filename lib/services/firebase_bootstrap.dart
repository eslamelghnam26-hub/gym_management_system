import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:gym_management_system/core/config/app_config.dart';
import 'package:gym_management_system/firebase_options.dart';

/// Tries to initialize the Firebase SDK automatically once
/// `lib/firebase_options.dart` is filled in (e.g. after running
/// `flutterfire configure`).
///
/// - `--dart-define=DATA_SOURCE=local` forces the offline demo data source.
/// - `--dart-define=DATA_SOURCE=firebase` requires Firebase and fails back to
///   demo mode only if initialization throws.
/// - No define (default): connects to Firebase as soon as the options file
///   contains real values.
abstract final class FirebaseBootstrap {
  static Future<bool> initialize() async {
    const requested = String.fromEnvironment('DATA_SOURCE');
    if (requested == 'local') return false;

    if (!DefaultFirebaseOptions.isConfigured) {
      debugPrint('FirebaseBootstrap: lib/firebase_options.dart has empty '
          'placeholders → staying in local demo mode.');
      return false;
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      if (AppConfig.isFirebase == false) {
        AppConfig.dataSource = AppDataSource.firebase;
      }
      return true;
    } catch (e) {
      debugPrint('FirebaseBootstrap: failed to init Firebase ($e) '
          '→ falling back to local demo mode.');
      return false;
    }
  }
}