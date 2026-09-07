import 'package:uuid/uuid.dart';

/// Stable UUIDv5 business key for automatic initial invoice delivery.
abstract final class AutoDeliveryIdempotencyKey {
  static const String namespace = '9d4c1d80-8d2c-5f2a-8b86-ff34c8a8e275';

  /// Seed format: `<tenantId>|<electronicInvoiceId>|auto_initial`.
  static String generate({
    required String tenantId,
    required String electronicInvoiceId,
  }) {
    final seed = '$tenantId|$electronicInvoiceId|auto_initial';
    return const Uuid().v5(namespace, seed);
  }
}
