import 'package:flutter_test/flutter_test.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/einvoice/data/einvoice_errors.dart';
import 'package:erp/features/einvoice/data/models.dart';
import 'package:erp/features/einvoice/logic/automation_policy_cubit.dart';

import '../support/fake_einvoice_configuration_repository.dart';

class _SystemErrorAutomationRepo extends FakeEInvoiceConfigurationRepository {
  @override
  Future<AutomationPolicyDto> updateAutomationPolicy({
    required int expectedPolicyVersion,
    bool? autoIssueEnabled,
    bool? autoSendEnabled,
  }) async {
    calls.add('updateAutomationPolicy');
    throw const AppException(EInvoiceErrorCodes.systemError);
  }
}

void main() {
  group('AutomationPolicyCubit', () {
    test('enableAutoIssueNotReady maps to notReady', () async {
      final repo = FakeEInvoiceConfigurationRepository(
        scenario: FakeEInvoiceConfigurationScenario.enableAutoIssueNotReady,
      );
      final cubit = AutomationPolicyCubit(repository: repo);
      await cubit.load();

      final result = await cubit.save();
      expect(result, equals(AutomationPolicySaveResult.notReady));

      await cubit.close();
    });

    test('automationStateChanged maps to stateChanged', () async {
      final repo = FakeEInvoiceConfigurationRepository(
        scenario: FakeEInvoiceConfigurationScenario.automationStateChanged,
      );
      final cubit = AutomationPolicyCubit(repository: repo);
      await cubit.load();

      final result = await cubit.save();
      expect(result, equals(AutomationPolicySaveResult.stateChanged));

      await cubit.close();
    });

    test('AppException systemError maps to failed', () async {
      final repo = _SystemErrorAutomationRepo();
      final cubit = AutomationPolicyCubit(repository: repo);
      await cubit.load();

      final result = await cubit.save();
      expect(result, equals(AutomationPolicySaveResult.failed));

      await cubit.close();
    });
  });
}
