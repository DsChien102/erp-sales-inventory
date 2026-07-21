import 'package:vet45_adapters/vet45_adapters.dart';
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
}
