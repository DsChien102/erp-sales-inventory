/// Resolves whether and when to retry a failed fetch.
class RetryResolver {
  RetryResolver({
    required this.maxRetries,
    required this.retryDelay,
    required this.retryOn,
  });

  final int maxRetries;
  final Duration Function(int attempt) retryDelay;
  final bool Function(Object error) retryOn;

  bool shouldRetry(Object error, int failureCount) {
    if (failureCount > maxRetries) return false;
    return retryOn(error);
  }

  Duration delayForAttempt(int failureCount) {
    return retryDelay(failureCount);
  }
}
