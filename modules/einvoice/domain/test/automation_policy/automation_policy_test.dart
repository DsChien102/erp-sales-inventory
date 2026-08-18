import 'package:test/test.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

void main() {
  group('AutomationPolicy', () {
    test('update bumps version and enables auto issue when ready', () {
      final policy = AutomationPolicy.reconstitute(
        id: const AutomationPolicyId('pol-1'),
        tenantId: TenantId('tenant-1'),
        autoIssueEnabled: false,
        autoSendEnabled: false,
        policyVersion: 1,
      );
      policy.update(
        autoIssueEnabled: true,
        expectedPolicyVersion: 1,
        readinessForAutoIssue: ConfigurationReadinessLevel.ready,
      );
      expect(policy.autoIssueEnabled, isTrue);
      expect(policy.policyVersion, 2);
    });

    test('update rejects auto issue when not ready', () {
      final policy = AutomationPolicy.reconstitute(
        id: const AutomationPolicyId('pol-1'),
        tenantId: TenantId('tenant-1'),
        autoIssueEnabled: false,
        autoSendEnabled: false,
        policyVersion: 1,
      );
      expect(
        () => policy.update(
          autoIssueEnabled: true,
          expectedPolicyVersion: 1,
          readinessForAutoIssue: ConfigurationReadinessLevel.notReady,
        ),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });
  });
}

