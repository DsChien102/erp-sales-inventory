import '../../tenant/shared/tenant_member_detail_dto.dart';

/// Result of RegisterFromInvitationCommand (§S8).
final class InvitationRegistrationResultDto {
  const InvitationRegistrationResultDto({
    required this.userId,
    required this.membership,
  });

  final String userId;
  final TenantMemberDetailDto membership;
}
