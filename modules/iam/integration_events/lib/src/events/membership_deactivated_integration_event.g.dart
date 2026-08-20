// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'membership_deactivated_integration_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MembershipDeactivatedIntegrationEventPayload
_$MembershipDeactivatedIntegrationEventPayloadFromJson(
  Map<String, dynamic> json,
) => _MembershipDeactivatedIntegrationEventPayload(
  id: integrationEventIdFromJson(json['id']),
  occurredOn: const DateTimeUtcConverter().fromJson(
    json['occurred_on'] as String,
  ),
  tenantId: _membershipTenantIdFromJson(json['tenant_id']),
  membershipId: _membershipIdFromJson(json['membership_id']),
  userId: _userIdFromJson(json['user_id']),
  version: (json['version'] as num?)?.toInt() ?? 1,
  actorUserId: _actorUserIdFromJson(json['actor_user_id']),
  eventVersion: (json['event_version'] as num?)?.toInt() ?? 1,
);

Map<String, dynamic> _$MembershipDeactivatedIntegrationEventPayloadToJson(
  _MembershipDeactivatedIntegrationEventPayload instance,
) => <String, dynamic>{
  'id': instance.id,
  'occurred_on': const DateTimeUtcConverter().toJson(instance.occurredOn),
  'tenant_id': instance.tenantId,
  'membership_id': instance.membershipId,
  'user_id': instance.userId,
  'version': instance.version,
  'actor_user_id': instance.actorUserId,
  'event_version': instance.eventVersion,
};
