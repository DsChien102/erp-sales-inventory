import '../dto/principal_access_dto.dart';
import '../dto/tenant_member_dto.dart';
import '../dto/tenant_membership_dto.dart';

/// Port for IAM access reads — infrastructure implements via Supabase RPC.
abstract interface class IIamAccessGateway {
  Future<PrincipalAccessDto?> getSessionContext({String? tenantId});

  Future<List<TenantMembershipDto>> listUserTenants();

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
