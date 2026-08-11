import 'package:admin/features/audit/presentation/mappers/platform_audit_ui_mapper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_iam_application/application.dart';

void main() {
  group('PlatformAuditUiMapper', () {
    test('localizes event codes to Vietnamese titles', () {
      final cases = {
        'iam.account.profile_updated': 'Cập nhật hồ sơ cá nhân',
        'iam.tenant.restored': 'Khôi phục tổ chức',
        'iam.tenant.suspended': 'Tạm ngừng tổ chức',
        'iam.tenant.profile_updated': 'Cập nhật hồ sơ tổ chức',
        'iam.tenant.profile.updated': 'Cập nhật hồ sơ tổ chức',
        'iam.account.password_reset_completed': 'Đặt lại mật khẩu',
        'iam.account.signed_out': 'Đăng xuất tài khoản',
        'platform.tenant.suspend': 'Tạm ngừng tổ chức',
        'platform.access.denied': 'Từ chối thao tác không đủ quyền',
      };

      for (final entry in cases.entries) {
        final dto = PlatformAuditLogSummaryDto(
          id: '1',
          title: entry.key,
          actionCode: entry.key,
          status: PlatformAuditLogStatus.success,
          actorName: 'User Test',
          actorRole: 'Role',
          targetOrgName: 'Org',
          targetOrgCode: 'ORG-01',
          timestamp: DateTime(2026, 8, 4),
          sourceApp: 'app',
        );

        final model = PlatformAuditUiMapper.fromSummary(dto);
        expect(model.title, entry.value, reason: 'Failed for ${entry.key}');
      }
    });

    test('preserves already localized non-dotted titles', () {
      final dto = PlatformAuditLogSummaryDto(
        id: '2',
        title: 'Đã tạm ngừng tổ chức',
        actionCode: 'platform.tenant.suspend',
        status: PlatformAuditLogStatus.success,
        actorName: 'User Test',
        actorRole: 'Role',
        targetOrgName: 'Org',
        targetOrgCode: 'ORG-01',
        timestamp: DateTime(2026, 8, 4),
        sourceApp: 'app',
      );

      final model = PlatformAuditUiMapper.fromSummary(dto);
      expect(model.title, 'Đã tạm ngừng tổ chức');
    });

    test('maps targetSubjectValue and targetDetailValue for account and tenant events', () {
      final accountDto = PlatformAuditLogDetailDto(
        id: 'eb45b531-9463-400e-8e5b-d2c46468d25e',
        title: 'iam.account.profile_updated',
        actionCode: 'iam.account.profile_updated',
        status: PlatformAuditLogStatus.success,
        statusLabel: 'Thành công',
        actorName: 'Đỗ Sỹ Chiến',
        actorRole: 'Nhân viên vận hành nền tảng',
        targetOrgName: '',
        targetOrgCode: '',
        timestamp: DateTime(2026, 8, 4, 3, 28),
        sourceApp: 'iam',
        correlationId: '4e3535c5',
        beforeState: '',
        afterState: '{"given_name": "Đỗ Sỹ"}',
      );

      final model = PlatformAuditUiMapper.fromDetail(accountDto);
      expect(model.targetSubjectLabel, 'Tổ chức');
      expect(model.targetSubjectValue, 'Đỗ Sỹ Chiến');
      expect(model.targetDetailLabel, 'Mã tổ chức');

      final tenantDto = PlatformAuditLogDetailDto(
        id: 'audit-001',
        title: 'iam.tenant.restored',
        actionCode: 'iam.tenant.restored',
        status: PlatformAuditLogStatus.success,
        statusLabel: 'Thành công',
        actorName: 'Admin',
        actorRole: 'Admin Role',
        targetOrgName: 'VietVet Trading',
        targetOrgCode: 'TEN-000095',
        timestamp: DateTime(2026, 8, 4),
        sourceApp: 'iam',
        correlationId: 'corr-01',
        beforeState: '',
        afterState: '',
      );

      final tenantModel = PlatformAuditUiMapper.fromDetail(tenantDto);
      expect(tenantModel.targetSubjectLabel, 'Tổ chức');
      expect(tenantModel.targetSubjectValue, 'VietVet Trading');
      expect(tenantModel.targetDetailLabel, 'Mã tổ chức');
      expect(tenantModel.targetDetailValue, 'TEN-000095');
    });
  });
}
