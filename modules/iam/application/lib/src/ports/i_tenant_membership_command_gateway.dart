import '../tenant/shared/tenant_member_detail_dto.dart';

/// Command port for TenantMembership lifecycle mutations (S10).
abstract interface class ITenantMembershipCommandGateway {
  Future<TenantMemberDetailDto> deactivate({
    required String tenantId,
    required String membershipId,
    required int expectedVersion,
  });

  Future<TenantMemberDetailDto> reactivate({
    required String tenantId,
    required String membershipId,
    required int expectedVersion,
  });

  Future<TenantMemberDetailDto> remove({
    required String tenantId,
    required String membershipId,
    required int expectedVersion,
  });
}
