import 'package:flutter_test/flutter_test.dart';
import 'package:erp/core/iam/iam_codes.dart';
import 'package:erp/features/iam/data/models/tenant_audit_log.dart';

import 'package:erp/features/iam/presentation/audit_logs/mappers/tenant_audit_ui_mapper.dart';

void main() {
  group('TenantAuditUiMapper remediation', () {
    test('uses backend category and falls back to catalog only when null', () {
      final backendCategory = TenantAuditUiMapper.fromSummary(
        _summary(eventCategory: TenantAuditEventCategory.security),
      );
      final legacyCategory = TenantAuditUiMapper.fromSummary(_summary());

      expect(
        backendCategory.eventCategory,
        TenantAuditEventCategory.security,
      );
      expect(backendCategory.category, 'security');
      expect(
        legacyCategory.eventCategory,
        TenantAuditEventCategory.organization,
      );
    });

    test('unknown event has neutral title and retains raw event code', () {
      final ui = TenantAuditUiMapper.fromSummary(
        _summary(eventCode: 'iam.internal.rotated_credential_bundle'),
      );

      expect(ui.title, 'Hoạt động quản trị');
      expect(ui.actionCode, 'iam.internal.rotated_credential_bundle');
      expect(ui.title, isNot(contains('rotated credential bundle')));
    });

    test('preserves actor and subject forensic fields without ID guessing', () {
      final ui = TenantAuditUiMapper.fromSummary(
        _summary(
          actor: const TenantAuditActorDto(
            userId: 'actor-uuid',
            actorType: 'service_account',
            roleCode: 'tenant_owner',
            displayOrigin: TenantAuditDisplayOrigin.unavailable,
          ),
          subject: const TenantAuditSubjectDto(
            type: 'tenant',
            id: 'subject-uuid',
            code: 'TEN-001',
            displayOrigin: TenantAuditDisplayOrigin.unavailable,
          ),
        ),
      );

      expect(ui.actorName, 'Không còn thông tin người thực hiện');
      expect(ui.actorId, 'actor-uuid');
      expect(ui.actorType, 'service_account');
      expect(ui.actorRoleCode, 'tenant_owner');
      expect(ui.subjectName, 'Không còn thông tin đối tượng');
      expect(ui.subjectType, 'tenant');
      expect(ui.subjectId, 'subject-uuid');
      expect(ui.subjectCode, 'TEN-001');
      expect(ui.targetOrg, isNot('subject-uuid'));
    });

    test('deep-equal values are skipped and sensitive fields are masked', () {
      final ui = TenantAuditUiMapper.fromDetail(
        _detail(
          beforeState: const {
            'same_scalar': 1,
            'same_list': [
              1,
              {'nested': true},
            ],
            'same_map': {
              'alpha': [1, 2],
            },
            'profile': {'name': 'Cũ'},
            'password_hash': 'raw-old-hash',
          },
          afterState: const {
            'same_scalar': 1,
            'same_list': [
              1,
              {'nested': true},
            ],
            'same_map': {
              'alpha': [1, 2],
            },
            'profile': {'name': 'Mới'},
            'password_hash': 'raw-new-hash',
          },
        ),
      );

      expect(
        ui.changes.map((change) => change.fieldKey),
        ['password_hash', 'profile'],
      );
      final password = ui.changes.first;
      expect(password.beforeValue, '[Đã che theo chính sách]');
      expect(password.afterValue, '[Đã che theo chính sách]');
      expect(password.beforeValue, isNot(contains('raw-old-hash')));
      expect(password.afterValue, isNot(contains('raw-new-hash')));
    });

    test('redacts each side independently without formatting its raw values', () {
      final beforeRedacted = TenantAuditUiMapper.fromDetail(
        _detail(
          beforeRedacted: true,
          beforeState: const {'display_name': 'RAW-BEFORE'},
          afterState: const {'display_name': 'Visible after'},
        ),
      );
      final afterRedacted = TenantAuditUiMapper.fromDetail(
        _detail(
          afterRedacted: true,
          beforeState: const {'display_name': 'Visible before'},
          afterState: const {'display_name': 'RAW-AFTER'},
        ),
      );

      expect(beforeRedacted.changes.single.beforeValue, '[Đã che theo chính sách]');
      expect(beforeRedacted.changes.single.afterValue, 'Visible after');
      expect(beforeRedacted.beforeState, isNot(contains('RAW-BEFORE')));
      expect(afterRedacted.changes.single.beforeValue, 'Visible before');
      expect(afterRedacted.changes.single.afterValue, '[Đã che theo chính sách]');
      expect(afterRedacted.afterState, isNot(contains('RAW-AFTER')));
    });
  });
}

TenantAuditLogSummaryDto _summary({
  String eventCode = IamAuditEvents.tenantActivated,
  TenantAuditEventCategory? eventCategory,
  TenantAuditActorDto actor = const TenantAuditActorDto(),
  TenantAuditSubjectDto subject = const TenantAuditSubjectDto(),
}) {
  return TenantAuditLogSummaryDto(
    auditLogId: 'audit-summary',
    eventCode: eventCode,
    eventCategory: eventCategory,
    result: TenantAuditLogResult.success,
    occurredAt: DateTime.utc(2026, 8, 20),
    source: 'iam',
    trackingId: 'tracking-summary',
    actor: actor,
    subject: subject,
  );
}

TenantAuditLogDetailDto _detail({
  bool beforeRedacted = false,
  bool afterRedacted = false,
  Map<String, Object?>? beforeState,
  Map<String, Object?>? afterState,
}) {
  return TenantAuditLogDetailDto(
    auditLogId: 'audit-detail',
    tenantId: 'tenant-1',
    eventCode: IamAuditEvents.tenantProfileUpdated,
    result: TenantAuditLogResult.success,
    occurredAt: DateTime.utc(2026, 8, 20),
    source: 'iam',
    trackingId: 'tracking-detail',
    actorUnavailable: false,
    beforeRedacted: beforeRedacted,
    afterRedacted: afterRedacted,
    actor: const TenantAuditActorDto(),
    subject: const TenantAuditSubjectDto(),
    beforeState: beforeState,
    afterState: afterState,
  );
}
