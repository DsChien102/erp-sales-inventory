enum ProviderInteractionOutcome {
  succeeded,
  definiteFailure,
  timeout,
  unavailable,
  notFound,
  mismatch,
  checkRequired;

  static ProviderInteractionOutcome fromWire(String value) {
    switch (value) {
      case 'SUCCEEDED':
        return succeeded;
      case 'DEFINITE_FAILURE':
        return definiteFailure;
      case 'TIMEOUT':
        return timeout;
      case 'UNAVAILABLE':
        return unavailable;
      case 'NOT_FOUND':
        return notFound;
      case 'MISMATCH':
        return mismatch;
      case 'CHECK_REQUIRED':
        return checkRequired;
      default:
        throw ArgumentError('Unknown ProviderInteractionOutcome: $value');
    }
  }

  String toWire() => switch (this) {
    succeeded => 'SUCCEEDED',
    definiteFailure => 'DEFINITE_FAILURE',
    timeout => 'TIMEOUT',
    unavailable => 'UNAVAILABLE',
    notFound => 'NOT_FOUND',
    mismatch => 'MISMATCH',
    checkRequired => 'CHECK_REQUIRED',
  };
}
