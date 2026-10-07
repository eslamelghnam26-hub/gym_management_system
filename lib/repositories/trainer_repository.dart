import 'package:gym_management_system/models/trainer.dart';

abstract class TrainerRepository {
  Future<List<Trainer>> fetchAll();
  Future<Trainer> create(Trainer trainer);
  Future<void> update(Trainer trainer);
  Future<void> delete(String id);
}