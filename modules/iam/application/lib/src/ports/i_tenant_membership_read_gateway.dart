import '../tenant/shared/tenant_member_detail_dto.dart';

/// Read port for TenantMembership detail (S10).
abstract interface class ITenantMembershipReadGateway {
  Future<TenantMemberDetailDto?> getMember({
    required String tenantId,
    required String membershipId,
  });
}
