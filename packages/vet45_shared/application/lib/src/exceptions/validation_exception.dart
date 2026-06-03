/// Thrown when a command fails application-layer validation.
final class ValidationException implements Exception {
  ValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Deprecated alias — use [ValidationException].
@Deprecated('Use ValidationException')
typedef CommandValidationException = ValidationException;
