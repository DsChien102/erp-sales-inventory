/// Application-layer failures surfaced to callers.
class ApplicationException implements Exception {
  ApplicationException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}
