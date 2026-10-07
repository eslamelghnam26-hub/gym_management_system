import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management_system/core/config/app_config.dart';
import 'package:gym_management_system/models/trainer.dart';
import 'package:gym_management_system/providers/shared_prefs_provider.dart';
import 'package:gym_management_system/repositories/demo_trainer_repository.dart';
import 'package:gym_management_system/repositories/firebase_trainer_repository.dart';
import 'package:gym_management_system/repositories/trainer_repository.dart';

final trainerRepositoryProvider = Provider<TrainerRepository>((ref) {
  if (AppConfig.isFirebase) return FirebaseTrainerRepository();
  return DemoTrainerRepository(ref.read(sharedPreferencesProvider));
});

class TrainersController extends AsyncNotifier<List<Trainer>> {
  TrainerRepository get _repo => ref.read(trainerRepositoryProvider);

  @override
  Future<List<Trainer>> build() => _repo.fetchAll();

  Future<void> _reload() async {
    try {
      state = AsyncData(await _repo.fetchAll());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> add(Trainer trainer) async {
    await _repo.create(trainer);
    await _reload();
  }

  Future<void> save(Trainer trainer) async {
    await _repo.update(trainer);
    await _reload();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    await _reload();
  }

  Trainer? byId(String id) {
    final list = state.value;
    if (list == null) return null;
    for (final trainer in list) {
      if (trainer.id == id) return trainer;
    }
    return null;
  }
}

final trainersControllerProvider =
    AsyncNotifierProvider<TrainersController, List<Trainer>>(TrainersController.new);