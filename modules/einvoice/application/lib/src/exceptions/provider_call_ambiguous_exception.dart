/// Raised when a provider HTTP call is ambiguous (timeout/transport/5xx).
///
/// Worker handlers audit the interaction, retry the same operation, and may end
/// at CHECK_REQUIRED after attempt exhaustion.
final class ProviderCallAmbiguousException implements Exception {
  const ProviderCallAmbiguousException(this.safeErrorCode, {this.message});

  final String safeErrorCode;
  final String? message;

  @override
  String toString() => message == null
      ? 'ProviderCallAmbiguousException($safeErrorCode)'
      : 'ProviderCallAmbiguousException($safeErrorCode: $message)';
}
