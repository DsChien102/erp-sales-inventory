import '../invitation/shared/invitation_detail_dto.dart';
import '../ports/i_tenant_invitation_command_gateway.dart';
import '../shared/iam_blocked_codes.dart';
import '../shared/iam_blocked_exception.dart';

/// In-memory invitation command gateway for unit tests (S7/S9).
final class FakeTenantInvitationCommandGateway
    implements ITenantInvitationCommandGateway {
  FakeTenantInvitationCommandGateway({
    this.onCreate,
    this.onResend,
    this.onRevoke,
  });

  Future<InvitationDetailDto> Function({
    required String tenantId,
    required String inviteeEmail,
    required String initialRoleId,
    required String idempotencyKey,
  })? onCreate;

  Future<InvitationDetailDto> Function({
    required String tenantId,
    required String invitationId,
    required int expectedVersion,
    required String idempotencyKey,
  })? onResend;

  Future<InvitationDetailDto> Function({
    required String tenantId,
    required String invitationId,
    required int expectedVersion,
    required String reason,
    required String idempotencyKey,
  })? onRevoke;

  final Map<String, InvitationDetailDto> _byIdempotency = {};
  final Map<String, String> _payloadByKey = {};
  InvitationDetailDto? current;

  @override
  Future<InvitationDetailDto> createInvitation({
    required String tenantId,
    required String inviteeEmail,
    required String initialRoleId,
    required String idempotencyKey,
  }) async {
    if (onCreate != null) {
      return onCreate!(
        tenantId: tenantId,
        inviteeEmail: inviteeEmail,
        initialRoleId: initialRoleId,
        idempotencyKey: idempotencyKey,
      );
    }

    final payload = '$tenantId|$inviteeEmail|$initialRoleId';
    final existing = _byIdempotency[idempotencyKey];
    if (existing != null) {
      if (_payloadByKey[idempotencyKey] != payload) {
        throw const IamBlockedException(IamBlockedCodes.idempotencyConflict);
      }
      return existing;
    }

    final now = DateTime.utc(2026, 7, 29, 12);
    final created = InvitationDetailDto(
      invitationId: 'inv-${_byIdempotency.length + 1}',
      inviteeEmail: inviteeEmail,
      initialRoleId: initialRoleId,
      initialRoleLabel: 'Nhân viên bán hàng',
      status: 'pending',
      expiresAt: now.add(const Duration(days: 7)),
      deliveryStatus: 'queued',
      deliveryCorrelationId: 'corr-$idempotencyKey',
      version: 1,
      createdAt: now,
      createdBy: 'actor-1',
      lastSentAt: now,
    );
    _byIdempotency[idempotencyKey] = created;
    _payloadByKey[idempotencyKey] = payload;
    current = created;
    return created;
  }

  @override
  Future<InvitationDetailDto> resendInvitation({
    required String tenantId,
    required String invitationId,
    required int expectedVersion,
    required String idempotencyKey,
  }) async {
    if (onResend != null) {
      return onResend!(
        tenantId: tenantId,
        invitationId: invitationId,
        expectedVersion: expectedVersion,
        idempotencyKey: idempotencyKey,
      );
    }
    final payload = 'resend|$tenantId|$invitationId|$expectedVersion';
    final existing = _byIdempotency[idempotencyKey];
    if (existing != null) {
      if (_payloadByKey[idempotencyKey] != payload) {
        throw const IamBlockedException(IamBlockedCodes.idempotencyConflict);
      }
      return existing;
    }
    final base = current ??
        InvitationDetailDto(
          invitationId: invitationId,
          inviteeEmail: 'invitee@example.com',
          initialRoleId: 'role-staff',
          initialRoleLabel: 'Nhân viên bán hàng',
          status: 'pending',
          expiresAt: DateTime.utc(2026, 8, 5),
          deliveryStatus: 'sent',
          deliveryCorrelationId: 'corr-old',
          version: expectedVersion,
          createdAt: DateTime.utc(2026, 7, 29),
          createdBy: 'actor-1',
          lastSentAt: DateTime.utc(2026, 7, 29),
        );
    if (base.version != expectedVersion) {
      throw const IamBlockedException(IamBlockedCodes.stateChanged);
    }
    if (base.status != 'pending') {
      throw const IamBlockedException(IamBlockedCodes.invitationAlreadyUsed);
    }
    final now = DateTime.utc(2026, 7, 30, 12);
    final resent = InvitationDetailDto(
      invitationId: base.invitationId,
      inviteeEmail: base.inviteeEmail,
      initialRoleId: base.initialRoleId,
      initialRoleLabel: base.initialRoleLabel,
      status: 'pending',
      expiresAt: now.add(const Duration(days: 7)),
      deliveryStatus: 'queued',
      deliveryCorrelationId: 'corr-$idempotencyKey',
      version: base.version + 1,
      createdAt: base.createdAt,
      createdBy: base.createdBy,
      lastSentAt: now,
    );
    _byIdempotency[idempotencyKey] = resent;
    _payloadByKey[idempotencyKey] = payload;
    current = resent;
    return resent;
  }

  @override
  Future<InvitationDetailDto> revokeInvitation({
    required String tenantId,
    required String invitationId,
    required int expectedVersion,
    required String reason,
    required String idempotencyKey,
  }) async {
    if (onRevoke != null) {
      return onRevoke!(
        tenantId: tenantId,
        invitationId: invitationId,
        expectedVersion: expectedVersion,
        reason: reason,
        idempotencyKey: idempotencyKey,
      );
    }
    final payload = 'revoke|$tenantId|$invitationId|$expectedVersion|$reason';
    final existing = _byIdempotency[idempotencyKey];
    if (existing != null) {
      if (_payloadByKey[idempotencyKey] != payload) {
        throw const IamBlockedException(IamBlockedCodes.idempotencyConflict);
      }
      return existing;
    }
    final base = current ??
        InvitationDetailDto(
          invitationId: invitationId,
          inviteeEmail: 'invitee@example.com',
          initialRoleId: 'role-staff',
          initialRoleLabel: 'Nhân viên bán hàng',
          status: 'pending',
          expiresAt: DateTime.utc(2026, 8, 5),
          deliveryStatus: 'sent',
          deliveryCorrelationId: 'corr-old',
          version: expectedVersion,
          createdAt: DateTime.utc(2026, 7, 29),
          createdBy: 'actor-1',
          lastSentAt: DateTime.utc(2026, 7, 29),
        );
    if (base.version != expectedVersion) {
      throw const IamBlockedException(IamBlockedCodes.stateChanged);
    }
    if (base.status != 'pending') {
      throw const IamBlockedException(IamBlockedCodes.invitationAlreadyUsed);
    }
    final now = DateTime.utc(2026, 7, 30, 12);
    final revoked = InvitationDetailDto(
      invitationId: base.invitationId,
      inviteeEmail: base.inviteeEmail,
      initialRoleId: base.initialRoleId,
      initialRoleLabel: base.initialRoleLabel,
      status: 'revoked',
      expiresAt: base.expiresAt,
      deliveryStatus: base.deliveryStatus,
      deliveryCorrelationId: base.deliveryCorrelationId,
      version: base.version + 1,
      createdAt: base.createdAt,
      createdBy: base.createdBy,
      lastSentAt: base.lastSentAt,
      revokedAt: now,
    );
    _byIdempotency[idempotencyKey] = revoked;
    _payloadByKey[idempotencyKey] = payload;
    current = revoked;
    return revoked;
  }
}
