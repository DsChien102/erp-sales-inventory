sealed class DeliveryObservationOutcome {
  const DeliveryObservationOutcome();
}

final class DeliveryObservedSucceeded extends DeliveryObservationOutcome {
  const DeliveryObservedSucceeded({this.providerReference});

  final String? providerReference;
}

final class DeliveryObservedDefiniteFailure extends DeliveryObservationOutcome {
  const DeliveryObservedDefiniteFailure(this.safeCode);

  final String safeCode;
}

final class DeliveryObservationUndetermined extends DeliveryObservationOutcome {
  const DeliveryObservationUndetermined(this.safeCode);

  final String safeCode;
}

final class DeliveryObservationUnsupported extends DeliveryObservationOutcome {
  const DeliveryObservationUnsupported();
}
