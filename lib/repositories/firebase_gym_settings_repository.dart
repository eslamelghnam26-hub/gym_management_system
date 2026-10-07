import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_management_system/core/constants/firestore_schema.dart';
import 'package:gym_management_system/models/gym_settings.dart';
import 'package:gym_management_system/repositories/gym_settings_repository.dart';

class FirebaseSettingsRepository implements GymSettingsRepository {
  static const String _docId = 'global';

  @override
  Future<GymSettings> fetch() async {
    final snapshot = await FirebaseFirestore.instance
        .collection(FirestoreSchema.gymSettings)
        .doc(_docId)
        .get();
    if (!snapshot.exists) return GymSettings.defaults;
    return GymSettings.fromJson(snapshot.data()!);
  }

  @override
  Future<void> save(GymSettings settings) async {
    await FirebaseFirestore.instance
        .collection(FirestoreSchema.gymSettings)
        .doc(_docId)
        .set(settings.toJson());
  }
}