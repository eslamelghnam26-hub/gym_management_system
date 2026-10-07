import 'package:gym_management_system/models/gym_notification.dart';

/// Repository contract for in-app notifications. A web dashboard writes
/// notifications into the `notifications` collection; the mobile app can
/// later read them by target (uid or "all").
abstract class NotificationRepository {
  Future<List<GymNotification>> fetchAll();
  Future<GymNotification> add(GymNotification notification);
  Future<void> delete(String id);
}