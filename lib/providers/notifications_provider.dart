import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management_system/core/config/app_config.dart';
import 'package:gym_management_system/models/gym_notification.dart';
import 'package:gym_management_system/providers/shared_prefs_provider.dart';
import 'package:gym_management_system/repositories/demo_notification_repository.dart';
import 'package:gym_management_system/repositories/firebase_notification_repository.dart';
import 'package:gym_management_system/repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  if (AppConfig.isFirebase) return FirebaseNotificationRepository();
  return DemoNotificationRepository(ref.read(sharedPreferencesProvider));
});

class NotificationsController extends AsyncNotifier<List<GymNotification>> {
  NotificationRepository get _repo => ref.read(notificationRepositoryProvider);

  @override
  Future<List<GymNotification>> build() => _repo.fetchAll();

  Future<void> add(GymNotification notification) async {
    final created = await _repo.add(notification);
    state = AsyncData([created, ...?state.value]);
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    state = AsyncData([
      for (final n in (state.value ?? const [])) if (n.id != id) n,
    ]);
  }
}

final notificationsControllerProvider =
    AsyncNotifierProvider<NotificationsController, List<GymNotification>>(
        NotificationsController.new);