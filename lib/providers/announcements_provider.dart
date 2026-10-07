import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management_system/core/config/app_config.dart';
import 'package:gym_management_system/models/announcement.dart';
import 'package:gym_management_system/providers/shared_prefs_provider.dart';
import 'package:gym_management_system/repositories/announcement_repository.dart';
import 'package:gym_management_system/repositories/demo_announcement_repository.dart';
import 'package:gym_management_system/repositories/firebase_announcement_repository.dart';

final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  if (AppConfig.isFirebase) return FirebaseAnnouncementRepository();
  return DemoAnnouncementRepository(ref.read(sharedPreferencesProvider));
});

class AnnouncementsController extends AsyncNotifier<List<Announcement>> {
  AnnouncementRepository get _repo => ref.read(announcementRepositoryProvider);

  @override
  Future<List<Announcement>> build() => _repo.fetchAll();

  Future<void> _reload() async {
    try {
      state = AsyncData(await _repo.fetchAll());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> add(Announcement announcement) async {
    await _repo.create(announcement);
    await _reload();
  }

  Future<void> save(Announcement announcement) async {
    await _repo.update(announcement);
    await _reload();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    await _reload();
  }
}

final announcementsControllerProvider =
    AsyncNotifierProvider<AnnouncementsController, List<Announcement>>(
        AnnouncementsController.new);