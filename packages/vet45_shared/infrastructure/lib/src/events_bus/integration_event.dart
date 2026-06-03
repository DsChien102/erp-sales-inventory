import 'integration_event_json.dart';

abstract class IntegrationEvent {
  const IntegrationEvent({
    required this.id,
    required this.occurredOn,
    required this.eventType,
  });

  final String id;
  final DateTime occurredOn;
  final String eventType;

  /// First segment of [eventType] — used as inbox `source_module`.
  String get sourceModule => eventType.split('.').first;

  static DateTime resolveOccurredOn(Map<String, dynamic> json) =>
      integrationEventOccurredOnFromMap(json);
}
