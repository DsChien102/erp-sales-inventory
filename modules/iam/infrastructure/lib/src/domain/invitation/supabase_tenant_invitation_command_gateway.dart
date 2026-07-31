import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/iam_blocked_error_mapper.dart';

final class SupabaseTenantInvitationCommandGateway
    implements ITenantInvitationCommandGateway {
  SupabaseTenantInvitationCommandGateway({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<InvitationDetailDto> createInvitation({
    required String tenantId,
    required String inviteeEmail,
    required String initialRoleId,
    required String idempotencyKey,
  }) {
    return _call(
      'create_tenant_invitation',
      <String, dynamic>{
        'p_tenant_id': tenantId,
        'p_invitee_email': inviteeEmail,
        'p_initial_role_id': initialRoleId,
        'p_idempotency_key': idempotencyKey,
      },
    );
  }

  @override
  Future<InvitationDetailDto> resendInvitation({
    required String tenantId,
    required String invitationId,
    required int expectedVersion,
    required String idempotencyKey,
  }) {
    return _call(
      'resend_tenant_invitation',
      <String, dynamic>{
        'p_tenant_id': tenantId,
        'p_invitation_id': invitationId,
        'p_expected_version': expectedVersion,
        'p_idempotency_key': idempotencyKey,
      },
    );
  }

  @override
  Future<InvitationDetailDto> revokeInvitation({
    required String tenantId,
    required String invitationId,
    required int expectedVersion,
    required String reason,
    required String idempotencyKey,
  }) {
    return _call(
      'revoke_tenant_invitation',
      <String, dynamic>{
        'p_tenant_id': tenantId,
        'p_invitation_id': invitationId,
        'p_expected_version': expectedVersion,
        'p_reason': reason,
        'p_idempotency_key': idempotencyKey,
      },
    );
  }

  Future<InvitationDetailDto> _call(
    String rpc,
    Map<String, dynamic> params,
  ) async {
    try {
      final result = await _rpcClient.callMap(rpc, params: params);
      return mapInvitationDetail(result);
    } on RpcException catch (error) {
      throw mapIamBlockedRpcError(error);
    }
  }
}

InvitationDetailDto mapInvitationDetail(Map<String, dynamic> row) {
  DateTime? parseTs(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value.toUtc();
    return DateTime.parse(value.toString()).toUtc();
  }

  return InvitationDetailDto(
    invitationId: row['invitation_id'] as String,
    inviteeEmail: row['invitee_email'] as String,
    initialRoleId: row['initial_role_id'] as String,
    initialRoleLabel: (row['initial_role_label'] as String?) ?? '',
    status: row['status'] as String,
    expiresAt: parseTs(row['expires_at'])!,
    deliveryStatus: (row['delivery_status'] as String?) ?? 'queued',
    deliveryCorrelationId: (row['delivery_correlation_id'] as String?) ?? '',
    version: (row['version'] as num?)?.toInt() ?? 1,
    createdAt: parseTs(row['created_at'])!,
    createdBy: (row['created_by'] as String?) ?? '',
    lastSentAt: parseTs(row['last_sent_at']),
    revokedAt: parseTs(row['revoked_at']),
    declinedAt: parseTs(row['declined_at']),
  );
}
