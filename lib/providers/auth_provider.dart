import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management_system/core/config/app_config.dart';
import 'package:gym_management_system/models/app_user.dart';
import 'package:gym_management_system/providers/shared_prefs_provider.dart';
import 'package:gym_management_system/repositories/auth_repository.dart';
import 'package:gym_management_system/repositories/demo_auth_repository.dart';
import 'package:gym_management_system/repositories/firebase_auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (AppConfig.isFirebase) return FirebaseAuthRepository();
  return DemoAuthRepository(ref.read(sharedPreferencesProvider));
});

class AuthController extends AsyncNotifier<AppUser?> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  Future<AppUser?> build() => _repo.currentUser();

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    try {
      final user = await _repo.signIn(email, password);
      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      final user = AppUser(
        uid: '',
        email: email,
        name: name,
        phone: phone,
        role: UserRole.member,
      );
      final created = await _repo.signUp(user, password);
      state = AsyncData(created);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = const AsyncData(null);
  }

  Future<void> forgotPassword(String email) async {
    await _repo.sendPasswordReset(email);
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AppUser?>(AuthController.new);