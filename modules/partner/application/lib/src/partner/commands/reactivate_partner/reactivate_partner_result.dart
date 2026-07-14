/// Result of reactivating a partner.
final class ReactivatePartnerResult {
  const ReactivatePartnerResult({
    required this.partnerId,
    required this.expectedVersion,
  });

  final String partnerId;
  final int expectedVersion;
}
