/// Base exception for the whole app. Every error raised by repositories and
/// services is one of these, which keeps the UI layer free of SDK-specific
/// error types (FirebaseAuthException, PlatformException, ...).
///
/// [code] is a stable machine-readable key that screens map to localized
/// messages via `AppStrings.errorMessage`.
abstract class AppException implements Exception {
  const AppException({required this.code, this.message});

  final String code;
  final String? message;

  @override
  String toString() => message ?? code;
}

class AuthException extends AppException {
  const AuthException({required super.code, super.message});
}

class DataException extends AppException {
  const DataException({required super.code, super.message});
}

class NetworkException extends AppException {
  const NetworkException({super.message})
      : super(code: 'network');
}