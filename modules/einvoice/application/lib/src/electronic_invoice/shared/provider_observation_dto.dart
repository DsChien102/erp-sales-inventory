/// Append-only provider observation snapshot.
final class ProviderObservationDto {
  const ProviderObservationDto({
    required this.observationId,
    required this.electronicInvoiceId,
    required this.providerStateCode,
    required this.observedAt,
    this.safeDescription,
    this.providerReference,
    this.source,
    this.correlationId,
    this.detailsSnapshot = const {},
  });

  final String observationId;
  final String electronicInvoiceId;
  final String providerStateCode;
  final DateTime observedAt;
  final String? safeDescription;
  final String? providerReference;
  final String? source;

  /// Correlation id stored on the observation row.
  final String? correlationId;
  final Map<String, Object?> detailsSnapshot;
}
