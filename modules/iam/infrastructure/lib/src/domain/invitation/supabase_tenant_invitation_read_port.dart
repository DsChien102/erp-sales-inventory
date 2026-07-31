import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/iam_blocked_error_mapper.dart';

final class SupabaseTenantInvitationReadPort
    implements ITenantInvitationReadPort {
  SupabaseTenantInvitationReadPort({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<CursorPageDto<InvitationSummaryDto>> listInvitations({
    required String tenantId,
    String? search,
    String? status,
    String? cursor,
    int limit = 20,
  }) async {
    try {
      final page = await _rpcClient.callMap(
        'list_tenant_invitations',
        params: <String, dynamic>{
          'p_tenant_id': tenantId,
          if (search != null) 'p_search': search,
          if (status != null) 'p_status': status,
          if (cursor != null) 'p_cursor': cursor,
          'p_limit': limit,
        },
      );
      final rows = (page['items'] as List<dynamic>? ?? const []);
      return CursorPageDto<InvitationSummaryDto>(
        items: rows
            .map((raw) => _mapSummary(Map<String, dynamic>.from(raw as Map)))
            .toList(growable: false),
        nextCursor: page['next_cursor'] as String?,
      );
    } on RpcException catch (error) {
      throw mapIamBlockedRpcError(error);
    }
  }

  @override
  Future<InvitationDetailDto?> getInvitation({
    required String tenantId,
    required String invitationId,
  }) async {
    try {
      final result = await _rpcClient.callMap(
        'get_tenant_invitation',
        params: <String, dynamic>{
          'p_tenant_id': tenantId,
          'p_invitation_id': invitationId,
        },
      );
      if (result.isEmpty) {
        return null;
      }
      return _mapDetail(result);
    } on RpcException catch (error) {
      throw mapIamBlockedRpcError(error);
    }
  }

  InvitationSummaryDto _mapSummary(Map<String, dynamic> row) {
    return InvitationSummaryDto(
      invitationId: row['invitation_id'] as String,
      inviteeEmail: row['invitee_email'] as String,
      initialRoleId: row['initial_role_id'] as String,
      initialRoleLabel: (row['initial_role_label'] as String?) ?? '',
      status: row['status'] as String,
      expiresAt: _parseTs(row['expires_at'])!,
      deliveryStatus: (row['delivery_status'] as String?) ?? 'unknown',
      deliveryCorrelationId: (row['delivery_correlation_id'] as String?) ?? '',
      version: (row['version'] as num?)?.toInt() ?? 1,
    );
  }

  InvitationDetailDto _mapDetail(Map<String, dynamic> row) {
    return InvitationDetailDto(
      invitationId: row['invitation_id'] as String,
      inviteeEmail: row['invitee_email'] as String,
      initialRoleId: row['initial_role_id'] as String,
      initialRoleLabel: (row['initial_role_label'] as String?) ?? '',
      status: row['status'] as String,
      expiresAt: _parseTs(row['expires_at'])!,
      deliveryStatus: (row['delivery_status'] as String?) ?? 'unknown',
      deliveryCorrelationId: (row['delivery_correlation_id'] as String?) ?? '',
      version: (row['version'] as num?)?.toInt() ?? 1,
      createdAt: _parseTs(row['created_at'])!,
      createdBy: (row['created_by'] as String?) ?? '',
      lastSentAt: _parseTs(row['last_sent_at']),
      revokedAt: _parseTs(row['revoked_at']),
      declinedAt: _parseTs(row['declined_at']),
    );
  }

  DateTime? _parseTs(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value.toUtc();
    return DateTime.parse(value.toString()).toUtc();
  }
}
