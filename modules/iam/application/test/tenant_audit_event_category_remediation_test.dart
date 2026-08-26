import 'package:test/test.dart';
import 'package:vet45_iam_application/application.dart';

void main() {
  test('summary and detail preserve nullable backend event category', () {
    const actor = TenantAuditActorDto();
    const subject = TenantAuditSubjectDto();
    final occurredAt = DateTime.utc(2026, 8, 20);

    final categorizedSummary = TenantAuditLogSummaryDto(
      auditLogId: 'audit-summary',
      eventCode: IamAuditEvents.tenantActivated,
      eventCategory: TenantAuditEventCategory.security,
      result: TenantAuditLogResult.success,
      occurredAt: occurredAt,
      source: 'iam',
      trackingId: 'tracking-summary',
      actor: actor,
      subject: subject,
    );
    final legacyDetail = TenantAuditLogDetailDto(
      auditLogId: 'audit-detail',
      tenantId: 'tenant-1',
      eventCode: IamAuditEvents.tenantActivated,
      result: TenantAuditLogResult.success,
      occurredAt: occurredAt,
      source: 'iam',
      trackingId: 'tracking-detail',
      actorUnavailable: false,
      beforeRedacted: false,
      afterRedacted: false,
      actor: actor,
      subject: subject,
    );

    expect(categorizedSummary.eventCategory, TenantAuditEventCategory.security);
    expect(legacyDetail.eventCategory, isNull);
  });
}
