import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_presentation/presentation.dart';

abstract final class PlatformAuditUiMapper {
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

  static String localizedTitle(String title, {String? actionCode}) {
    if (title.isNotEmpty && _localizedEventTitles.containsKey(title)) {
      return _localizedEventTitles[title]!;
    }
    if (actionCode != null && _localizedEventTitles.containsKey(actionCode)) {
      return _localizedEventTitles[actionCode]!;
    }
    if (title.isNotEmpty && !title.contains('.')) {
      return title;
    }
    final code = title.isNotEmpty ? title : (actionCode ?? '');
    if (code.isEmpty) return '—';
    final parts = code.split('.');
    if (parts.isNotEmpty) {
      return parts.last.replaceAll('_', ' ');
    }
    return code;
  }

  static (String subjectLabel, String subjectValue, String detailLabel, String detailValue)
      _resolveTargetInfo({
    required String targetOrgName,
    required String targetOrgCode,
    required String actionCode,
    required String actorName,
  }) {
    final name = (targetOrgName.isNotEmpty &&
            targetOrgName != 'account' &&
            targetOrgName != 'tenant' &&
            targetOrgName != 'membership')
        ? targetOrgName
        : (actorName.isNotEmpty ? actorName : '—');

    final code = (targetOrgCode.isNotEmpty &&
            targetOrgCode != 'account' &&
            targetOrgCode != 'tenant' &&
            targetOrgCode != 'membership')
        ? targetOrgCode
        : '—';

    return ('Tổ chức', name, 'Mã tổ chức', code);
  }

  static AuditLogStatus toUiStatus(PlatformAuditLogStatus status) {
    return switch (status) {
      PlatformAuditLogStatus.success => AuditLogStatus.success,
      PlatformAuditLogStatus.blocked => AuditLogStatus.blocked,
      PlatformAuditLogStatus.error => AuditLogStatus.error,
    };
  }

  static String statusLabel(PlatformAuditLogStatus status) {
    return switch (status) {
      PlatformAuditLogStatus.success => 'Thành công',
      PlatformAuditLogStatus.blocked => 'Bị chặn',
      PlatformAuditLogStatus.error => 'Lỗi',
    };
  }

  static AuditLogItemUiModel fromSummary(PlatformAuditLogSummaryDto dto) {
    final targetInfo = _resolveTargetInfo(
      targetOrgName: dto.targetOrgName,
      targetOrgCode: dto.targetOrgCode,
      actionCode: dto.actionCode,
      actorName: dto.actorName,
    );
    return AuditLogItemUiModel(
      id: dto.id.startsWith('#') ? dto.id : '#${dto.id}',
      title: localizedTitle(dto.title, actionCode: dto.actionCode),
      actionCode: dto.actionCode,
      status: toUiStatus(dto.status),
      statusLabel: statusLabel(dto.status),
      actorName: dto.actorName,
      actorRole: dto.actorRole,
      targetOrg: dto.targetOrgName,
      targetOrgCode: dto.targetOrgCode,
      targetSubjectLabel: targetInfo.$1,
      targetSubjectValue: targetInfo.$2,
      targetDetailLabel: targetInfo.$3,
      targetDetailValue: targetInfo.$4,
      timestamp: dto.timestamp,
      sourceApp: dto.sourceApp,
      correlationId: '',
      beforeState: '',
      afterState: '',
      icon: VIcons.edit,
    );
  }

  static AuditLogItemUiModel fromDetail(PlatformAuditLogDetailDto dto) {
    final targetInfo = _resolveTargetInfo(
      targetOrgName: dto.targetOrgName,
      targetOrgCode: dto.targetOrgCode,
      actionCode: dto.actionCode,
      actorName: dto.actorName,
    );
    return AuditLogItemUiModel(
      id: dto.id.startsWith('#') ? dto.id : '#${dto.id}',
      title: localizedTitle(dto.title, actionCode: dto.actionCode),
      actionCode: dto.actionCode,
      status: toUiStatus(dto.status),
      statusLabel: dto.statusLabel.isEmpty ? statusLabel(dto.status) : dto.statusLabel,
      actorName: dto.actorName,
      actorRole: dto.actorRole,
      targetOrg: dto.targetOrgName,
      targetOrgCode: dto.targetOrgCode,
      targetSubjectLabel: targetInfo.$1,
      targetSubjectValue: targetInfo.$2,
      targetDetailLabel: targetInfo.$3,
      targetDetailValue: targetInfo.$4,
      timestamp: dto.timestamp,
      sourceApp: dto.sourceApp,
      correlationId: dto.correlationId,
      beforeState: dto.beforeState,
      afterState: dto.afterState,
      icon: VIcons.edit,
    );
  }
}
