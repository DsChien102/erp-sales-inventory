import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/iam/data/models/tenant_invitation.dart';
import 'package:erp/features/iam/data/models/tenant_member.dart';

import 'models/invitation_token_inspection.dart';

/// RPC nhận / từ chối lời mời. Không cần tenant đang chọn.
class InvitationAcceptanceRepository {
  InvitationAcceptanceRepository({required SupabaseRpc rpc}) : _rpc = rpc;

  final SupabaseRpc _rpc;

  Future<InvitationTokenInspection> inspect(String token) async {
    final result = await _rpc.call(
      'iam',
      'inspect_invitation_token',
      params: <String, dynamic>{'p_token': token},
    );
    return InvitationTokenInspection.fromJson(_asMap(result));
  }

  Future<TenantMemberDetail> accept(
    String token, {
    required String idempotencyKey,
  }) async {
    final result = await _rpc.call(
      'iam',
      'accept_invitation',
      params: <String, dynamic>{
        'p_token': token,
        'p_idempotency_key': idempotencyKey,
      },
    );
    return TenantMemberDetail.fromJson(_asMap(result));
  }

  Future<TenantInvitationDetail> decline(
    String token, {
    required String idempotencyKey,
  }) async {
    final result = await _rpc.call(
      'iam',
      'decline_invitation',
      params: <String, dynamic>{
        'p_token': token,
        'p_idempotency_key': idempotencyKey,
      },
    );
    return TenantInvitationDetail.fromJson(_asMap(result));
  }
}

Map<String, dynamic> _asMap(dynamic result) {
  if (result is Map) return Map<String, dynamic>.from(result);
  if (result is List && result.isNotEmpty && result.first is Map) {
    return Map<String, dynamic>.from(result.first as Map);
  }
  return const {};
}
