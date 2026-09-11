import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:erp/features/iam/presentation/audit_logs/mappers/tenant_audit_ui_mapper.dart';

void main() {
  test('unavailable actor keeps real ID without inferring account lifecycle role', () {
    final ui = TenantAuditUiMapper.fromSummary(
      TenantAuditLogSummaryDto(
        auditLogId: 'audit-unavailable',
        eventCode: IamAuditEvents.tenantActivated,
        result: TenantAuditLogResult.success,
        occurredAt: DateTime.utc(2026, 8, 20),
        source: 'iam',
        trackingId: 'tracking-unavailable',
        actor: const TenantAuditActorDto(
          userId: 'actor-real-id',
          roleCode: 'tenant_owner',
          roleLabel: 'Chủ sở hữu',
          displayOrigin: TenantAuditDisplayOrigin.unavailable,
        ),
        subject: const TenantAuditSubjectDto(),
      ),
    );

    expect(ui.actorName, 'Không còn thông tin người thực hiện');
    expect(ui.actorId, 'actor-real-id');
    expect(ui.actorRole, '—');
    expect(ui.actorRole, isNot('Tài khoản đã ngừng'));
  });
}
