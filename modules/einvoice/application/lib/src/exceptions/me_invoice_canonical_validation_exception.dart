/// Deterministic canonical payload fault before the publish dispatch barrier.
final class MeInvoiceCanonicalValidationException implements Exception {
  const MeInvoiceCanonicalValidationException(this.reasonCode, {this.message});

  final String reasonCode;
  final String? message;

  @override
  String toString() => message ?? reasonCode;
}
