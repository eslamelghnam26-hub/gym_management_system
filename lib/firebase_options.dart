import 'package:firebase_core/firebase_core.dart';

/// Placeholder Firebase configuration.
///
/// This file is intentionally a TEMPLATE: there is no Firebase project yet.
/// Two ways to fill it in later:
///
/// 1. Recommended: run `flutterfire configure` at the project root after
///    creating the Firebase project — it regenerates this file automatically.
/// 2. Or fill in the fields below manually (values, not comments).
///
/// While these fields stay empty, `FirebaseBootstrap.initialize` refuses to
/// start Firebase and every app (mobile + web admin) transparently stays in
/// the offline demo mode, so nothing breaks.
abstract final class DefaultFirebaseOptions {
  static const FirebaseOptions currentPlatform = FirebaseOptions(
    apiKey: '',
    appId: '',
    messagingSenderId: '',
    projectId: '',
    storageBucket: '',
    authDomain: '',
    measurementId: '',
  );

  static bool get isConfigured =>
      currentPlatform.apiKey.isNotEmpty &&
      currentPlatform.appId.isNotEmpty &&
      currentPlatform.projectId.isNotEmpty;
}