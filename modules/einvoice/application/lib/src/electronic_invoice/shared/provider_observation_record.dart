final class ProviderObservationRecord {
  const ProviderObservationRecord({
    required this.tenantId,
    required this.electronicInvoiceId,
    required this.providerStateCode,
    this.safeDescription,
    this.providerReference,
    required this.observedAt,
    required this.deduplicationKey,
    required this.detailsSnapshot,
    required this.providerInteractionReference,
    required this.source,
  });

  final String tenantId;
  final String electronicInvoiceId;
  final String providerStateCode;
  final String? safeDescription;
  final String? providerReference;
  final DateTime observedAt;
  final String deduplicationKey;
  final Map<String, Object?> detailsSnapshot;
  final String providerInteractionReference;
  final String source;
}
