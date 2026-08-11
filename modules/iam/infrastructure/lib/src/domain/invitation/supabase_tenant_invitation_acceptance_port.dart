import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/iam_blocked_error_mapper.dart';
import '../membership/supabase_tenant_membership_read_gateway.dart';
import 'supabase_tenant_invitation_command_gateway.dart';

final class SupabaseTenantInvitationAcceptancePort
    implements ITenantInvitationAcceptancePort {
  SupabaseTenantInvitationAcceptancePort({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<InvitationTokenInspectionDto> inspectToken(String token) async {
    try {
      final result = await _rpcClient.callMap(
        'inspect_invitation_token',
        params: <String, dynamic>{'p_token': token},
      );
      return InvitationTokenInspectionDto(
        tenantId: result['tenant_id'] as String,
        tenantName: (result['tenant_name'] as String?) ?? '',
        inviteeEmail: result['invitee_email'] as String,
        initialRoleId: result['initial_role_id'] as String,
        initialRoleLabel: (result['initial_role_label'] as String?) ?? '',
        expiresAt: DateTime.parse(result['expires_at'].toString()).toUtc(),
        accountExists: result['account_exists'] as bool? ?? false,
      );
    } on RpcException catch (error) {
      throw mapIamBlockedRpcError(error);
    }
  }

  @override
  Future<TenantMemberDetailDto> acceptInvitation({
    required String token,
    required String idempotencyKey,
  }) async {
    try {
      final result = await _rpcClient.callMap(
        'accept_invitation',
        params: <String, dynamic>{
          'p_token': token,
          'p_idempotency_key': idempotencyKey,
        },
      );
      return mapTenantMemberDetail(result);
    } on RpcException catch (error) {
      throw mapIamBlockedRpcError(error);
    }
  }

  @override
  Future<InvitationDetailDto> declineInvitation({
    required String token,
    required String idempotencyKey,
  }) async {
    try {
      final result = await _rpcClient.callMap(
        'decline_invitation',
        params: <String, dynamic>{
          'p_token': token,
          'p_idempotency_key': idempotencyKey,
        },
      );
      return mapInvitationDetail(result);
    } on RpcException catch (error) {
      throw mapIamBlockedRpcError(error);
    }
  }
}
