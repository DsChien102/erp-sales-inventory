import '../data/models/tenant_invitation.dart';
import 'iam_date_formatter.dart';
import 'user_ui_model.dart';

abstract final class InvitationUiMapper {
  static InvitationUiModel fromSummary(
    InvitationSummaryDto dto, {
    required DateTime nowUtc,
  }) {
    final expiry = _expiryLabel(dto, nowUtc);
    final delivery = _deliveryLabel(dto.deliveryStatus);
    final detail = expiry.isEmpty
        ? '${dto.initialRoleLabel} · $delivery'
        : '${dto.initialRoleLabel} · $expiry · $delivery';
    return InvitationUiModel(
      id: dto.invitationId,
      email: dto.inviteeEmail,
      role: dto.initialRoleLabel,
      statusDetail: detail,
      expiryLabel: expiry,
      deliveryLabel: delivery,
      status: _listStatus(dto, nowUtc),
      deliveryStatus: dto.deliveryStatus,
      expiresAt: dto.expiresAt,
      version: dto.version,
    );
  }

  static InvitationUiModel fromDetail(
    InvitationDetailDto dto, {
    required DateTime nowUtc,
  }) {
    return fromSummary(dto.toSummary(), nowUtc: nowUtc);
  }

  static InvitationStatus _listStatus(
    InvitationSummaryDto dto,
    DateTime nowUtc,
  ) {
    // Terminal lifecycle wins: a revoked invitation is not a delivery problem.
    switch (dto.status) {
      case 'accepted':
        return InvitationStatus.accepted;
      case 'declined':
        return InvitationStatus.declined;
      case 'revoked':
        return InvitationStatus.revoked;
      case 'expired':
        return InvitationStatus.expired;
    }

    // Still live — delivery outcome is independent of lifecycle status.
    if (dto.deliveryStatus == 'failed') {
      return InvitationStatus.failed;
    }
    if (IamDateFormatter.isExpiringSoon(dto.expiresAt, nowUtc)) {
      return InvitationStatus.expiring;
    }
    return InvitationStatus.pending;
  }

  static String _deliveryLabel(String deliveryStatus) {
    return switch (deliveryStatus) {
      'failed' => 'Chưa gửi được email',
      'queued' => 'Đang xếp hàng gửi',
      'sent' => 'Đã gửi email',
      _ => '—',
    };
  }

  static String _expiryLabel(InvitationSummaryDto dto, DateTime nowUtc) {
    if (dto.status == 'accepted' ||
        dto.status == 'declined' ||
        dto.status == 'revoked') {
      return '';
    }
    return IamDateFormatter.invitationExpiryDetail(dto.expiresAt, nowUtc);
  }
}
