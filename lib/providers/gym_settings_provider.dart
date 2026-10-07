import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management_system/core/config/app_config.dart';
import 'package:gym_management_system/models/gym_settings.dart';
import 'package:gym_management_system/providers/shared_prefs_provider.dart';
import 'package:gym_management_system/repositories/demo_gym_settings_repository.dart';
import 'package:gym_management_system/repositories/firebase_gym_settings_repository.dart';
import 'package:gym_management_system/repositories/gym_settings_repository.dart';

final settingsRepositoryProvider = Provider<GymSettingsRepository>((ref) {
  if (AppConfig.isFirebase) return FirebaseSettingsRepository();
  return DemoSettingsRepository(ref.read(sharedPreferencesProvider));
});

class GymSettingsController extends AsyncNotifier<GymSettings> {
  GymSettingsRepository get _repo => ref.read(settingsRepositoryProvider);

  @override
  Future<GymSettings> build() => _repo.fetch();

  Future<void> save(GymSettings settings) async {
    await _repo.save(settings);
    state = AsyncData(settings);
  }
}

final gymSettingsProvider =
    AsyncNotifierProvider<GymSettingsController, GymSettings>(
        GymSettingsController.new);