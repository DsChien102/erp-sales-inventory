/// MISA publish retry policy for provider rejection codes (TH-08 H1).
abstract final class PublishProviderRetryPolicy {
  /// Maximum automatic publish retries per attempt for retryable provider codes.
  static const maxAttempts = 3;

  /// MISA recommends waiting before retrying after number-gap rejection.
  static const minInvoiceNumberNotContinuousBackoff = Duration(seconds: 5);

  static Duration backoffForAttempt(int completedRetryCount) {
    if (completedRetryCount <= 1) {
      return minInvoiceNumberNotContinuousBackoff;
    }
    return const Duration(seconds: 30);
  }
}
