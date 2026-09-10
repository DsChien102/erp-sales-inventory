import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/iam_error_mapper.dart';

/// Supabase RPC adapter for platform Admin operations (TH-01 S15/S16).
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
  Future<CursorPageDto<PlatformUserSummaryDto>> searchPlatformUsers({
    String? query,
    PlatformUserStatus? status,
    String? cursor,
    int limit = 20,
  }) async {
    try {
      final page = await _rpcClient.callMap(
        'search_platform_users',
        params: <String, dynamic>{
          'p_query': query,
          'p_status': status == null ? null : _statusToSql(status),
          'p_cursor': cursor,
          'p_page_size': limit,
        },
      );
      final items = (page['items'] as List? ?? const [])
          .map((e) => _mapSummary((e as Map).cast<String, dynamic>()))
          .toList(growable: false);
      return CursorPageDto(
        items: items,
        nextCursor: page['next_cursor'] as String?,
      );
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
  Future<void> sendActivationInvitation({
    required String userId,
    required int expectedVersion,
    required String idempotencyKey,
  }) async {
    try {
      // Owner Design A kích hoạt qua lời mời (tenant_invitations). "Gửi lại email
      // kích hoạt" dùng chung cơ chế resend của staff, phát lại mã mới — thay cho
      // send_activation_invitation (chỉ hợp platform user có auth.users).
      await _rpcClient.callScalar<Object?>(
        'resend_owner_activation',
        params: <String, dynamic>{
          'p_user_id': userId,
          'p_idempotency_key': idempotencyKey,
        },
      );
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
    }
  }

  @override
  Future<void> requestPasswordReset({
    required String userId,
    required int expectedVersion,
    required String idempotencyKey,
  }) async {
    try {
      await _rpcClient.callScalar<Object?>(
        'request_platform_password_reset',
        params: <String, dynamic>{
          'p_user_id': userId,
          'p_expected_version': expectedVersion,
          'p_idempotency_key': idempotencyKey,
        },
      );
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
    }
  }

  @override
  Future<void> suspendPlatformUser({
    required String userId,
    required String reason,
    required int expectedVersion,
    required String idempotencyKey,
  }) async {
    try {
      await _rpcClient.callScalar<Object?>(
        'suspend_platform_user',
        params: <String, dynamic>{
          'p_user_id': userId,
          'p_reason': reason,
          'p_expected_version': expectedVersion,
          'p_idempotency_key': idempotencyKey,
        },
      );
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
    }
  }

  @override
  Future<void> restorePlatformUser({
    required String userId,
    required int expectedVersion,
    required String idempotencyKey,
  }) async {
    try {
      await _rpcClient.callScalar<Object?>(
        'restore_platform_user',
        params: <String, dynamic>{
          'p_user_id': userId,
          'p_expected_version': expectedVersion,
          'p_idempotency_key': idempotencyKey,
        },
      );
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
    }
  }

  @override
  Future<TenantOnboardingResultDto> createTenantOnboarding({
    required bool isNewUser,
    required String organizationName,
    required String idempotencyKey,
    String? organizationDisplayName,
    String? contactEmail,
    String? contactPhone,
    String? contactAddressText,
    String? provinceCode,
    String? communeCode,
    String? legalName,
    String? taxCode,
    String? registeredAddressText,
    String? ownerUserId,
    String? ownerEmail,
    String? ownerGivenName,
    String? ownerFamilyName,
    String? ownerPhone,
    String? correlationId,
  }) async {
    try {
      final result = await _rpcClient.callMap(
        'create_tenant_onboarding',
        params: <String, dynamic>{
          'p_owner_user_id': ownerUserId,
          'p_org_name': organizationName,
          'p_org_display_name': organizationDisplayName,
          'p_org_contact_email': contactEmail,
          'p_org_contact_phone': contactPhone,
          'p_org_contact_address_text': contactAddressText,
          'p_org_province_code': provinceCode,
          'p_org_commune_code': communeCode,
          'p_org_legal_name': legalName,
          'p_org_tax_code': taxCode,
          'p_org_registered_address_text': registeredAddressText,
          'p_idempotency_key': idempotencyKey,
          'p_correlation_id': correlationId,
          'p_is_new_user': isNewUser,
          'p_owner_email': ownerEmail,
          'p_owner_given_name': ownerGivenName,
          'p_owner_family_name': ownerFamilyName,
          'p_owner_phone': ownerPhone,
        },
      );
      return TenantOnboardingResultDto(
        tenantId: result['tenant_id'] as String,
        ownerMembershipId: result['owner_membership_id'] as String?,
        ownerUserId: result['owner_user_id'] as String?,
        tenantStatus: result['tenant_status'] as String,
        correlationId: result['correlation_id'] as String,
        isNewUser: result['is_new_user'] as bool? ?? isNewUser,
        activationIssued: result['activation_issued'] as bool? ?? false,
      );
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
    }
  }

  @override
  Future<TenantOnboardingOperationDto?> getTenantOnboardingOperation(
    String operationId,
  ) async {
    try {
      final result = await _rpcClient.callMap(
        'get_tenant_onboarding_operation',
        params: <String, dynamic>{'p_operation_id': operationId},
      );
      if (result.isEmpty) return null;
      return _mapOnboardingOperation(result);
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
    }
  }

  @override
  Future<TenantOnboardingOperationDto> retryTenantOnboardingOperation({
    required String operationId,
    required String idempotencyKey,
  }) async {
    try {
      final result = await _rpcClient.callMap(
        'retry_tenant_onboarding_operation',
        params: <String, dynamic>{
          'p_operation_id': operationId,
          'p_idempotency_key': idempotencyKey,
        },
      );
      return _mapOnboardingOperation(result);
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
    }
  }

  @override
  Future<CursorPageDto<PlatformTenantSummaryDto>> searchPlatformTenants({
    String? query,
    TenantLifecycleStatus? status,
    String? readinessState,
    String? warningCode,
    String? cursor,
    int limit = 20,
  }) async {
    try {
      final page = await _rpcClient.callMap(
        'search_platform_tenants',
        params: <String, dynamic>{
          'p_query': query,
          'p_status': status == null ? null : _tenantStatusToSql(status),
          'p_readiness_state': readinessState,
          'p_warning_code': warningCode,
          'p_cursor': cursor,
          'p_page_size': limit,
        },
      );
      final items = (page['items'] as List? ?? const [])
          .map((e) => _mapTenantSummary((e as Map).cast<String, dynamic>()))
          .toList(growable: false);
      return CursorPageDto(
        items: items,
        nextCursor: page['next_cursor'] as String?,
      );
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
    required int expectedVersion,
    required String idempotencyKey,
  }) async {
    try {
      await _rpcClient.callScalar<Object?>(
        'suspend_platform_tenant',
        params: <String, dynamic>{
          'p_tenant_id': tenantId,
          'p_reason': reason,
          'p_expected_version': expectedVersion,
          'p_idempotency_key': idempotencyKey,
        },
      );
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
    }
  }

  @override
  Future<void> restorePlatformTenant({
    required String tenantId,
    required int expectedVersion,
    required String idempotencyKey,
  }) async {
    try {
      await _rpcClient.callScalar<Object?>(
        'restore_platform_tenant',
        params: <String, dynamic>{
          'p_tenant_id': tenantId,
          'p_expected_version': expectedVersion,
          'p_idempotency_key': idempotencyKey,
        },
      );
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
    }
  }

  @override
  Future<void> transferPlatformTenantOwnership({
    required String tenantId,
    required String newOwnerUserId,
    required int expectedVersion,
    required String idempotencyKey,
  }) async {
    try {
      await _rpcClient.callScalar<Object?>(
        'transfer_platform_tenant_ownership',
        params: <String, dynamic>{
          'p_tenant_id': tenantId,
          'p_new_owner_user_id': newOwnerUserId,
          'p_expected_version': expectedVersion,
          'p_idempotency_key': idempotencyKey,
        },
      );
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
    }
  }

  @override
  Future<CursorPageDto<PlatformAuditLogSummaryDto>> searchPlatformAuditLogs({
    DateTime? fromUtc,
    DateTime? toUtc,
    String? actorUserId,
    String? targetType,
    String? targetId,
    String? action,
    String? result,
    String? source,
    String? correlationId,
    String? cursor,
    int limit = 20,
  }) async {
    try {
      final page = await _rpcClient.callMap(
        'search_platform_audit_logs',
        params: <String, dynamic>{
          'p_from': fromUtc?.toUtc().toIso8601String(),
          'p_to': toUtc?.toUtc().toIso8601String(),
          'p_actor_user_id': actorUserId,
          'p_target_type': targetType,
          'p_target_id': targetId,
          'p_action': action,
          'p_result': result,
          'p_source': source,
          'p_correlation_id': correlationId,
          'p_cursor': cursor,
          'p_page_size': limit,
        },
      );
      final items = (page['items'] as List? ?? const [])
          .map((e) => _mapAuditSummary((e as Map).cast<String, dynamic>()))
          .toList(growable: false);
      return CursorPageDto(
        items: items,
        nextCursor: page['next_cursor'] as String?,
      );
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
    }
  }

  @override
  Future<PlatformAuditLogDetailDto> getPlatformAuditLog(
    String auditLogId,
  ) async {
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

  TenantOnboardingOperationDto _mapOnboardingOperation(
    Map<String, dynamic> row,
  ) {
    final stepsRaw = row['completed_steps'];
    final steps = switch (stepsRaw) {
      final List list => list.map((e) => e.toString()).toList(growable: false),
      _ => const <String>[],
    };
    return TenantOnboardingOperationDto(
      operationId: row['operation_id'] as String,
      status:
          TenantOnboardingOperationStatusCodes.fromCode(
            row['status'] as String?,
          ) ??
          TenantOnboardingOperationStatus.inProgress,
      completedSteps: steps,
      failedStep: row['failed_step'] as String?,
      correlationId: row['correlation_id'] as String? ?? '',
      tenantId: row['tenant_id'] as String?,
      ownerUserId: row['owner_user_id'] as String?,
    );
  }

  PlatformUserSummaryDto _mapSummary(Map<String, dynamic> row) {
    return PlatformUserSummaryDto(
      userId: row['user_id'] as String,
      fullName: row['full_name'] as String? ?? '',
      email: row['email'] as String? ?? '',
      status: _statusFromSql(row['status'] as String?),
      createdAt: DateTime.parse(row['created_at'] as String),
      phoneNumber: row['phone_number'] as String?,
    );
  }

  PlatformUserDetailDto _mapDetail(Map<String, dynamic> json) {
    final membershipsRaw = json['memberships'];
    final memberships = switch (membershipsRaw) {
      final List<dynamic> list =>
        list
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
    final activationRaw = json['activation_expires_at'];
    final emailVerifiedRaw = json['email_verified_at'];
    return PlatformUserDetailDto(
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      status: _statusFromSql(json['status'] as String?),
      emailVerified: json['email_verified'] as bool? ?? false,
      emailVerifiedAt:
          emailVerifiedRaw is String ? DateTime.parse(emailVerifiedRaw) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      version: (json['version'] as num?)?.toInt() ?? 1,
      lastLoginAt: lastLoginRaw is String ? DateTime.parse(lastLoginRaw) : null,
      activationExpiresAt:
          activationRaw is String ? DateTime.parse(activationRaw) : null,
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
      readinessState: row['readiness_state'] as String?,
      warningCode: row['warning_code'] as String?,
    );
  }

  PlatformTenantDetailDto _mapTenantDetail(Map<String, dynamic> json) {
    final membersRaw = json['members'];
    final mappedMembers = switch (membersRaw) {
      final List<dynamic> list =>
        list
            .map((e) => e as Map<String, dynamic>)
            .map(_mapTenantMemberFromJson)
            .toList(growable: false),
      _ => const <PlatformTenantMemberDto>[],
    };
    final membersByUserId = <String, PlatformTenantMemberDto>{};
    for (final member in mappedMembers) {
      membersByUserId.putIfAbsent(member.userId, () => member);
    }
    final members = membersByUserId.values.toList(growable: false);
    final status = _tenantStatusFromSql(json['status'] as String?);
    final isSettingUp = status == TenantLifecycleStatus.provisioning;
    final ownerEmail = json['owner_email'] as String?;
    final ownerEmailVerified = json['owner_email_verified'] as bool? ?? false;
    final unverifiedEmail = json['unverified_email'] as bool? ?? (isSettingUp && !ownerEmailVerified);
    final incompleteProfile = json['incomplete_profile'] as bool? ?? isSettingUp;

    return PlatformTenantDetailDto(
      tenantId: json['tenant_id'] as String,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      status: status,
      createdAt: DateTime.parse(json['created_at'] as String),
      version: (json['version'] as num?)?.toInt() ?? 1,
      ownerUserId: json['owner_user_id'] as String?,
      ownerName: json['owner_name'] as String?,
      ownerEmail: ownerEmail,
      ownerRoleLabel: json['owner_role'] as String? ?? 'Chủ sở hữu',
      activatedAt: _parseDate(json['activated_at']),
      lastActivityAt: _parseDate(json['last_activity_at']),
      suspendedAt: _parseDate(json['suspended_at']),
      suspendedBy: json['suspended_by'] as String?,
      suspendReason: json['suspend_reason'] as String?,
      closedAt: _parseDate(json['closed_at']),
      closedBy: json['closed_by'] as String?,
      closeReason: json['close_reason'] as String?,
      members: members,
      unverifiedEmail: unverifiedEmail,
      incompleteProfile: incompleteProfile,
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
      roleLabel:
          m['role_label'] as String? ?? m['label_text'] as String? ?? m['role'] as String? ?? '',
      isOwner: m['is_owner'] as bool? ?? false,
    );
  }

  PlatformAuditLogSummaryDto _mapAuditSummary(Map<String, dynamic> row) {
    return PlatformAuditLogSummaryDto(
      id: row['id'] as String? ?? row['audit_log_id'] as String,
      title: row['title'] as String? ?? row['event_code'] as String? ?? '',
      actionCode: row['action_code'] as String? ?? row['event_code'] as String? ?? '',
      status: _auditStatusFromSql(row['status'] as String? ?? row['result'] as String?),
      actorName: row['actor_name'] as String? ?? '',
      actorRole: row['actor_role'] as String? ?? '',
      targetOrgName: row['target_org_name'] as String? ?? row['subject_type'] as String? ?? '',
      targetOrgCode: row['target_org_code'] as String? ?? row['subject_id'] as String? ?? '',
      timestamp: DateTime.parse(
        (row['created_at'] ?? row['occurred_at']) as String,
      ),
      sourceApp: row['source_app'] as String? ?? row['source'] as String? ?? '',
    );
  }

  PlatformAuditLogDetailDto _mapAuditDetail(Map<String, dynamic> json) {
    return PlatformAuditLogDetailDto(
      id: json['id'] as String,
      auditNo: (json['audit_no'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      actionCode: json['action_code'] as String? ?? '',
      status: _auditStatusFromSql(json['status'] as String?),
      statusLabel: json['status_label'] as String? ?? '',
      actorName: json['actor_name'] as String? ?? '',
      actorRole: json['actor_role'] as String? ?? '',
      targetOrgName: json['target_org_name'] as String? ?? json['subject_type'] as String? ?? '',
      targetOrgCode: json['target_org_code'] as String? ?? json['subject_id'] as String? ?? '',
      targetType: json['target_type'] as String? ?? '',
      targetDisplayName: json['target_display_name'] as String? ?? '',
      timestamp: DateTime.parse(
        (json['timestamp'] ?? json['created_at']) as String,
      ),
      sourceApp: json['source_app'] as String? ?? '',
      correlationId: json['correlation_id'] as String? ?? '',
      beforeState: json['before_state']?.toString() ?? '',
      afterState: json['after_state']?.toString() ?? '',
      changeBefore: json['change_before'] is Map
          ? Map<String, Object?>.from(json['change_before'] as Map)
          : const {},
      changeAfter: json['change_after'] is Map
          ? Map<String, Object?>.from(json['change_after'] as Map)
          : const {},
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

  static PlatformAuditLogStatus _auditStatusFromSql(String? raw) {
    return switch (raw) {
      'blocked' => PlatformAuditLogStatus.blocked,
      'error' => PlatformAuditLogStatus.error,
      _ => PlatformAuditLogStatus.success,
    };
  }
}
