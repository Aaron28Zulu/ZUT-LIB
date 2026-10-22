/// Errors thrown by services. Every message is written for the end user
/// (docs/DESIGN_CONVENTIONS.md, "Copy") and can be shown as-is in a snackbar.
sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The signed-in user's role or tenant does not allow the action (FR-AUTH-08).
class PermissionDeniedException extends AppException {
  const PermissionDeniedException([
    super.message = 'Your account does not have permission to do this.',
  ]);
}

/// A business rule refused the action, e.g. the loan limit (FR-BOR-02).
class RuleException extends AppException {
  const RuleException(super.message);
}

class NotFoundException extends AppException {
  const NotFoundException(super.message);
}

class AuthException extends AppException {
  const AuthException(super.message);
}

/// Form validation with one message per field (FR-RES-02).
class ValidationException extends AppException {
  const ValidationException(this.fieldErrors)
      : super('Some fields need attention.');

  final Map<String, String> fieldErrors;
}
