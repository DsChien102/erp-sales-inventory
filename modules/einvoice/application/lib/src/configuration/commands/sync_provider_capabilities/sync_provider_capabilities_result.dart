final class ProviderCapabilitiesDto {
  const ProviderCapabilitiesDto({
    required this.connectionId, required this.supportsEmailDelivery, required this.templateCount,
  });

  final String connectionId;
  final bool supportsEmailDelivery;
  final int templateCount;
}
