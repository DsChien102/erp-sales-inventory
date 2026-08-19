import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/iam_error_mapper.dart';

final class SupabaseIamAccessGateway implements IIamAccessGateway {
  SupabaseIamAccessGateway({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<PrincipalAccessDto?> getSessionContext({String? tenantId}) async {
    try {
      final result = await _rpcClient.callMap(
        'get_session_context',
        params: tenantId == null ? null : <String, dynamic>{'p_tenant_id': tenantId},
      );

      if (result.isEmpty) {
        return null;
      }

      return _mapPrincipalAccess(result);
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
    }
  }

  @override
  Future<List<TenantMembershipDto>> listUserTenants() async {
    try {
      final rows = await _rpcClient.callList('list_user_tenants');
      return rows
          .map(
            (row) => TenantMembershipDto(
              tenantId: row['tenant_id'] as String,
              name: row['name'] as String,
              role: row['role'] as String,
            ),
          )
          .toList(growable: false);
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
    }
  }

  @override
  Future<List<AccessibleTenantDto>> listAccessibleTenants() async {
    try {
      final rows = await _rpcClient.callList('list_accessible_tenants');
      return rows
          .map(
            (row) => AccessibleTenantDto(
              tenantId: row['tenant_id'] as String,
              name: row['name'] as String,
              roleLabel: row['role'] as String,
              status: _mapTenantStatus(row['status'] as String?),
              isOwner: row['is_owner'] as bool? ?? false,
            ),
          )
          .toList(growable: false);
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
    }
  }

  @override
  Future<TenantContextDto> switchTenantContext({
    required String targetTenantId,
  }) async {
    try {
      final result = await _rpcClient.callMap(
        'switch_tenant_context',
        params: <String, dynamic>{'p_target_tenant_id': targetTenantId},
      );
      return _mapTenantContext(result);
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
    }
  }

  @override
  Future<TenantContextDto> getValidatedTenantContext({
    String? sessionTenantId,
  }) async {
    try {
      final result = await _rpcClient.callMap(
        'get_tenant_context',
        params: sessionTenantId == null ? null : <String, dynamic>{'p_tenant_id': sessionTenantId},
      );
      if (result.isEmpty) {
        return const TenantContextDto(status: TenantContextStatus.none);
      }
      return _mapTenantContext(result);
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
    }
  }

  @override
  Future<CursorPageDto<TenantMemberDto>> listTenantMembers({
    required String tenantId,
    String? search,
    String? status,
    String? cursor,
    int limit = 20,
  }) async {
    try {
      final page = await _rpcClient.callMap(
        'list_tenant_members',
        params: <String, dynamic>{
          'p_tenant_id': tenantId,
          // PostgREST matches by exact param set — always send optionals (null OK).
          'p_search': search,
          'p_status': status,
          'p_cursor': cursor,
          'p_limit': limit,
        },
      );
      final rows = (page['items'] as List<dynamic>? ?? const []);
      final items = rows
          .map((raw) {
            final row = Map<String, dynamic>.from(raw as Map);
            return TenantMemberDto(
              membershipId: row['membership_id'] as String? ?? row['user_id'] as String,
              userId: row['user_id'] as String,
              displayName: row['display_name'] as String? ?? '',
              email: row['email'] as String? ?? '',
              roleId: row['role_id'] as String? ?? row['role'] as String? ?? '',
              roleLabel: row['role_label'] as String? ?? row['role'] as String? ?? '',
              isOwner: row['is_owner'] as bool? ?? false,
              status: row['status'] as String? ?? 'active',
              joinedAt: DateTime.parse(
                (row['joined_at'] as String?) ?? (row['created_at'] as String),
              ),
              version: (row['version'] as num?)?.toInt() ?? 1,
            );
          })
          .toList(growable: false);
      return CursorPageDto<TenantMemberDto>(
        items: items,
        nextCursor: page['next_cursor'] as String?,
      );
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
    }
  }

  @override
  Future<void> assignMemberRole({
    required String tenantId,
    required String userId,
    required String role,
  }) async {
    try {
      await _rpcClient.callScalar<Object?>(
        'assign_member_role',
        params: <String, dynamic>{
          'p_tenant_id': tenantId,
          'p_user_id': userId,
          'p_role': role,
        },
      );
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
    }
  }

  @override
  Future<bool> hasPermission({
    required String tenantId,
    required String permission,
  }) async {
    try {
      final result = await _rpcClient.callScalar<bool>(
        'has_permission',
        params: <String, dynamic>{
          'p_tenant_id': tenantId,
          'p_permission': permission,
        },
      );
      return result ?? false;
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
    }
  }

  @override
  Future<bool> isMember(String tenantId) async {
    final context = await getSessionContext(tenantId: tenantId);
    return context != null;
  }

  PrincipalAccessDto _mapPrincipalAccess(Map<String, dynamic> json) {
    final permissionsRaw = json['permissions'];
    final permissions = switch (permissionsRaw) {
      final List<dynamic> list => list.map((e) => e as String).toList(),
      _ => const <String>[],
    };

    return PrincipalAccessDto(
      userId: json['user_id'] as String,
      tenantId: json['tenant_id'] as String,
      role: json['role'] as String,
      isOwner: json['is_owner'] as bool? ?? false,
      permissions: permissions,
    );
  }

  TenantContextDto _mapTenantContext(Map<String, dynamic> json) {
    final statusRaw = json['status'] as String? ?? 'none';
    final status = switch (statusRaw) {
      'valid' => TenantContextStatus.valid,
      'invalidated' => TenantContextStatus.invalidated,
      _ => TenantContextStatus.none,
    };

    final permissionsRaw = json['permissions'];
    final permissions = switch (permissionsRaw) {
      final List<dynamic> list => list.map((e) => e as String).toList(),
      _ => const <String>[],
    };

    final reasonRaw = json['invalidation_reason'] as String?;
    final invalidationReason = switch (reasonRaw) {
      'membershipRemoved' => TenantContextInvalidationReason.membershipRemoved,
      'membershipInactive' => TenantContextInvalidationReason.membershipInactive,
      'tenantSuspended' => TenantContextInvalidationReason.tenantSuspended,
      'tenantClosed' => TenantContextInvalidationReason.tenantClosed,
      'accessDenied' => TenantContextInvalidationReason.accessDenied,
      'identityInactive' => TenantContextInvalidationReason.identityInactive,
      'roleNoLongerAssignable' => TenantContextInvalidationReason.roleNoLongerAssignable,
      'permissionsChanged' => TenantContextInvalidationReason.permissionsChanged,
      'ownershipChanged' => TenantContextInvalidationReason.ownershipChanged,
      _ => null,
    };

    final tenantStatusRaw = json['tenant_status'] as String?;

    return TenantContextDto(
      status: status,
      tenantId: json['tenant_id'] as String?,
      tenantName: json['tenant_name'] as String?,
      roleLabel: json['role'] as String?,
      isOwner: json['is_owner'] as bool? ?? false,
      permissions: permissions,
      tenantStatus: tenantStatusRaw == null ? null : _mapTenantStatus(tenantStatusRaw),
      invalidationReason: invalidationReason,
      blockedErrorCode: json['blocked_error_code'] as String?,
    );
  }

  TenantLifecycleStatus _mapTenantStatus(String? raw) {
    return switch (raw) {
      'provisioning' => TenantLifecycleStatus.provisioning,
      'suspended' => TenantLifecycleStatus.suspended,
      'closed' => TenantLifecycleStatus.closed,
      _ => TenantLifecycleStatus.active,
    };
  }
}
