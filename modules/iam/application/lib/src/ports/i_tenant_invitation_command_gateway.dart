import '../invitation/shared/invitation_detail_dto.dart';

/// Command gateway for tenant invitation mutations (S7/S9).
abstract interface class ITenantInvitationCommandGateway {
  Future<InvitationDetailDto> createInvitation({
    required String tenantId,
    required String inviteeEmail,
    required String initialRoleId,
    required String idempotencyKey,
  });

  Future<InvitationDetailDto> resendInvitation({
    required String tenantId,
    required String invitationId,
    required int expectedVersion,
    required String idempotencyKey,
  });

  Future<InvitationDetailDto> revokeInvitation({
    required String tenantId,
    required String invitationId,
    required int expectedVersion,
    required String reason,
    required String idempotencyKey,
  });
}
