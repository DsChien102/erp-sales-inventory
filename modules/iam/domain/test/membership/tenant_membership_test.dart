import 'package:test/test.dart';
import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

void main() {
  TenantMembership membership({
    MembershipStatus status = MembershipStatus.active,
    bool isOwner = false,
    int version = 1,
    String role = 'staff',
  }) {
    return TenantMembership.reconstitute(
      id: const TenantMembershipId('m-1'),
      tenantId: const TenantId('t-1'),
      userId: 'u-1',
      role: role,
      isOwner: isOwner,
      status: status,
      version: version,
    );
  }

  group('TenantMembership.deactivate', () {
    test('active → inactive bumps version', () {
      final m = membership();
      m.deactivate(isSoleOwner: false);
      expect(m.status, MembershipStatus.inactive);
      expect(m.version, 2);
    });

    test('sole owner protected', () {
      final m = membership(isOwner: true);
      expect(
        () => m.deactivate(isSoleOwner: true),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });

    test('removed is terminal', () {
      final m = membership(status: MembershipStatus.removed);
      expect(
        () => m.deactivate(isSoleOwner: false),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });
  });

  group('TenantMembership.reactivate', () {
    test('inactive → active bumps version', () {
      final m = membership(status: MembershipStatus.inactive);
      m.reactivate(roleAssignable: true);
      expect(m.status, MembershipStatus.active);
      expect(m.version, 2);
    });

    test('removed cannot reactivate', () {
      final m = membership(status: MembershipStatus.removed);
      expect(
        () => m.reactivate(roleAssignable: true),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });

    test('role not assignable', () {
      final m = membership(status: MembershipStatus.inactive);
      expect(
        () => m.reactivate(roleAssignable: false),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });
  });

  group('TenantMembership.remove', () {
    test('active → removed', () {
      final m = membership();
      m.remove(isSoleOwner: false);
      expect(m.status, MembershipStatus.removed);
      expect(m.version, 2);
    });

    test('sole owner protected', () {
      final m = membership(isOwner: true);
      expect(
        () => m.remove(isSoleOwner: true),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });
  });
}
