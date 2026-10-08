import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_iam_application/application.dart' hide TenantAuditEventCategory, TenantAuditLogResult, TenantAuditDisplayOrigin, TenantAuditLogSummaryDto, TenantAuditLogDetailDto, TenantAuditActorDto, TenantAuditSubjectDto;
import 'package:erp/features/iam/data/models/tenant_audit_log.dart';

import 'package:erp/features/iam/presentation/audit_logs/mappers/tenant_audit_ui_mapper.dart';

void main() {
  group('TenantAuditUiMapper', () {
    test('localizes known IAM audit event titles from catalog', () {
      final cases = {
        IamAuditEvents.accountProfileUpdated: 'Cập nhật thông tin tài khoản',
        IamAuditEvents.tenantProfileUpdated: 'Cập nhật hồ sơ tổ chức',
        IamAuditEvents.invitationCreated: 'Tạo lời mời thành viên',
        IamAuditEvents.invitationAccepted: 'Chấp nhận lời mời tham gia',
        IamAuditEvents.invitationRevoked: 'Thu hồi lời mời thành viên',
      };

      for (final entry in cases.entries) {
        final ui = TenantAuditUiMapper.fromSummary(
          _summary(eventCode: entry.key),
        );

        expect(ui.title, entry.value);
      }
    });

    test('maps actor snapshot and subject snapshot correctly', () {
      final ui = TenantAuditUiMapper.fromSummary(
        TenantAuditLogSummaryDto(
          auditLogId: 'audit-1',
          eventCode: IamAuditEvents.tenantActivated,
          result: TenantAuditLogResult.success,
          occurredAt: DateTime.utc(2026, 8, 2, 8, 35),
          source: 'erp',
          trackingId: 'tracking-1',
          actor: const TenantAuditActorDto(
            displayName: 'Bác sĩ Lan Lê',
            roleLabel: 'Bác sĩ thú y',
            displayOrigin: TenantAuditDisplayOrigin.snapshot,
          ),
          subject: const TenantAuditSubjectDto(
            type: 'tenant',
            id: 'tenant-1',
            displayName: 'Chi nhánh Quận 1',
            code: 'VET-Q1',
            displayOrigin: TenantAuditDisplayOrigin.snapshot,
          ),
        ),
      );

      expect(ui.actorName, 'Bác sĩ Lan Lê');
      expect(ui.actorRole, 'Bác sĩ thú y');
      expect(ui.targetOrg, 'Chi nhánh Quận 1');
      expect(ui.targetOrgCode, 'VET-Q1');
      expect(ui.targetDetailValue, 'VET-Q1');
    });

    test('detail computes changes diff and formats payload using field catalog', () {
      final detail = TenantAuditUiMapper.fromDetail(
        TenantAuditLogDetailDto(
          auditLogId: 'audit-1',
          auditDisplayId: 'AUD-000982',
          tenantId: 'tenant-1',
          eventCode: IamAuditEvents.tenantProfileUpdated,
          result: TenantAuditLogResult.success,
          occurredAt: DateTime.utc(2026, 8, 2, 8, 35),
          source: 'erp',
          correlationId: 'corr-1',
          trackingId: 'tracking-1',
          actorUnavailable: false,
          beforeRedacted: false,
          afterRedacted: false,
          actor: const TenantAuditActorDto(
            displayName: 'Nguyễn Văn A',
            roleLabel: 'Chủ sở hữu',
            displayOrigin: TenantAuditDisplayOrigin.snapshot,
          ),
          subject: const TenantAuditSubjectDto(
            type: 'tenant',
            id: '7a3c8e61-1111-2222-3333-44444444b942',
            displayName: 'Chi nhánh 1',
            code: 'CN-1',
          ),
          beforeState: const {'status': 'suspended', 'display_name': 'Cửa hàng cũ'},
          afterState: const {'status': 'active', 'display_name': 'Cửa hàng mới'},
        ),
      );

      expect(detail.changes.length, 2);
      final statusChange = detail.changes.firstWhere((c) => c.fieldKey == 'status');
      expect(statusChange.fieldLabel, 'Trạng thái');
      expect(statusChange.beforeValue, 'Tạm ngừng');
      expect(statusChange.afterValue, 'Đang hoạt động');
      expect(statusChange.isChanged, isTrue);
      expect(detail.auditDisplayId, 'AUD-000982');
      expect(detail.correlationId, 'corr-1');
      expect(detail.targetSubjectLabel, 'Tổ chức');
      expect(detail.targetDetailLabel, 'ID đối tượng');
      expect(detail.targetDetailValue, '7a3c8e61…b942');
      expect(detail.sourceApp, 'Tenant App');
    });

    test('handles unavailable actor gracefully without UUID guessing', () {
      final ui = TenantAuditUiMapper.fromSummary(
        TenantAuditLogSummaryDto(
          auditLogId: 'audit-1',
          eventCode: IamAuditEvents.tenantActivated,
          result: TenantAuditLogResult.success,
          occurredAt: DateTime.utc(2026, 8, 2, 8, 35),
          source: 'erp',
          trackingId: 'tracking-1',
          actor: const TenantAuditActorDto(
            userId: '3fa85f64-5717-4562-b3fc-2c963f66afa6',
            displayOrigin: TenantAuditDisplayOrigin.unavailable,
          ),
          subject: const TenantAuditSubjectDto(type: 'tenant'),
        ),
      );

      expect(ui.actorName, 'Không còn thông tin người thực hiện');
      expect(ui.actorRole, '—');
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
    actor: const TenantAuditActorDto(
      displayName: 'Lan Le',
      roleLabel: 'Chủ sở hữu',
    ),
    subject: const TenantAuditSubjectDto(
      type: 'tenant',
      id: 'tenant-1',
      displayName: 'Phòng khám',
    ),
  );
}
