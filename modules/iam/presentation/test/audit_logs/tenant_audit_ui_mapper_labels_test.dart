import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_presentation/src/audit_logs/mappers/tenant_audit_ui_mapper.dart';

void main() {
  group('TenantAuditUiMapper labels', () {
    test('localizes known IAM audit event titles', () {
      final cases = {
        IamAuditEvents.accountProfileUpdated: 'Cập nhật hồ sơ cá nhân',
        IamAuditEvents.tenantProfileUpdated: 'Cập nhật hồ sơ tổ chức',
        'tenant.invitation.accepted': 'Chấp nhận lời mời',
        'tenant.invitation.created': 'Tạo lời mời',
        'tenant.invitation.revoked': 'Thu hồi lời mời',
      };

      for (final entry in cases.entries) {
        final ui = TenantAuditUiMapper.fromSummary(
          _summary(eventCode: entry.key),
        );

        expect(ui.title, entry.value);
      }
    });

    test('falls back to readable event suffix for unknown event codes', () {
      final ui = TenantAuditUiMapper.fromSummary(
        _summary(eventCode: 'iam.custom.some_new_event'),
      );

      expect(ui.title, 'some new event');
    });
  });
}

TenantAuditLogSummaryDto _summary({required String eventCode}) {
  return TenantAuditLogSummaryDto(
    auditLogId: 'audit-1',
    eventCode: eventCode,
    result: TenantAuditLogResult.success,
    occurredAt: DateTime.utc(2026, 8, 2, 8, 35),
    source: 'erp',
    trackingId: 'tracking-1',
    actorUserId: 'user-1',
    actorDisplayName: 'Lan Le',
    subjectType: 'tenant',
    subjectId: 'tenant-1',
  );
}
