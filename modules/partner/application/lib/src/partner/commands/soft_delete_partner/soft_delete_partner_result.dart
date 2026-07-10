/// Result of soft-deleting a partner.
final class SoftDeletePartnerResult {
  const SoftDeletePartnerResult({
    required this.partnerId,
    required this.expectedVersion,
  });

  final String partnerId;
  final int expectedVersion;
}
