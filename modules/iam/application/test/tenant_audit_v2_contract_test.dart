import 'package:test/test.dart';
import 'package:vet45_iam_application/application.dart';

void main() {
  group('Tenant Audit V2 Application Contracts', () {
    test('SearchTenantAuditLogsQuery supports V2 search parameters', () {
      final from = DateTime.utc(2026, 8, 1);
      final to = DateTime.utc(2026, 9, 1);
      final query = SearchTenantAuditLogsQuery(
        tenantId: 'tenant-1',
        fromUtc: from,
        toUtc: to,
        query: 'Nguyễn Văn A',
        eventCategory: TenantAuditEventCategory.organization,
        eventCodes: const [IamAuditEvents.tenantActivated],
        limit: 20,
      );

      expect(query.tenantId, 'tenant-1');
      expect(query.fromUtc, from);
      expect(query.toUtc, to);
      expect(query.query, 'Nguyễn Văn A');
      expect(query.eventCategory, TenantAuditEventCategory.organization);
      expect(query.eventCodes, const [IamAuditEvents.tenantActivated]);
      expect(query.limit, 20);
    });

    test('TenantAuditEventCategory has required codes and fromCode parser', () {
      expect(TenantAuditEventCategory.member.code, 'member');
      expect(TenantAuditEventCategory.role.code, 'role');
      expect(TenantAuditEventCategory.organization.code, 'organization');
      expect(TenantAuditEventCategory.invitation.code, 'invitation');
      expect(TenantAuditEventCategory.account.code, 'account');
      expect(TenantAuditEventCategory.security.code, 'security');
      expect(TenantAuditEventCategory.system.code, 'system');

      expect(
        TenantAuditEventCategory.fromCode('organization'),
        TenantAuditEventCategory.organization,
      );
      expect(TenantAuditEventCategory.fromCode('unknown'), isNull);
      expect(TenantAuditEventCategory.fromCode(null), isNull);
    });

    test('TenantAuditDisplayOrigin has required codes and fromCode parser', () {
      expect(TenantAuditDisplayOrigin.snapshot.code, 'snapshot');
      expect(TenantAuditDisplayOrigin.current.code, 'current');
      expect(TenantAuditDisplayOrigin.system.code, 'system');
      expect(TenantAuditDisplayOrigin.unavailable.code, 'unavailable');

      expect(
        TenantAuditDisplayOrigin.fromCode('snapshot'),
        TenantAuditDisplayOrigin.snapshot,
      );
      expect(TenantAuditDisplayOrigin.fromCode('invalid'), isNull);
      expect(TenantAuditDisplayOrigin.fromCode(null), isNull);
    });

    test('TenantAuditActorDto and TenantAuditSubjectDto instantiate correctly', () {
      const actor = TenantAuditActorDto(
        userId: 'user-1',
        displayName: 'Nguyễn Văn A',
        actorType: 'user',
        roleCode: 'store_owner',
        roleLabel: 'Chủ sở hữu',
        displayOrigin: TenantAuditDisplayOrigin.snapshot,
      );

      expect(actor.userId, 'user-1');
      expect(actor.displayName, 'Nguyễn Văn A');
      expect(actor.actorType, 'user');
      expect(actor.roleCode, 'store_owner');
      expect(actor.roleLabel, 'Chủ sở hữu');
      expect(actor.displayOrigin, TenantAuditDisplayOrigin.snapshot);

      const subject = TenantAuditSubjectDto(
        type: 'tenant',
        id: 'tenant-1',
        displayName: 'Phòng khám Vet 45',
        code: 'VET45-HCM',
        secondaryLabel: null,
        displayOrigin: TenantAuditDisplayOrigin.snapshot,
      );

      expect(subject.type, 'tenant');
      expect(subject.id, 'tenant-1');
      expect(subject.displayName, 'Phòng khám Vet 45');
      expect(subject.code, 'VET45-HCM');
      expect(subject.secondaryLabel, isNull);
      expect(subject.displayOrigin, TenantAuditDisplayOrigin.snapshot);
    });

    test('TenantAuditLogSummaryDto and PageDto preserve V2 properties', () {
      const actor = TenantAuditActorDto(
        userId: 'user-1',
        displayName: 'Nguyễn Văn A',
        actorType: 'user',
        roleCode: 'store_owner',
        roleLabel: 'Chủ sở hữu',
        displayOrigin: TenantAuditDisplayOrigin.snapshot,
      );

      const subject = TenantAuditSubjectDto(
        type: 'tenant',
        id: 'tenant-1',
        displayName: 'Phòng khám Vet 45',
        code: 'VET45-HCM',
        secondaryLabel: null,
        displayOrigin: TenantAuditDisplayOrigin.snapshot,
      );

      final summary = TenantAuditLogSummaryDto(
        auditLogId: 'audit-1',
        eventCode: IamAuditEvents.tenantActivated,
        result: TenantAuditLogResult.success,
        occurredAt: DateTime.utc(2026, 8, 20),
        source: 'iam',
        trackingId: 'track-1',
        actor: actor,
        subject: subject,
      );

      final page = TenantAuditLogSearchPageDto(
        items: [summary],
        totalCount: 37,
        nextCursor: 'cursor-1',
      );

      expect(page.items.length, 1);
      expect(page.totalCount, 37);
      expect(page.nextCursor, 'cursor-1');
      expect(page.items.first.actor.displayName, 'Nguyễn Văn A');
      expect(page.items.first.subject.displayName, 'Phòng khám Vet 45');
    });

    test('TenantAuditLogDetailDto accepts Map<String, Object?> before and after states', () {
      const actor = TenantAuditActorDto(
        userId: 'user-1',
        displayName: 'Nguyễn Văn A',
        actorType: 'user',
        roleCode: 'store_owner',
        roleLabel: 'Chủ sở hữu',
        displayOrigin: TenantAuditDisplayOrigin.snapshot,
      );

      const subject = TenantAuditSubjectDto(
        type: 'tenant',
        id: 'tenant-1',
        displayName: 'Phòng khám Vet 45',
        code: 'VET45-HCM',
        secondaryLabel: null,
        displayOrigin: TenantAuditDisplayOrigin.snapshot,
      );

      final detail = TenantAuditLogDetailDto(
        auditLogId: 'audit-1',
        auditDisplayId: 'AUD-000982',
        tenantId: 'tenant-1',
        activityCode: IamAuditEvents.tenantActivated,
        eventCode: IamAuditEvents.tenantActivated,
        titleSnapshot: 'Đã kích hoạt tổ chức',
        result: TenantAuditLogResult.success,
        occurredAt: DateTime.utc(2026, 8, 20),
        source: 'iam',
        correlationId: 'corr-1',
        trackingId: 'track-1',
        actorUnavailable: false,
        beforeRedacted: false,
        afterRedacted: false,
        actor: actor,
        subject: subject,
        beforeState: const {'status': 'pending', 'version': 1},
        afterState: const {'status': 'active', 'version': 2},
      );

      expect(detail.beforeState?['status'], 'pending');
      expect(detail.auditDisplayId, 'AUD-000982');
      expect(detail.correlationId, 'corr-1');
      expect(detail.afterState?['status'], 'active');
      expect(detail.actor.displayName, 'Nguyễn Văn A');
      expect(detail.subject.code, 'VET45-HCM');
    });
  });
}
