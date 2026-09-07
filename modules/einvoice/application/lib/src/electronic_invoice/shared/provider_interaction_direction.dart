enum ProviderInteractionDirection {
  outbound,
  inboundCallback;

  static ProviderInteractionDirection fromWire(String value) {
    switch (value) {
      case 'OUTBOUND':
        return outbound;
      case 'INBOUND_CALLBACK':
        return inboundCallback;
      default:
        throw ArgumentError('Unknown ProviderInteractionDirection: $value');
    }
  }

  String toWire() => switch (this) {
    outbound => 'OUTBOUND',
    inboundCallback => 'INBOUND_CALLBACK',
  };
}
