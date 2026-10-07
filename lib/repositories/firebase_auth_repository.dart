import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gym_management_system/core/constants/firestore_schema.dart';
import 'package:gym_management_system/core/errors/app_exception.dart';
import 'package:gym_management_system/models/app_user.dart';
import 'package:gym_management_system/repositories/auth_repository.dart';

/// Real Firebase Authentication implementation. The `users` collection also
/// stores display name + role so other features can apply RBAC from Firestore
/// Security Rules.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  @override
  Future<AppUser?> currentUser() async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return null;
    return _buildUser(fbUser);
  }

  Future<AppUser> _buildUser(User fbUser) async {
    try {
      final doc = await _db.collection(FirestoreSchema.users).doc(fbUser.uid).get();
      if (doc.exists) {
        return AppUser.fromJson({...doc.data()!, 'uid': fbUser.uid});
      }
    } catch (_) {
      // fall through to default user built from Firebase profile
    }
    return AppUser(
      uid: fbUser.uid,
      email: fbUser.email ?? '',
      name: fbUser.displayName ?? (fbUser.email?.split('@').first ?? 'User'),
      photoUrl: fbUser.photoURL,
      role: UserRole.member,
    );
  }

  @override
  Future<AppUser> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return await _buildUser(credential.user!);
    } on FirebaseAuthException catch (e) {
      throw _mapAuthError(e);
    }
  }

  @override
  Future<AppUser> signUp(AppUser user, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: user.email.trim(),
        password: password,
      );
      await credential.user!.updateDisplayName(user.name);
      final safe = AppUser(
        uid: credential.user!.uid,
        email: credential.user!.email ?? user.email,
        name: user.name,
        phone: user.phone,
        photoUrl: user.photoUrl,
        role: user.role,
      );
      await _db.collection(FirestoreSchema.users).doc(safe.uid).set(safe.toJson());
      return safe;
    } on FirebaseAuthException catch (e) {
      throw _mapAuthError(e);
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _mapAuthError(e);
    }
  }

  AppException _mapAuthError(FirebaseAuthException e) {
    return switch (e.code) {
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' ||
      'invalid-login-credentials' =>
        const AuthException(code: 'invalid_credentials'),
      'email-already-in-use' => const AuthException(code: 'email_in_use'),
      'weak-password' => const AuthException(code: 'weak_password'),
      'invalid-email' => const AuthException(code: 'invalid_email'),
      'network-request-failed' => const NetworkException(),
      _ => AuthException(code: 'auth', message: e.message),
    };
  }
}