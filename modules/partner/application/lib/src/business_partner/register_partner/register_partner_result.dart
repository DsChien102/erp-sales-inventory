final class RegisterPartnerResult {
  const RegisterPartnerResult({
    required this.businessPartnerId,
    required this.hasTaxCodeWarning,
  });

  final String businessPartnerId;
  final bool hasTaxCodeWarning;
}
