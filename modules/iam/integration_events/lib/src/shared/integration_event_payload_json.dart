/// IAM integration-event payload helpers for [json_serializable].
library;

/// Validates envelope `event_version` before deserialization.
void assertIntegrationEventEnvelopeVersion(
  Map<String, dynamic> json,
  int expected, {
  required String eventName,
}) {
  final versionRaw = json['event_version'];
  if (versionRaw is! int && versionRaw is! num) {
    throw FormatException('$eventName missing event_version', json);
  }
  final eventVersion = (versionRaw as num).toInt();
  if (eventVersion != expected) {
    throw FormatException(
      'Unsupported event_version=$eventVersion (expected $expected)',
      json,
    );
  }
}
