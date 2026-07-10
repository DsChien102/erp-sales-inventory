/// Result of deactivating a partner.
final class DeactivatePartnerResult {
  const DeactivatePartnerResult({
    required this.partnerId,
    required this.expectedVersion,
  });

  final String partnerId;
  final int expectedVersion;
}
