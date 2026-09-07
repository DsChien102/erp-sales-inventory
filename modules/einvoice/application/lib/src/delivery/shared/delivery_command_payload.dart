/// Identity-only parser shared by dispatch and dead-letter handling.
/// Supports legacy SQL camelCase without weakening the shared kernel.
final class DeliveryCommandPayload {
  DeliveryCommandPayload.fromJson(Map<String, dynamic> json)
    : tenantId = _identity(json, 'tenant_id', 'tenantId'),
      deliveryId = _identity(json, 'delivery_id', 'deliveryId'),
      attemptId = _identity(json, 'attempt_id', 'attemptId');

  final String tenantId;
  final String deliveryId;
  final String attemptId;

  static String _identity(Map<String, dynamic> json, String key, String legacy) {
    if (json.containsKey(key) && json.containsKey(legacy) && json[key] != json[legacy]) {
      throw FormatException('Conflicting delivery identity aliases: $key');
    }
    final value = json.containsKey(key) ? json[key] : json[legacy];
    if (value is! String || value.trim().isEmpty || value != value.trim()) {
      throw FormatException('Invalid or missing delivery identity: $key');
    }
    return value;
  }
}
