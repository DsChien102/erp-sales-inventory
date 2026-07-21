import '../dto/accessible_tenant_dto.dart';
import '../dto/principal_access_dto.dart';
import '../dto/tenant_context_dto.dart';
import '../dto/tenant_member_dto.dart';
import '../dto/tenant_membership_dto.dart';

/// Port for IAM access reads — infrastructure implements via Supabase RPC.
abstract interface class IIamAccessGateway {
  Future<PrincipalAccessDto?> getSessionContext({String? tenantId});

  Future<List<TenantMembershipDto>> listUserTenants();

  /// Accessible tenants for the authenticated actor (S1).
  /// Returns `isCurrent: false`; handler sets current from session.
  Future<List<AccessibleTenantDto>> listAccessibleTenants();

  /// Switch tenant context after re-validating access (S2).
  /// RPC target: `iam.switch_tenant_context`.
  Future<TenantContextDto> switchTenantContext({
    required String targetTenantId,
  });

  /// Validate current or candidate session tenant (S3).
  /// RPC target: `iam.get_tenant_context`.
  Future<TenantContextDto> getValidatedTenantContext({
    String? sessionTenantId,
  });

  Future<List<TenantMemberDto>> listTenantMembers(String tenantId);

  Future<void> assignMemberRole({
    required String tenantId,
    required String userId,
    required String role,
  });

  Future<bool> hasPermission({
    required String tenantId,
    required String permission,
  });

  Future<bool> isMember(String tenantId);

  /// Dev/bootstrap — creates owner tenant when user has no membership.
  Future<String> bootstrapOwner({String tenantName = 'My Store'});
}
