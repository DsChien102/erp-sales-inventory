final class CanonicalInvoiceIntegrityException implements Exception {
  const CanonicalInvoiceIntegrityException({
    required this.attemptId,
    this.reasonCode = 'COMMAND_INTEGRITY',
    required this.message,
  });

  final String attemptId;
  final String reasonCode;
  final String message;

  @override
  String toString() =>
      'CanonicalInvoiceIntegrityException(attemptId: $attemptId, reasonCode: $reasonCode, message: $message)';
}
