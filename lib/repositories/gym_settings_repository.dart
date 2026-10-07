import 'package:gym_management_system/models/gym_settings.dart';

abstract class GymSettingsRepository {
  Future<GymSettings> fetch();
  Future<void> save(GymSettings settings);
}