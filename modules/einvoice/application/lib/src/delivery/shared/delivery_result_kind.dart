/// Exhaustive classification of a delivery provider outcome.
///
/// `undetermined` means the send may have dispatched; it must never be
/// treated as a retryable failure.
enum DeliveryResultKind {
  success,
  definiteFailure,
  retryableFailure,
  undetermined,
}
