import 'package:gym_management_system/models/app_user.dart';

/// Contract for the authentication layer. Implementations:
/// - [DemoAuthRepository]: fully offline, persists to [SharedPreferences]
///   so the app runs without any Firebase config.
/// - [FirebaseAuthRepository]: real Firebase Authentication + Firestore.
abstract class AuthRepository {
  Future<AppUser?> currentUser();

  Future<AppUser> signIn(String email, String password);

  Future<AppUser> signUp(AppUser user, String password);

  Future<void> signOut();

  Future<void> sendPasswordReset(String email);
}