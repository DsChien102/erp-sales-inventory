import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:erp/features/iam/presentation/audit_logs/catalog/tenant_audit_event_catalog.dart';

void main() {
  group('TenantAuditEventCatalog', () {
    test('covers all 19 canonical IamAuditEvents with Vietnamese titles and icons', () {
      for (final eventCode in IamAuditEvents.all) {
        final entry = TenantAuditEventCatalog.entryFor(eventCode);
        expect(entry.eventCode, eventCode);
        expect(entry.title, isNotEmpty);
        expect(entry.category, isNotNull);
        expect(entry.icon, isNotNull);
      }
    });

    test('matchingEventCodes resolves complete localized titles and aliases only', () {
      expect(
        TenantAuditEventCatalog.matchingEventCodes('Cập nhật hồ sơ tổ chức'),
        contains('iam.tenant.profile_updated'),
      );
      expect(
        TenantAuditEventCatalog.matchingEventCodes('đổi mật khẩu'),
        contains('iam.account.password_reset_completed'),
      );
      expect(
        TenantAuditEventCatalog.matchingEventCodes('iam.tenant.activated'),
        isEmpty,
        reason: 'raw event-code input must remain backend free text',
      );
      expect(
        TenantAuditEventCatalog.matchingEventCodes('mời'),
        isEmpty,
        reason: 'partial localized aliases must remain backend free text',
      );
      expect(
        TenantAuditEventCatalog.matchingEventCodes('mời thành viên'),
        contains('iam.tenant.invitation_created'),
      );
    });

    test('codesForCategory partitions events accurately', () {
      final orgEvents = TenantAuditEventCatalog.codesForCategory(
        TenantAuditEventCategory.organization,
      );
      expect(orgEvents, contains('iam.tenant.profile_updated'));
      expect(orgEvents, contains('iam.tenant.activated'));
      expect(orgEvents, contains('iam.tenant.suspended'));

      final memberEvents = TenantAuditEventCatalog.codesForCategory(
        TenantAuditEventCategory.member,
      );
      expect(memberEvents, contains('iam.membership.deactivated'));
      expect(memberEvents, contains('iam.membership.reactivated'));
      expect(memberEvents, contains('iam.membership.removed'));
    });

    test('fallback entry keeps raw code with a neutral business title', () {
      final fallback = TenantAuditEventCatalog.entryFor('iam.custom.something_special');
      expect(fallback.title, 'Hoạt động quản trị');
      expect(fallback.eventCode, 'iam.custom.something_special');
      expect(fallback.category, TenantAuditEventCategory.system);
    });
  });
}
