/// Delivery lifecycle status for UI / projection (independent of invitation status).
enum EmailDeliveryStatus {
  queued('queued'),
  sent('sent'),
  failed('failed'),
  bounced('bounced');

  const EmailDeliveryStatus(this.wireValue);

  final String wireValue;

  static EmailDeliveryStatus fromWire(String value) {
    for (final status in EmailDeliveryStatus.values) {
      if (status.wireValue == value) {
        return status;
      }
    }
    throw ArgumentError.value(value, 'value', 'Unknown email delivery status');
  }
}
