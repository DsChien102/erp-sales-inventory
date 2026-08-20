import 'package:json_annotation/json_annotation.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../shared/integration_event_payload_json.dart';

part 'membership_deactivated_integration_event.g.dart';

/// Integration event published when a tenant membership is deactivated.
///
/// Envelope v1 — outbox payload produced by `iam.deactivate_membership` RPC
/// (via `iam._mutate_membership_status`).
///
/// Consumers (inbox handlers) should use [userId] to clear or rotate the
/// `iam.user_preferences.last_selected_tenant_id` for the affected user so
/// that the next login does not attempt to restore an inactive tenant.
final class MembershipDeactivatedIntegrationEvent extends TenantScopedIntegrationEvent {
  MembershipDeactivatedIntegrationEvent({
    required super.id,
    required super.occurredOn,
    required super.tenantId,
    required this.membershipId,
    required this.userId,
    required this.version,
    required this.actorUserId,
    this.eventVersion = 1,
  }) : super(eventType: type);

  static const type = 'iam.membership.deactivated';
  static const currentEventVersion = 1;

  final String membershipId;
  final String userId;
  final int version;
  final String actorUserId;
  final int eventVersion;

  @override
  Map<String, dynamic> toPayload() {
    final payload = _MembershipDeactivatedIntegrationEventPayload.fromEvent(this);
    return payload.toJson()..['status'] = 'inactive';
  }

  factory MembershipDeactivatedIntegrationEvent.fromPayload(
    Map<String, dynamic> json,
  ) {
    final normalized = normalizeIntegrationEventJson(json);
    assertIntegrationEventEnvelopeVersion(
      normalized,
      currentEventVersion,
      eventName: 'MembershipDeactivatedIntegrationEvent',
    );
    return _MembershipDeactivatedIntegrationEventPayload.fromJson(normalized).toEvent();
  }
}

@JsonSerializable(
  fieldRename: FieldRename.snake,
  explicitToJson: true,
  includeIfNull: false,
  createToJson: true,
  createFactory: true,
)
final class _MembershipDeactivatedIntegrationEventPayload {
  const _MembershipDeactivatedIntegrationEventPayload({
    required this.id,
    required this.occurredOn,
    required this.tenantId,
    required this.membershipId,
    required this.userId,
    required this.version,
    required this.actorUserId,
    required this.eventVersion,
  });

  factory _MembershipDeactivatedIntegrationEventPayload.fromEvent(
    MembershipDeactivatedIntegrationEvent event,
  ) {
    return _MembershipDeactivatedIntegrationEventPayload(
      id: event.id,
      occurredOn: event.occurredOn,
      tenantId: event.tenantId,
      membershipId: event.membershipId,
      userId: event.userId,
      version: event.version,
      actorUserId: event.actorUserId,
      eventVersion: event.eventVersion,
    );
  }

  @JsonKey(fromJson: integrationEventIdFromJson)
  final String id;

  @DateTimeUtcConverter()
  final DateTime occurredOn;

  @JsonKey(fromJson: _membershipTenantIdFromJson)
  final String tenantId;

  @JsonKey(fromJson: _membershipIdFromJson)
  final String membershipId;

  @JsonKey(fromJson: _userIdFromJson)
  final String userId;

  @JsonKey(defaultValue: 1)
  final int version;

  @JsonKey(fromJson: _actorUserIdFromJson)
  final String actorUserId;

  @JsonKey(defaultValue: 1)
  final int eventVersion;

  MembershipDeactivatedIntegrationEvent toEvent() {
    return MembershipDeactivatedIntegrationEvent(
      id: id,
      occurredOn: occurredOn,
      tenantId: tenantId,
      membershipId: membershipId,
      userId: userId,
      version: version,
      actorUserId: actorUserId,
      eventVersion: eventVersion,
    );
  }

  factory _MembershipDeactivatedIntegrationEventPayload.fromJson(
    Map<String, dynamic> json,
  ) => _$MembershipDeactivatedIntegrationEventPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$MembershipDeactivatedIntegrationEventPayloadToJson(this);
}

String _req(Object? json, String fieldName) {
  if (json is! String || json.trim().isEmpty) {
    throw FormatException('$MembershipDeactivatedIntegrationEvent missing $fieldName');
  }
  return json;
}

String _membershipTenantIdFromJson(Object? json) => _req(json, 'tenant_id');
String _membershipIdFromJson(Object? json) => _req(json, 'membership_id');
String _userIdFromJson(Object? json) => _req(json, 'user_id');
String _actorUserIdFromJson(Object? json) => _req(json, 'actor_user_id');
