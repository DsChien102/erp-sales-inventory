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
    String targetType = '',
    String targetDisplayName = '',
  }) {
    final tt = targetType.trim().toLowerCase();
    final isUserTarget = tt == 'account' || tt == 'platformuser' || tt == 'user';

    if (isUserTarget) {
      final name = targetDisplayName.isNotEmpty
          ? targetDisplayName
          : (actorName.isNotEmpty ? actorName : '—');
      final code =
          (targetOrgCode.isNotEmpty &&
              targetOrgCode != 'account' &&
              targetOrgCode != 'tenant' &&
              targetOrgCode != 'membership')
          ? targetOrgCode
          : '—';
      return ('Người dùng', name, 'Mã người dùng', code);
    }

    final name = targetDisplayName.isNotEmpty
        ? targetDisplayName
        : ((targetOrgName.isNotEmpty &&
                  targetOrgName != 'account' &&
                  targetOrgName != 'tenant' &&
                  targetOrgName != 'membership')
              ? targetOrgName
              : (actorName.isNotEmpty ? actorName : '—'));

    final code =
        (targetOrgCode.isNotEmpty &&
            targetOrgCode != 'account' &&
            targetOrgCode != 'tenant' &&
            targetOrgCode != 'membership')
        ? targetOrgCode
        : '—';

    return ('Tổ chức', name, 'Mã tổ chức', code);
  }

  /// Dựng danh sách thay đổi (diff Trước/Sau) từ before/after (đã redact lúc ghi),
  /// dùng chung catalog nhãn field/giá trị với tenant audit.
  static List<AuditLogChangeRowUiModel> _computeChanges(
    Map<String, Object?> before,
    Map<String, Object?> after,
  ) {
    if (before.isEmpty && after.isEmpty) return const [];
    final keys = <String>{...before.keys, ...after.keys}.toList()..sort();
    final rows = <AuditLogChangeRowUiModel>[];
    for (final key in keys) {
      final b = before[key];
      final a = after[key];
      if (b?.toString() == a?.toString()) continue;
      rows.add(
        AuditLogChangeRowUiModel(
          fieldKey: key,
          fieldLabel: TenantAuditFieldCatalog.labelFor(key),
          beforeValue: TenantAuditFieldCatalog.formatValue(key, b),
          afterValue: TenantAuditFieldCatalog.formatValue(key, a),
          isChanged: true,
        ),
      );
    }
    return rows;
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
      sourceApp: _sourceLabel(dto.sourceApp),
      correlationId: '',
      beforeState: '',
      afterState: '',
      icon: VIcons.edit,
    );
  }

  /// Nhãn nguồn hiển thị cho người dùng (thay cho mã raw như `iam`/`admin`).
  static String _sourceLabel(String source) {
    switch (source.trim().toLowerCase()) {
      case 'platform_admin_app':
      case 'admin':
        return 'Platform Admin App';
      case 'tenant_app':
        return 'Tenant App';
      case 'auth':
        return 'Xác thực';
      case 'iam':
        return 'Hệ thống IAM';
      case 'system':
        return 'Hệ thống';
      case '':
        return '—';
      default:
        return source;
    }
  }

  static AuditLogItemUiModel fromDetail(PlatformAuditLogDetailDto dto) {
    final targetInfo = _resolveTargetInfo(
      targetOrgName: dto.targetOrgName,
      targetOrgCode: dto.targetOrgCode,
      actionCode: dto.actionCode,
      actorName: dto.actorName,
      targetType: dto.targetType,
      targetDisplayName: dto.targetDisplayName,
    );
    final changes = _computeChanges(dto.changeBefore, dto.changeAfter);
    return AuditLogItemUiModel(
      id: dto.id.startsWith('#') ? dto.id : '#${dto.id}',
      auditDisplayId: dto.auditNo > 0 ? 'AUD-${dto.auditNo.toString().padLeft(6, '0')}' : null,
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
      // Render "Đối tượng" đọc subjectName (fallback targetOrg) → set giá trị đã resolve.
      subjectName: targetInfo.$2 == '—' ? '' : targetInfo.$2,
      timestamp: dto.timestamp,
      sourceApp: _sourceLabel(dto.sourceApp),
      correlationId: dto.correlationId,
      beforeState: dto.beforeState,
      afterState: dto.afterState,
      changes: changes,
      icon: VIcons.edit,
    );
  }
}
