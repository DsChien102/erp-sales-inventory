import 'package:test/test.dart';
import 'package:vet45_iam_application/application.dart';

void main() {
  group('IamAuditEvents minimum set', () {
    test('contains all required event codes', () {
      expect(IamAuditEvents.all, hasLength(19));
      expect(IamAuditEvents.all.toSet(), hasLength(19));
    });

    test('every code is namespaced under iam.', () {
      for (final code in IamAuditEvents.all) {
        expect(code, startsWith('iam.'));
      }
    });

    test('covers membership, role, tenant, invitation and account domains', () {
      expect(IamAuditEvents.all, contains('iam.membership.deactivated'));
      expect(IamAuditEvents.all, contains('iam.membership.reactivated'));
      expect(IamAuditEvents.all, contains('iam.membership.removed'));
      expect(IamAuditEvents.all, contains('iam.tenant.member_role_assigned'));
      expect(IamAuditEvents.all, contains('iam.tenant.profile_updated'));
      expect(IamAuditEvents.all, contains('iam.tenant.legal_profile_updated'));
      expect(IamAuditEvents.all, contains('iam.tenant.activated'));
      expect(IamAuditEvents.all, contains('iam.tenant.suspended'));
      expect(IamAuditEvents.all, contains('iam.tenant.restored'));
      expect(IamAuditEvents.all, contains('iam.tenant.ownership_transferred'));
      expect(IamAuditEvents.all, contains('iam.tenant.owner_activated'));
      expect(IamAuditEvents.all, contains('iam.tenant.invitation_created'));
      expect(IamAuditEvents.all, contains('iam.tenant.invitation_resent'));
      expect(IamAuditEvents.all, contains('iam.tenant.invitation_revoked'));
      expect(IamAuditEvents.all, contains('iam.tenant.invitation_accepted'));
      expect(IamAuditEvents.all, contains('iam.account.profile_updated'));
      expect(IamAuditEvents.all, contains('iam.user.profile_updated'));
      expect(
        IamAuditEvents.all,
        contains('iam.account.password_reset_completed'),
      );
      expect(IamAuditEvents.all, contains('iam.account.signed_out'));
    });
  });
}
