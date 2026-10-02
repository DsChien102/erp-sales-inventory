/// Identity-only parser shared by dispatch and dead-letter handling.
/// Supports legacy SQL camelCase without weakening the shared kernel.
final class DeliveryCommandPayload {
  DeliveryCommandPayload.fromJson(Map<String, dynamic> json)
    : tenantId = _identity(json, 'tenant_id', 'tenantId'),
      deliveryId = _identity(json, 'delivery_id', 'deliveryId'),
      retryCount = _retryCount(json);

  final String tenantId;
  final String deliveryId;
  final int retryCount;

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

  static int _retryCount(Map<String, dynamic> json) {
    const key = 'retry_count';
    const legacy = 'retryCount';
    if (json.containsKey(key) && json.containsKey(legacy) && json[key] != json[legacy]) {
      throw FormatException('Conflicting delivery identity aliases: $key');
    }
    final value = json.containsKey(key) ? json[key] : json[legacy];
    if (value is! int || value < 0 || value > 2) {
      throw FormatException('Invalid or missing delivery identity: $key');
    }
    return value;
  }
}
