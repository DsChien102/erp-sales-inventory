import 'package:vet45_iam_application/application.dart';

import '../models/user_ui_model.dart';
import 'iam_date_formatter.dart';

abstract final class InvitationUiMapper {
  static InvitationUiModel fromSummary(
    InvitationSummaryDto dto, {
    required DateTime nowUtc,
  }) {
    return InvitationUiModel(
      id: dto.invitationId,
      email: dto.inviteeEmail,
      role: dto.initialRoleLabel,
      statusDetail: _statusDetail(dto, nowUtc),
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

  static String _statusDetail(InvitationSummaryDto dto, DateTime nowUtc) {
    final delivery = switch (dto.deliveryStatus) {
      'failed' => 'Chưa gửi được email',
      'queued' => 'Đang xếp hàng gửi',
      'sent' => 'Đã gửi email',
      _ => dto.deliveryStatus,
    };
    final expiry = IamDateFormatter.invitationExpiryDetail(
      dto.expiresAt,
      nowUtc,
    );
    return '${dto.initialRoleLabel} · $expiry · $delivery';
  }
}
