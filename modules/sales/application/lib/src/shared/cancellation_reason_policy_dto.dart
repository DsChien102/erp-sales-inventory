/// Authoritative cancellation reason policy row (S24).
///
/// Display name, requires-note and ordering are owned by the backend policy
/// projection; presentation must not synthesize labels or fall back to the
/// reason code.
final class CancellationReasonPolicyDto {
  const CancellationReasonPolicyDto({
    required this.reasonCode,
    required this.displayName,
    required this.requiresNote,
    required this.sortOrder,
  });

  final String reasonCode;
  final String displayName;
  final bool requiresNote;
  final int sortOrder;
}
