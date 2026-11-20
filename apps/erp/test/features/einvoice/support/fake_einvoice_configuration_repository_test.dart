import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/einvoice/data/einvoice_errors.dart';
import 'package:erp/features/einvoice/data/models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_einvoice_configuration_repository.dart';

void main() {
  group('FakeEInvoiceConfigurationRepository', () {
    test('connectAuthFailed -> connect throws AppException with PROVIDER_AUTH_FAILED', () async {
      final repo = FakeEInvoiceConfigurationRepository(
        scenario: FakeEInvoiceConfigurationScenario.connectAuthFailed,
      );

      expect(
        () => repo.connect(username: 'user', password: 'pwd'),
        throwsA(
          isA<AppException>().having((e) => e.code, 'code', EInvoiceErrorCodes.providerAuthFailed),
        ),
      );
      expect(repo.calls, ['connect']);
    });

    test('setDefaultIncompatible -> throws TEMPLATE_NOT_AVAILABLE', () async {
      final repo = FakeEInvoiceConfigurationRepository(
        scenario: FakeEInvoiceConfigurationScenario.setDefaultIncompatible,
      );

      expect(
        () => repo.setDefaultConfiguration(
          templateId: 'tpl-1',
          signingConfigId: 'sign-1',
        ),
        throwsA(
          isA<AppException>().having((e) => e.code, 'code', EInvoiceErrorCodes.templateNotAvailable),
        ),
      );
      expect(repo.calls, ['setDefaultConfiguration']);
    });

    test('connectionScreenPending -> getConnectionScreen returns checkRequired', () async {
      final repo = FakeEInvoiceConfigurationRepository(
        scenario: FakeEInvoiceConfigurationScenario.connectionScreenPending,
      );

      final screen = await repo.getConnectionScreen();
      expect(screen.connection.status, ProviderConnectionStatus.checkRequired);
      expect(repo.calls, ['getConnectionScreen']);
    });

    test('configurationLoadFailure -> all 5 query methods throw SYSTEM_ERROR', () async {
      final repo = FakeEInvoiceConfigurationRepository(
        scenario: FakeEInvoiceConfigurationScenario.configurationLoadFailure,
      );

      await expectLater(
        () => repo.getConnectionScreen(),
        throwsA(isA<AppException>().having((e) => e.code, 'code', EInvoiceErrorCodes.systemError)),
      );
      await expectLater(
        () => repo.listTemplates(),
        throwsA(isA<AppException>().having((e) => e.code, 'code', EInvoiceErrorCodes.systemError)),
      );
      await expectLater(
        () => repo.getIssuanceProfile(),
        throwsA(isA<AppException>().having((e) => e.code, 'code', EInvoiceErrorCodes.systemError)),
      );
      await expectLater(
        () => repo.getAutomationPolicy(),
        throwsA(isA<AppException>().having((e) => e.code, 'code', EInvoiceErrorCodes.systemError)),
      );
      await expectLater(
        () => repo.getConfigurationReadiness(),
        throwsA(isA<AppException>().having((e) => e.code, 'code', EInvoiceErrorCodes.systemError)),
      );

      expect(repo.calls, [
        'getConnectionScreen',
        'listTemplates',
        'getIssuanceProfile',
        'getAutomationPolicy',
        'getConfigurationReadiness',
      ]);
    });

    test('calls records methods in exact call order', () async {
      final repo = FakeEInvoiceConfigurationRepository();

      await repo.getConnectionScreen();
      await repo.connect(username: 'u', password: 'p');
      await repo.listTemplates();
      await repo.setDefaultConfiguration(templateId: 't', signingConfigId: 's');
      await repo.getAutomationPolicy();
      await repo.updateAutomationPolicy(expectedPolicyVersion: 1, autoIssueEnabled: true);
      await repo.disconnect(connectionId: 'c', confirm: true);

      expect(repo.calls, [
        'getConnectionScreen',
        'connect',
        'listTemplates',
        'setDefaultConfiguration',
        'getAutomationPolicy',
        'updateAutomationPolicy',
        'disconnect',
      ]);
    });
  });
}
