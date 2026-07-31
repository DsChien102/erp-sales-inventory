import '../invitation/shared/invitation_detail_dto.dart';
import '../invitation/shared/invitation_token_inspection_dto.dart';
import '../dto/tenant_member_detail_dto.dart';

/// Token-gated invitation inspect / accept / decline (§S8).
abstract interface class ITenantInvitationAcceptancePort {
  Future<InvitationTokenInspectionDto> inspectToken(String token);

  Future<TenantMemberDetailDto> acceptInvitation({
    required String token,
    required String idempotencyKey,
  });

  Future<InvitationDetailDto> declineInvitation({
    required String token,
    required String idempotencyKey,
  });
}
