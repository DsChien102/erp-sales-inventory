/// Issuance attempt lifecycle.
enum IssuanceAttemptStatus {
  preparing,
  submitted,
  waitingResult,
  reconciling,
  succeeded,
  failed,
}
