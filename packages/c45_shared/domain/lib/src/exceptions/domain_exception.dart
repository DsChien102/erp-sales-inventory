/// Base type for domain-layer failures surfaced to callers.
class DomainException implements Exception {
  DomainException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}
