import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management_system/core/config/app_config.dart';
import 'package:gym_management_system/models/app_user.dart';
import 'package:gym_management_system/providers/shared_prefs_provider.dart';
import 'package:gym_management_system/repositories/demo_user_repository.dart';
import 'package:gym_management_system/repositories/firebase_user_repository.dart';
import 'package:gym_management_system/repositories/user_repository.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  if (AppConfig.isFirebase) return FirebaseUserRepository();
  return DemoUserRepository(ref.read(sharedPreferencesProvider));
});

class UsersController extends AsyncNotifier<List<AppUser>> {
  UserRepository get _repo => ref.read(userRepositoryProvider);

  @override
  Future<List<AppUser>> build() => _repo.fetchAll();

  Future<void> save(AppUser user) async {
    await _repo.update(user);
    state = AsyncData([
      for (final u in (state.value ?? const []))
        if (u.uid == user.uid) user else u,
    ]);
  }

  Future<void> delete(String uid) async {
    await _repo.delete(uid);
    state = AsyncData([
      for (final u in (state.value ?? const [])) if (u.uid != uid) u,
    ]);
  }
}

final usersControllerProvider =
    AsyncNotifierProvider<UsersController, List<AppUser>>(UsersController.new);