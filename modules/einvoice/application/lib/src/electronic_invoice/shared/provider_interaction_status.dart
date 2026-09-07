enum ProviderInteractionStatus {
  started,
  completed;

  static ProviderInteractionStatus fromWire(String value) {
    switch (value) {
      case 'STARTED':
        return started;
      case 'COMPLETED':
        return completed;
      default:
        throw ArgumentError('Unknown ProviderInteractionStatus: $value');
    }
  }

  String toWire() => switch (this) {
    started => 'STARTED',
    completed => 'COMPLETED',
  };
}
