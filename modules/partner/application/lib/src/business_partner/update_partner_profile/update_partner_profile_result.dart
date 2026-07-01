final class UpdatePartnerProfileResult {
  const UpdatePartnerProfileResult({
    required this.businessPartnerId,
    required this.version,
    required this.hasTaxCodeWarning,
  });

  final String businessPartnerId;
  final int version;
  final bool hasTaxCodeWarning;
}
