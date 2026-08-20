// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'email_delivery_requested_integration_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EmailDeliveryRequestedIntegrationEventPayload
_$EmailDeliveryRequestedIntegrationEventPayloadFromJson(
  Map<String, dynamic> json,
) => _EmailDeliveryRequestedIntegrationEventPayload(
  id: integrationEventIdFromJson(json['id']),
  occurredOn: const DateTimeUtcConverter().fromJson(
    json['occurred_on'] as String,
  ),
  tenantId: const PlatformMessagingTenantIdConverter().fromJson(
    json['tenant_id'],
  ),
  templateId: _templateIdFromJson(json['template_id']),
  toEmail: _toEmailFromJson(json['to_email']),
  correlationId: _correlationIdFromJson(json['correlation_id']),
  outcomeId: _outcomeIdFromJson(json['outcome_id']),
  locale: json['locale'] as String? ?? 'vi',
  refs: emailDeliveryRefsFromJson(json['refs']),
  secretPayloadCiphertext: json['secret_payload_ciphertext'] as String?,
  eventVersion: (json['event_version'] as num?)?.toInt() ?? 1,
);

Map<String, dynamic> _$EmailDeliveryRequestedIntegrationEventPayloadToJson(
  _EmailDeliveryRequestedIntegrationEventPayload instance,
) => <String, dynamic>{
  'id': instance.id,
  'occurred_on': const DateTimeUtcConverter().toJson(instance.occurredOn),
  'tenant_id': ?const PlatformMessagingTenantIdConverter().toJson(
    instance.tenantId,
  ),
  'template_id': instance.templateId,
  'to_email': instance.toEmail,
  'correlation_id': instance.correlationId,
  'outcome_id': instance.outcomeId,
  'locale': instance.locale,
  'refs': instance.refs,
  'secret_payload_ciphertext': ?instance.secretPayloadCiphertext,
  'event_version': instance.eventVersion,
};
