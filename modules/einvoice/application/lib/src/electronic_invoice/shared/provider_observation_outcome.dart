/// Closed provider outcome for observation poll (`getStatus`).
sealed class ProviderObservationOutcome {
  const ProviderObservationOutcome({
    this.responseReference,
    this.providerReference,
  });

  final String? responseReference;
  final String? providerReference;
}

final class ProviderObservationFound extends ProviderObservationOutcome {
  const ProviderObservationFound({
    required this.providerStateCode,
    required this.safeDescription,
    required this.observedAt,
    required this.detailsSnapshot,
    super.responseReference,
    super.providerReference,
  });

  final String providerStateCode;
  final String safeDescription;
  final DateTime observedAt;
  final Map<String, Object?> detailsSnapshot;
}

final class ProviderObservationNotFound extends ProviderObservationOutcome {
  const ProviderObservationNotFound({
    required this.providerStateCode,
    required this.safeDescription,
    required this.observedAt,
    super.responseReference,
    super.providerReference,
  });

  final String providerStateCode;
  final String safeDescription;
  final DateTime observedAt;
}

final class ProviderObservationMismatch extends ProviderObservationOutcome {
  const ProviderObservationMismatch({
    required this.providerStateCode,
    required this.safeDescription,
    required this.observedAt,
    super.responseReference,
    super.providerReference,
  });

  final String providerStateCode;
  final String safeDescription;
  final DateTime observedAt;
}

final class ProviderObservationAmbiguous extends ProviderObservationOutcome {
  const ProviderObservationAmbiguous({
    required this.safeErrorCode,
    super.responseReference,
  });

  final String safeErrorCode;
}
