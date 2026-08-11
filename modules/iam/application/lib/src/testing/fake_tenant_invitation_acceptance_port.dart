import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_iam_application/application.dart';

/// In-memory acceptance port for unit/fake tests (§S8).
final class FakeTenantInvitationAcceptancePort
    implements ITenantInvitationAcceptancePort {
  FakeTenantInvitationAcceptancePort({
    this.inspection,
    this.onInspect,
    this.onAccept,
    this.onDecline,
  });

  InvitationTokenInspectionDto? inspection;
  Future<InvitationTokenInspectionDto> Function(String token)? onInspect;
  Future<TenantMemberDetailDto> Function({
    required String token,
    required String idempotencyKey,
  })?
  onAccept;
  Future<InvitationDetailDto> Function({
    required String token,
    required String idempotencyKey,
  })?
  onDecline;

  final Map<String, TenantMemberDetailDto> _acceptByKey = {};
  final Map<String, InvitationDetailDto> _declineByKey = {};
  final Set<String> _consumedTokens = {};

  @override
  Future<InvitationTokenInspectionDto> inspectToken(String token) async {
    if (onInspect != null) {
      return onInspect!(token);
    }
    if (inspection != null) {
      return inspection!;
    }
    throw const IamBlockedException(IamBlockedCodes.invitationTokenInvalid);
  }

  @override
  Future<TenantMemberDetailDto> acceptInvitation({
    required String token,
    required String idempotencyKey,
  }) async {
    if (onAccept != null) {
      return onAccept!(token: token, idempotencyKey: idempotencyKey);
    }
    final existing = _acceptByKey[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    if (_consumedTokens.contains(token)) {
      throw const IamBlockedException(IamBlockedCodes.invitationAlreadyUsed);
    }
    final membership = TenantMemberDetailDto(
      membershipId: 'mem-from-invite',
      tenantId: 'org-001',
      userId: 'new-member',
      role: 'staff',
      isOwner: false,
      isSoleOwner: false,
      status: MembershipStatus.active,
      version: 1,
      joinedAt: DateTime.utc(2026, 7, 30),
    );
    _acceptByKey[idempotencyKey] = membership;
    _consumedTokens.add(token);
    return membership;
  }

  @override
  Future<InvitationDetailDto> declineInvitation({
    required String token,
    required String idempotencyKey,
  }) async {
    if (onDecline != null) {
      return onDecline!(token: token, idempotencyKey: idempotencyKey);
    }
    final existing = _declineByKey[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final declined = InvitationDetailDto(
      invitationId: 'inv-declined',
      inviteeEmail: 'invitee@example.com',
      initialRoleId: 'role-staff',
      initialRoleLabel: 'Nhân viên bán hàng',
      status: 'declined',
      expiresAt: DateTime.utc(2026, 8, 5),
      deliveryStatus: 'sent',
      deliveryCorrelationId: 'corr-1',
      version: 2,
      createdAt: DateTime.utc(2026, 7, 29),
      createdBy: 'lan-le',
      declinedAt: DateTime.utc(2026, 7, 30),
    );
    _declineByKey[idempotencyKey] = declined;
    return declined;
  }
}
