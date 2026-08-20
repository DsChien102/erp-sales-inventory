import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/iam_blocked_error_mapper.dart';

final class SupabaseTenantMembershipReadGateway
    implements ITenantMembershipReadGateway {
  SupabaseTenantMembershipReadGateway({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<TenantMemberDetailDto?> getMember({
    required String tenantId,
    required String membershipId,
  }) async {
    try {
      final result = await _rpcClient.callMap(
        'get_tenant_member',
        params: <String, dynamic>{
          'p_tenant_id': tenantId,
          'p_membership_id': membershipId,
        },
      );
      if (result.isEmpty) {
        return null;
      }
      return mapTenantMemberDetail(result);
    } on RpcException catch (error) {
      throw mapIamBlockedRpcError(error);
    }
  }
}

TenantMemberDetailDto mapTenantMemberDetail(Map<String, dynamic> row) {
  return TenantMemberDetailDto(
    membershipId: row['membership_id'] as String,
    tenantId: row['tenant_id'] as String,
    userId: row['user_id'] as String,
    displayName: row['display_name'] as String?,
    email: row['email'] as String?,
    role: row['role'] as String,
    roleLabel: row['role_label'] as String?,
    isOwner: row['is_owner'] as bool? ?? false,
    isSoleOwner: row['is_sole_owner'] as bool? ?? false,
    status: _mapStatus(row['status'] as String?),
    version: (row['version'] as num?)?.toInt() ?? 1,
    joinedAt: DateTime.parse(row['joined_at'] as String),
    lastActivityAt: row['last_activity_at'] == null
        ? null
        : DateTime.parse(row['last_activity_at'] as String),
    statusChangedAt: row['status_changed_at'] == null
        ? null
        : DateTime.parse(row['status_changed_at'] as String),
    removedAt: row['removed_at'] == null
        ? null
        : DateTime.parse(row['removed_at'] as String),
  );
}

MembershipStatus _mapStatus(String? raw) {
  return switch (raw) {
    'inactive' => MembershipStatus.inactive,
    'removed' => MembershipStatus.removed,
    _ => MembershipStatus.active,
  };
}
