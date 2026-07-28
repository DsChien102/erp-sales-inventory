import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/iam_error_mapper.dart';

/// Supabase RPC adapter for platform Admin operations (TH-01 S15).
///
/// New-user onboarding (create `auth.users`) is a Platform Identity boundary —
/// this gateway only calls Theme-1 RPC with a resolved [ownerUserId].
final class SupabasePlatformAdminGateway implements IPlatformAdminGateway {
  SupabasePlatformAdminGateway({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<bool> hasPlatformPermission(String permission) async {
    try {
      final result = await _rpcClient.callScalar<bool>(
        'has_platform_permission',
        params: <String, dynamic>{'p_permission': permission},
      );
      return result ?? false;
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
    }
  }

  @override
  Future<List<PlatformUserSummaryDto>> searchPlatformUsers({
    String? query,
    PlatformUserStatus? status,
  }) async {
    try {
      final rows = await _rpcClient.callList(
        'search_platform_users',
        params: <String, dynamic>{
          'p_query': query,
          'p_status': status == null ? null : _statusToSql(status),
        },
      );
      return rows.map(_mapSummary).toList(growable: false);
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
    }
  }

  @override
  Future<PlatformUserDetailDto> getPlatformUser(String userId) async {
    try {
      final result = await _rpcClient.callMap(
        'get_platform_user',
        params: <String, dynamic>{'p_user_id': userId},
      );
      if (result.isEmpty) {
        throw ApplicationException('Platform user not found: $userId');
      }
      return _mapDetail(result);
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
    }
  }

  @override
  Future<void> sendActivationInvitation(String userId) async {
    try {
      await _rpcClient.callScalar<Object?>(
        'send_activation_invitation',
        params: <String, dynamic>{'p_user_id': userId},
      );
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
    }
  }

  @override
  Future<void> requestPasswordReset(String userId) async {
    try {
      await _rpcClient.callScalar<Object?>(
        'request_platform_password_reset',
        params: <String, dynamic>{'p_user_id': userId},
      );
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
    }
  }

  @override
  Future<void> suspendPlatformUser({
    required String userId,
    required String reason,
  }) async {
    try {
      await _rpcClient.callScalar<Object?>(
        'suspend_platform_user',
        params: <String, dynamic>{
          'p_user_id': userId,
          'p_reason': reason,
        },
      );
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
    }
  }

  @override
  Future<void> restorePlatformUser(String userId) async {
    try {
      await _rpcClient.callScalar<Object?>(
        'restore_platform_user',
        params: <String, dynamic>{'p_user_id': userId},
      );
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
    }
  }

  @override
  Future<TenantOnboardingResultDto> createTenantOnboarding({
    required OnboardingOwnerInput owner,
    required String organizationName,
    required String idempotencyKey,
    String? correlationId,
  }) async {
    final ownerUserId = await _resolveOwnerUserId(owner);
    try {
      final result = await _rpcClient.callMap(
        'create_tenant_onboarding',
        params: <String, dynamic>{
          'p_owner_user_id': ownerUserId,
          'p_org_name': organizationName,
          'p_idempotency_key': idempotencyKey,
          'p_correlation_id': correlationId,
          'p_is_new_user': owner.isNewUser,
        },
      );
      return TenantOnboardingResultDto(
        tenantId: result['tenant_id'] as String,
        ownerMembershipId: result['owner_membership_id'] as String,
        ownerUserId: result['owner_user_id'] as String,
        tenantStatus: result['tenant_status'] as String,
        correlationId: result['correlation_id'] as String,
        isNewUser: result['is_new_user'] as bool? ?? owner.isNewUser,
      );
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
    }
  }


  @override
  Future<List<PlatformTenantSummaryDto>> searchPlatformTenants({
    String? query,
    TenantLifecycleStatus? status,
  }) async {
    try {
      final rows = await _rpcClient.callList(
        'search_platform_tenants',
        params: <String, dynamic>{
          'p_query': query,
          'p_status': status == null ? null : _tenantStatusToSql(status),
        },
      );
      return rows.map(_mapTenantSummary).toList(growable: false);
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
    }
  }

  @override
  Future<PlatformTenantDetailDto> getPlatformTenant(String tenantId) async {
    try {
      final result = await _rpcClient.callMap(
        'get_platform_tenant',
        params: <String, dynamic>{'p_tenant_id': tenantId},
      );
      if (result.isEmpty) {
        throw ApplicationException('Platform tenant not found: $tenantId');
      }
      return _mapTenantDetail(result);
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
    }
  }

  @override
  Future<List<PlatformTenantMemberDto>> listPlatformTenantMembers(
    String tenantId,
  ) async {
    try {
      final rows = await _rpcClient.callList(
        'list_platform_tenant_members',
        params: <String, dynamic>{'p_tenant_id': tenantId},
      );
      return rows.map(_mapTenantMember).toList(growable: false);
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
    }
  }

  @override
  Future<void> suspendPlatformTenant({
    required String tenantId,
    required String reason,
  }) async {
    try {
      await _rpcClient.callScalar<Object?>(
        'suspend_platform_tenant',
        params: <String, dynamic>{
          'p_tenant_id': tenantId,
          'p_reason': reason,
        },
      );
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
    }
  }

  @override
  Future<void> restorePlatformTenant(String tenantId) async {
    try {
      await _rpcClient.callScalar<Object?>(
        'restore_platform_tenant',
        params: <String, dynamic>{'p_tenant_id': tenantId},
      );
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
    }
  }

  @override
  Future<void> transferPlatformTenantOwnership({
    required String tenantId,
    required String newOwnerUserId,
    required String idempotencyKey,
  }) async {
    try {
      await _rpcClient.callScalar<Object?>(
        'transfer_platform_tenant_ownership',
        params: <String, dynamic>{
          'p_tenant_id': tenantId,
          'p_new_owner_user_id': newOwnerUserId,
          'p_idempotency_key': idempotencyKey,
        },
      );
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
    }
  }

  @override
  Future<List<PlatformAuditLogSummaryDto>> searchPlatformAuditLogs({
    String? query,
    PlatformAuditLogStatus? status,
  }) async {
    try {
      final rows = await _rpcClient.callList(
        'search_platform_audit_logs',
        params: <String, dynamic>{
          'p_query': query,
          'p_status': status == null ? null : _auditStatusToSql(status),
        },
      );
      return rows.map(_mapAuditSummary).toList(growable: false);
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
    }
  }

  @override
  Future<PlatformAuditLogDetailDto> getPlatformAuditLog(String auditLogId) async {
    try {
      final result = await _rpcClient.callMap(
        'get_platform_audit_log',
        params: <String, dynamic>{'p_audit_log_id': auditLogId},
      );
      if (result.isEmpty) {
        throw ApplicationException('Audit log not found: $auditLogId');
      }
      return _mapAuditDetail(result);
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
    }
  }

  Future<String> _resolveOwnerUserId(OnboardingOwnerInput owner) async {
    if (owner.isExisting) {
      return owner.existingUserId!;
    }
    // Platform Identity boundary — creating auth.users is out of Theme-1 scope.
    throw ApplicationException(
      'New Platform User creation requires Platform Identity; '
      'resolve an existing userId for interim onboarding',
    );
  }

  PlatformUserSummaryDto _mapSummary(Map<String, dynamic> row) {
    return PlatformUserSummaryDto(
      userId: row['user_id'] as String,
      fullName: row['full_name'] as String? ?? '',
      email: row['email'] as String? ?? '',
      status: _statusFromSql(row['status'] as String?),
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  PlatformUserDetailDto _mapDetail(Map<String, dynamic> json) {
    final membershipsRaw = json['memberships'];
    final memberships = switch (membershipsRaw) {
      final List<dynamic> list => list
          .map((e) => e as Map<String, dynamic>)
          .map(
            (m) => PlatformUserMembershipDto(
              tenantId: m['tenant_id'] as String,
              tenantName: m['tenant_name'] as String? ?? '',
              roleLabel: m['role'] as String? ?? '',
              isOwner: m['is_owner'] as bool? ?? false,
            ),
          )
          .toList(growable: false),
      _ => const <PlatformUserMembershipDto>[],
    };

    final lastLoginRaw = json['last_login_at'];
    return PlatformUserDetailDto(
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      status: _statusFromSql(json['status'] as String?),
      emailVerified: json['email_verified'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastLoginAt: lastLoginRaw is String ? DateTime.parse(lastLoginRaw) : null,
      memberships: memberships,
    );
  }

  static String _statusToSql(PlatformUserStatus status) {
    return switch (status) {
      PlatformUserStatus.pendingActivation => 'pending_activation',
      PlatformUserStatus.active => 'active',
      PlatformUserStatus.suspended => 'suspended',
    };
  }

  static PlatformUserStatus _statusFromSql(String? raw) {
    return switch (raw) {
      'pending_activation' => PlatformUserStatus.pendingActivation,
      'suspended' => PlatformUserStatus.suspended,
      _ => PlatformUserStatus.active,
    };
  }

  PlatformTenantSummaryDto _mapTenantSummary(Map<String, dynamic> row) {
    return PlatformTenantSummaryDto(
      tenantId: row['tenant_id'] as String,
      name: row['name'] as String? ?? '',
      code: row['code'] as String? ?? '',
      status: _tenantStatusFromSql(row['status'] as String?),
      createdAt: DateTime.parse(row['created_at'] as String),
      ownerName: row['owner_name'] as String?,
      ownerEmail: row['owner_email'] as String?,
      memberCount: (row['member_count'] as num?)?.toInt() ?? 0,
    );
  }

  PlatformTenantDetailDto _mapTenantDetail(Map<String, dynamic> json) {
    final membersRaw = json['members'];
    final members = switch (membersRaw) {
      final List<dynamic> list => list
          .map((e) => e as Map<String, dynamic>)
          .map(_mapTenantMemberFromJson)
          .toList(growable: false),
      _ => const <PlatformTenantMemberDto>[],
    };
    return PlatformTenantDetailDto(
      tenantId: json['tenant_id'] as String,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      status: _tenantStatusFromSql(json['status'] as String?),
      createdAt: DateTime.parse(json['created_at'] as String),
      ownerUserId: json['owner_user_id'] as String?,
      ownerName: json['owner_name'] as String?,
      ownerEmail: json['owner_email'] as String?,
      ownerRoleLabel: json['owner_role'] as String? ?? 'Chủ cửa hàng',
      activatedAt: _parseDate(json['activated_at']),
      suspendedAt: _parseDate(json['suspended_at']),
      suspendedBy: json['suspended_by'] as String?,
      suspendReason: json['suspend_reason'] as String?,
      closedAt: _parseDate(json['closed_at']),
      closedBy: json['closed_by'] as String?,
      closeReason: json['close_reason'] as String?,
      members: members,
    );
  }

  PlatformTenantMemberDto _mapTenantMember(Map<String, dynamic> row) {
    return PlatformTenantMemberDto(
      userId: row['user_id'] as String,
      fullName: row['full_name'] as String? ?? '',
      email: row['email'] as String? ?? '',
      roleLabel: row['role_label'] as String? ?? row['role'] as String? ?? '',
      isOwner: row['is_owner'] as bool? ?? false,
    );
  }

  PlatformTenantMemberDto _mapTenantMemberFromJson(Map<String, dynamic> m) {
    return PlatformTenantMemberDto(
      userId: m['user_id'] as String,
      fullName: m['full_name'] as String? ?? '',
      email: m['email'] as String? ?? '',
      roleLabel: m['role'] as String? ?? '',
      isOwner: m['is_owner'] as bool? ?? false,
    );
  }

  PlatformAuditLogSummaryDto _mapAuditSummary(Map<String, dynamic> row) {
    return PlatformAuditLogSummaryDto(
      id: row['id'] as String,
      title: row['title'] as String? ?? '',
      actionCode: row['action_code'] as String? ?? '',
      status: _auditStatusFromSql(row['status'] as String?),
      actorName: row['actor_name'] as String? ?? '',
      actorRole: row['actor_role'] as String? ?? '',
      targetOrgName: row['target_org_name'] as String? ?? '',
      targetOrgCode: row['target_org_code'] as String? ?? '',
      timestamp: DateTime.parse(row['created_at'] as String),
      sourceApp: row['source_app'] as String? ?? '',
    );
  }

  PlatformAuditLogDetailDto _mapAuditDetail(Map<String, dynamic> json) {
    return PlatformAuditLogDetailDto(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      actionCode: json['action_code'] as String? ?? '',
      status: _auditStatusFromSql(json['status'] as String?),
      statusLabel: json['status_label'] as String? ?? '',
      actorName: json['actor_name'] as String? ?? '',
      actorRole: json['actor_role'] as String? ?? '',
      targetOrgName: json['target_org_name'] as String? ?? '',
      targetOrgCode: json['target_org_code'] as String? ?? '',
      timestamp: DateTime.parse(json['timestamp'] as String),
      sourceApp: json['source_app'] as String? ?? '',
      correlationId: json['correlation_id'] as String? ?? '',
      beforeState: json['before_state'] as String? ?? '',
      afterState: json['after_state'] as String? ?? '',
    );
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw is String) return DateTime.parse(raw);
    return null;
  }

  static String _tenantStatusToSql(TenantLifecycleStatus status) {
    return switch (status) {
      TenantLifecycleStatus.provisioning => 'provisioning',
      TenantLifecycleStatus.active => 'active',
      TenantLifecycleStatus.suspended => 'suspended',
      TenantLifecycleStatus.closed => 'closed',
    };
  }

  static TenantLifecycleStatus _tenantStatusFromSql(String? raw) {
    return switch (raw) {
      'provisioning' => TenantLifecycleStatus.provisioning,
      'suspended' => TenantLifecycleStatus.suspended,
      'closed' => TenantLifecycleStatus.closed,
      _ => TenantLifecycleStatus.active,
    };
  }

  static String _auditStatusToSql(PlatformAuditLogStatus status) {
    return switch (status) {
      PlatformAuditLogStatus.success => 'success',
      PlatformAuditLogStatus.blocked => 'blocked',
      PlatformAuditLogStatus.error => 'error',
    };
  }

  static PlatformAuditLogStatus _auditStatusFromSql(String? raw) {
    return switch (raw) {
      'blocked' => PlatformAuditLogStatus.blocked,
      'error' => PlatformAuditLogStatus.error,
      _ => PlatformAuditLogStatus.success,
    };
  }

}

