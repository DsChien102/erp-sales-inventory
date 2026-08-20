import 'package:json_annotation/json_annotation.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../shared/email_delivery_constants.dart';
import '../shared/email_delivery_refs_json.dart';
import '../shared/integration_event_payload_json.dart';
import '../shared/platform_messaging_tenant_id_json.dart';

part 'email_delivery_requested_integration_event.g.dart';

/// Integration event: email delivery requested (outbox → inbox self-consume).
///
/// Envelope v1 — see TH-01 `07-api-contracts.md` §S-NOTIFY.
///
/// Platform-scoped mail uses `tenant_id: null` in the payload. Messaging
/// partition rows still use [platformMessagingTenantId] because outbox/inbox
/// tables require a non-null tenant key.
final class EmailDeliveryRequestedIntegrationEvent extends TenantScopedIntegrationEvent {
  EmailDeliveryRequestedIntegrationEvent({
    required super.id,
    required super.occurredOn,
    required super.tenantId,
    required this.templateId,
    required this.toEmail,
    required this.correlationId,
    required this.outcomeId,
    this.locale = 'vi',
    this.refs = const <String, String>{},
    this.secretPayloadCiphertext,
    this.eventVersion = 1,
  }) : super(eventType: type);

  static const type = 'iam.email.delivery_requested';
  static const currentEventVersion = 1;

  /// Outbox/inbox partition key for platform-scoped mail (not a domain tenant).
  static const platformMessagingTenantId =
      EmailDeliveryIntegrationEventConstants.platformMessagingTenantId;

  final String templateId;
  final String toEmail;
  final String correlationId;
  final String outcomeId;
  final String locale;
  final Map<String, String> refs;

  /// Optional encrypted transient secret channel (key outside DB).
  /// Raw tokens must never appear in [refs] or normal JSON fields.
  final String? secretPayloadCiphertext;

  final int eventVersion;

  bool get isPlatformScoped => tenantId == platformMessagingTenantId;

  @override
  Map<String, dynamic> toPayload() =>
      _EmailDeliveryRequestedIntegrationEventPayload.fromEvent(this).toJson();

  factory EmailDeliveryRequestedIntegrationEvent.fromPayload(
    Map<String, dynamic> json,
  ) {
    final normalized = normalizeIntegrationEventJson(json);
    assertIntegrationEventEnvelopeVersion(
      normalized,
      currentEventVersion,
      eventName: '$EmailDeliveryRequestedIntegrationEvent',
    );
    return _EmailDeliveryRequestedIntegrationEventPayload.fromJson(normalized).toEvent();
  }
}

@JsonSerializable(
  fieldRename: FieldRename.snake,
  explicitToJson: true,
  includeIfNull: false,
)
final class _EmailDeliveryRequestedIntegrationEventPayload {
  const _EmailDeliveryRequestedIntegrationEventPayload({
    required this.id,
    required this.occurredOn,
    required this.tenantId,
    required this.templateId,
    required this.toEmail,
    required this.correlationId,
    required this.outcomeId,
    required this.locale,
    required this.refs,
    required this.secretPayloadCiphertext,
    required this.eventVersion,
  });

  factory _EmailDeliveryRequestedIntegrationEventPayload.fromEvent(
    EmailDeliveryRequestedIntegrationEvent event,
  ) {
    return _EmailDeliveryRequestedIntegrationEventPayload(
      id: event.id,
      occurredOn: event.occurredOn,
      tenantId: event.tenantId,
      templateId: event.templateId,
      toEmail: event.toEmail,
      correlationId: event.correlationId,
      outcomeId: event.outcomeId,
      locale: event.locale,
      refs: event.refs,
      secretPayloadCiphertext: event.secretPayloadCiphertext,
      eventVersion: event.eventVersion,
    );
  }

  @JsonKey(fromJson: integrationEventIdFromJson)
  final String id;

  @DateTimeUtcConverter()
  final DateTime occurredOn;

  @PlatformMessagingTenantIdConverter()
  @JsonKey(name: 'tenant_id')
  final String tenantId;

  @JsonKey(fromJson: _templateIdFromJson)
  final String templateId;

  @JsonKey(fromJson: _toEmailFromJson)
  final String toEmail;

  @JsonKey(fromJson: _correlationIdFromJson)
  final String correlationId;

  @JsonKey(fromJson: _outcomeIdFromJson)
  final String outcomeId;

  @JsonKey(defaultValue: 'vi')
  final String locale;

  @JsonKey(fromJson: emailDeliveryRefsFromJson)
  final Map<String, String> refs;

  final String? secretPayloadCiphertext;

  @JsonKey(defaultValue: 1)
  final int eventVersion;

  EmailDeliveryRequestedIntegrationEvent toEvent() {
    return EmailDeliveryRequestedIntegrationEvent(
      id: id,
      occurredOn: occurredOn,
      tenantId: tenantId,
      templateId: templateId,
      toEmail: toEmail,
      correlationId: correlationId,
      outcomeId: outcomeId,
      locale: locale,
      refs: refs,
      secretPayloadCiphertext: secretPayloadCiphertext,
      eventVersion: eventVersion,
    );
  }

  factory _EmailDeliveryRequestedIntegrationEventPayload.fromJson(
    Map<String, dynamic> json,
  ) => _$EmailDeliveryRequestedIntegrationEventPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$EmailDeliveryRequestedIntegrationEventPayloadToJson(this);
}

String _required(Object? json, String fieldName) {
  if (json is! String || json.trim().isEmpty) {
    throw FormatException('$EmailDeliveryRequestedIntegrationEvent missing $fieldName');
  }
  return json;
}

String _templateIdFromJson(Object? json) => _required(json, 'template_id');
String _toEmailFromJson(Object? json) => _required(json, 'to_email');
String _correlationIdFromJson(Object? json) => _required(json, 'correlation_id');
String _outcomeIdFromJson(Object? json) => _required(json, 'outcome_id');
