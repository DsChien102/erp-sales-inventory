import 'package:vet45_shared_infrastructure/infrastructure.dart';

/// Partner/customer display-name normalization for integration-event payloads.
Map<String, dynamic> normalizeCustomerDisplayNameJson(Map<String, dynamic> json) {
  final map = normalizeIntegrationEventJson(json);
  map['display_name'] ??= map['name'] ?? '';
  return map;
}
