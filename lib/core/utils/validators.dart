/// Lightweight validators returning error *codes* (not text) so the UI can
/// localize them. `null` means "valid".
abstract final class Validators {
  static final RegExp _email = RegExp(r'^[\w.\-+]+@[\w\-]+(\.[\w\-]+)+$');
  static final RegExp _phone = RegExp(r'^[0-9+\-\s]{8,15}$');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'required';
    if (!_email.hasMatch(v)) return 'invalid_email';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'required';
    if (v.length < 6) return 'short_password';
    return null;
  }

  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) return 'required';
    return null;
  }

  static String? phone(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    if (!_phone.hasMatch(v)) return 'invalid_phone';
    return null;
  }
}