/// How to interpret the provider status lookup key when polling MISA.
enum IssuanceProviderStatusLookup {
  /// Lookup by MISA transaction id stored on the attempt.
  providerTransactionId,

  /// Lookup by immutable RefID / idempotency key.
  refId,
}
