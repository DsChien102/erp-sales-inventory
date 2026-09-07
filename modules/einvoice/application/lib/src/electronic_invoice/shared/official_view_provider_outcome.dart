/// Closed provider outcome for official invoice view fetch.
sealed class OfficialViewProviderOutcome {
  const OfficialViewProviderOutcome({
    this.responseReference,
    this.providerReference,
  });

  final String? responseReference;
  final String? providerReference;
}

final class OfficialViewProviderSuccess extends OfficialViewProviderOutcome {
  const OfficialViewProviderSuccess({
    required this.viewerUrl,
    required this.expiresAt,
    super.responseReference,
    super.providerReference,
  });

  final String viewerUrl;
  final DateTime expiresAt;
}

final class OfficialViewProviderCheckRequired extends OfficialViewProviderOutcome {
  const OfficialViewProviderCheckRequired({
    required this.safeErrorCode,
    super.responseReference,
    super.providerReference,
  });

  final String safeErrorCode;
}

final class OfficialViewProviderDefiniteFailure extends OfficialViewProviderOutcome {
  const OfficialViewProviderDefiniteFailure({
    required this.failureCode,
    this.failureMessage,
    super.responseReference,
    super.providerReference,
  });

  final String failureCode;
  final String? failureMessage;
}

final class OfficialViewProviderAmbiguous extends OfficialViewProviderOutcome {
  const OfficialViewProviderAmbiguous({
    required this.safeErrorCode,
    super.responseReference,
  });

  final String safeErrorCode;
}
