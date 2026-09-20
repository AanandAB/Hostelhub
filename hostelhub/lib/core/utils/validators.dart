/// Input validation helpers for email and phone fields.
class Validators {
  Validators._();

  static final _emailRe = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
  static final _phoneRe = RegExp(r'^[0-9+\s-]{10,15}$');

  static bool isValidEmail(String? v) =>
      v != null && v.trim().isNotEmpty && _emailRe.hasMatch(v.trim());

  static bool isValidPhone(String? v) =>
      v != null && v.trim().isNotEmpty && _phoneRe.hasMatch(v.trim());

  /// Returns an error string for an optional email (empty = OK), else null.
  static String? emailError(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return null; // optional
    return _emailRe.hasMatch(s) ? null : 'Enter a valid email address';
  }

  /// Returns an error string for an optional phone (empty = OK), else null.
  static String? phoneError(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return null; // optional
    return _phoneRe.hasMatch(s) ? null : 'Enter a valid phone number';
  }

  /// For required phone fields (e.g. inmate onboarding).
  static String? requiredPhoneError(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Phone number is required';
    return _phoneRe.hasMatch(s) ? null : 'Enter a valid phone number';
  }

  /// For required email fields (e.g. owner signup, so password reset works).
  static String? requiredEmailError(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Email is required';
    return _emailRe.hasMatch(s) ? null : 'Enter a valid email address';
  }
}
