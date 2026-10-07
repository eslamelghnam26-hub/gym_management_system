import 'package:gym_management_system/models/announcement.dart';

abstract class AnnouncementRepository {
  Future<List<Announcement>> fetchAll();
  Future<Announcement> create(Announcement announcement);
  Future<void> update(Announcement announcement);
  Future<void> delete(String id);
}