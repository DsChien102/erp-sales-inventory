sealed class DeliveryProviderOutcome {
  const DeliveryProviderOutcome();
}

final class DeliveryProviderSucceeded extends DeliveryProviderOutcome {
  const DeliveryProviderSucceeded({this.providerReference});

  final String? providerReference;
}

final class DeliveryProviderDefiniteFailure extends DeliveryProviderOutcome {
  const DeliveryProviderDefiniteFailure(this.safeErrorCode);

  final String safeErrorCode;
}

final class DeliveryProviderRetryableFailure extends DeliveryProviderOutcome {
  const DeliveryProviderRetryableFailure(this.safeErrorCode);

  final String safeErrorCode;
}

final class DeliveryProviderUndetermined extends DeliveryProviderOutcome {
  const DeliveryProviderUndetermined(this.safeErrorCode);

  final String safeErrorCode;
}
