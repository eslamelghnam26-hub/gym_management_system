import 'package:gym_management_system/models/app_user.dart';

/// Repository contract for managing staff/accounts in the `users` collection.
/// Read-only for regular apps; the web admin uses it to adjust roles.
abstract class UserRepository {
  Future<List<AppUser>> fetchAll();
  Future<void> update(AppUser user);
  Future<void> delete(String uid);
}