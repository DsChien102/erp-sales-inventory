/// Append-only provider observation snapshot.
final class ProviderObservationDto {
  const ProviderObservationDto({
    required this.observationId,
    required this.electronicInvoiceId,
    required this.payload,
    required this.observedAt,
  });

  final String observationId;
  final String electronicInvoiceId;
  final Map<String, Object?> payload;
  final DateTime observedAt;
}
