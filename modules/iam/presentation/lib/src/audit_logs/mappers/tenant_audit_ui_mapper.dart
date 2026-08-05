import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';

import '../models/audit_log_ui_model.dart';

abstract final class TenantAuditUiMapper {
  static AuditLogItemUiModel fromSummary(TenantAuditLogSummaryDto dto) {
    final status = _status(dto.result);
    return AuditLogItemUiModel(
      id: dto.auditLogId,
      title: _titleFromEvent(dto.eventCode),
      actionCode: dto.eventCode,
      status: status,
      statusLabel: _statusLabel(status),
      actorName: dto.actorDisplayName ?? dto.actorUserId ?? '—',
      actorRole: dto.subjectType ?? '—',
      targetOrg: dto.subjectId ?? '',
      targetOrgCode: dto.subjectId ?? '',
      timestamp: dto.occurredAt.toLocal(),
      sourceApp: dto.source,
      correlationId: dto.trackingId,
      beforeState: '',
      afterState: '',
      icon: VIcons.history,
      category: dto.subjectType,
      targetSubjectLabel: 'Đối tượng',
      targetSubjectValue: dto.subjectType ?? '—',
      targetDetailLabel: 'Mã đối tượng',
      targetDetailValue: dto.subjectId ?? '—',
    );
  }

  static AuditLogItemUiModel fromDetail(TenantAuditLogDetailDto dto) {
    final status = _status(dto.result);
    final actorUnavailable = dto.actorUnavailable;
    return AuditLogItemUiModel(
      id: dto.auditLogId,
      title: _titleFromEvent(dto.eventCode),
      actionCode: dto.eventCode,
      status: status,
      statusLabel: _statusLabel(status),
      actorName: actorUnavailable
          ? 'Không còn thông tin người thực hiện'
          : (dto.actorDisplayName ?? dto.actorUserId ?? '—'),
      actorRole: dto.subjectType ?? '—',
      targetOrg: dto.subjectId ?? '',
      targetOrgCode: dto.subjectId ?? '',
      timestamp: dto.occurredAt.toLocal(),
      sourceApp: dto.source,
      correlationId: dto.trackingId,
      beforeState: dto.beforeRedacted ? '' : (dto.beforeState ?? ''),
      afterState: dto.afterRedacted ? '' : (dto.afterState ?? ''),
      icon: VIcons.history,
      category: dto.subjectType,
      targetSubjectLabel: 'Loại đối tượng',
      targetSubjectValue: dto.subjectType ?? '—',
      targetDetailLabel: 'Mã đối tượng',
      targetDetailValue: dto.subjectId ?? '—',
      changeSectionTitle: 'Dữ liệu thay đổi',
      isActorUnavailable: actorUnavailable,
      beforeRedacted: dto.beforeRedacted,
      afterRedacted: dto.afterRedacted,
    );
  }

  static AuditLogStatus _status(TenantAuditLogResult result) {
    return switch (result) {
      TenantAuditLogResult.success => AuditLogStatus.success,
      TenantAuditLogResult.blocked => AuditLogStatus.blocked,
      TenantAuditLogResult.error => AuditLogStatus.error,
    };
  }

  static String _statusLabel(AuditLogStatus status) {
    return switch (status) {
      AuditLogStatus.success => 'Thành công',
      AuditLogStatus.blocked => 'Bị chặn',
      AuditLogStatus.error => 'Lỗi',
    };
  }

  static String _titleFromEvent(String eventCode) {
    final localized = _localizedEventTitles[eventCode];
    if (localized != null) return localized;

    final parts = eventCode.split('.');
    if (parts.isEmpty) return eventCode;
    return parts.last.replaceAll('_', ' ');
  }

  static const Map<String, String> _localizedEventTitles = {
    IamAuditEvents.membershipDeactivated: 'Tạm ngừng thành viên',
    IamAuditEvents.membershipReactivated: 'Kích hoạt lại thành viên',
    IamAuditEvents.membershipRemoved: 'Loại thành viên khỏi tổ chức',
    IamAuditEvents.tenantProfileUpdated: 'Cập nhật hồ sơ tổ chức',
    'iam.tenant.profile.updated': 'Cập nhật hồ sơ tổ chức',
    IamAuditEvents.tenantLegalProfileUpdated: 'Cập nhật hồ sơ pháp lý',
    IamAuditEvents.tenantActivated: 'Kích hoạt tổ chức',
    IamAuditEvents.tenantSuspended: 'Tạm ngừng tổ chức',
    IamAuditEvents.tenantRestored: 'Khôi phục tổ chức',
    IamAuditEvents.tenantOwnershipTransferred: 'Chuyển chủ sở hữu tổ chức',
    IamAuditEvents.accountProfileUpdated: 'Cập nhật hồ sơ cá nhân',
    IamAuditEvents.accountPasswordResetCompleted: 'Đặt lại mật khẩu',
    IamAuditEvents.accountSignedOut: 'Đăng xuất tài khoản',
    'tenant.invitation.created': 'Tạo lời mời',
    'tenant.invitation.resent': 'Gửi lại lời mời',
    'tenant.invitation.accepted': 'Chấp nhận lời mời',
    'tenant.invitation.revoked': 'Thu hồi lời mời',
    'platform.tenant.suspend': 'Tạm ngừng tổ chức',
    'platform.tenant.restore': 'Khôi phục tổ chức',
    'platform.tenant.onboard': 'Khởi tạo tổ chức',
    'platform.access.denied': 'Từ chối thao tác không đủ quyền',
    'platform.policy.refresh': 'Làm mới chính sách quyền',
  };
}
