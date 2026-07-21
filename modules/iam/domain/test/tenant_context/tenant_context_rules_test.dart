import 'package:test/test.dart';
import 'package:vet45_iam_domain/domain.dart';

void main() {
  group('TargetTenantMustDifferFromCurrentRule', () {
    test('not broken when current is null', () {
      const rule = TargetTenantMustDifferFromCurrentRule(
        targetTenantId: 't-1',
      );
      expect(rule.isBroken(), isFalse);
    });

    test('not broken when target differs', () {
      const rule = TargetTenantMustDifferFromCurrentRule(
        targetTenantId: 't-2',
        currentTenantId: 't-1',
      );
      expect(rule.isBroken(), isFalse);
    });

    test('broken when same as current', () {
      const rule = TargetTenantMustDifferFromCurrentRule(
        targetTenantId: 't-1',
        currentTenantId: 't-1',
      );
      expect(rule.isBroken(), isTrue);
    });
  });

  group('TenantMustAllowBusinessContextRule', () {
    test('active allows context', () {
      const rule =
          TenantMustAllowBusinessContextRule(TenantLifecycleStatus.active);
      expect(rule.isBroken(), isFalse);
    });

    test('provisioning allows context', () {
      const rule = TenantMustAllowBusinessContextRule(
        TenantLifecycleStatus.provisioning,
      );
      expect(rule.isBroken(), isFalse);
    });

    test('suspended blocks context', () {
      const rule = TenantMustAllowBusinessContextRule(
        TenantLifecycleStatus.suspended,
      );
      expect(rule.isBroken(), isTrue);
    });

    test('closed blocks context', () {
      const rule =
          TenantMustAllowBusinessContextRule(TenantLifecycleStatus.closed);
      expect(rule.isBroken(), isTrue);
    });
  });

  group('ActiveMembershipRequiredForContextRule', () {
    test('not broken when membership active', () {
      const rule =
          ActiveMembershipRequiredForContextRule(hasActiveMembership: true);
      expect(rule.isBroken(), isFalse);
    });

    test('broken when no active membership', () {
      const rule =
          ActiveMembershipRequiredForContextRule(hasActiveMembership: false);
      expect(rule.isBroken(), isTrue);
    });
  });
}
