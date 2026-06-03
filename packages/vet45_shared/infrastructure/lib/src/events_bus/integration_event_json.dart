import 'package:json_annotation/json_annotation.dart';

import 'integration_event.dart';

/// Normalizes inbox/outbox JSON before [json_serializable] deserialization.
///
/// - Maps legacy `idempotency_key` to `id`
/// - Ensures `occurred_on` exists (defaults to now UTC)
Map<String, dynamic> normalizeIntegrationEventJson(Map<String, dynamic> json) {
  final map = Map<String, dynamic>.from(json);
  final id = map['id'] as String? ?? map['idempotency_key'] as String?;
  if (id == null || id.isEmpty) {
    throw FormatException('Integration event payload requires id or idempotency_key');
  }
  map['id'] = id;
  map.putIfAbsent(
    'occurred_on',
    () => DateTime.now().toUtc().toIso8601String(),
  );
  return map;
}

/// Serializes [DateTime] as UTC ISO-8601 for integration event payloads.
final class DateTimeUtcConverter implements JsonConverter<DateTime, String> {
  const DateTimeUtcConverter();

  @override
  DateTime fromJson(String json) => DateTime.parse(json).toUtc();

  @override
  String toJson(DateTime object) => object.toUtc().toIso8601String();
}

/// Reads integration event id from JSON (for `@JsonKey(fromJson: ...)`).
String integrationEventIdFromJson(Object? json) {
  if (json is! String || json.isEmpty) {
    throw FormatException('Integration event payload requires id or idempotency_key');
  }
  return json;
}

/// Reads integration event occurred-on from JSON (for `@JsonKey(fromJson: ...)`).
DateTime integrationEventOccurredOnFromJson(Object? json) {
  if (json is String && json.isNotEmpty) {
    return DateTime.parse(json).toUtc();
  }
  if (json is DateTime) {
    return json.toUtc();
  }
  return DateTime.now().toUtc();
}

/// Reads integration event id from a JSON map (for manual deserialization).
String integrationEventIdFromMap(Map<String, dynamic> json) {
  final id = json['id'] as String? ?? json['idempotency_key'] as String?;
  if (id == null || id.isEmpty) {
    throw FormatException('Integration event payload requires id or idempotency_key');
  }
  return id;
}

/// Reads integration event occurred-on from a JSON map (for manual deserialization).
DateTime integrationEventOccurredOnFromMap(Map<String, dynamic> json) =>
    IntegrationEvent.resolveOccurredOn(json);
