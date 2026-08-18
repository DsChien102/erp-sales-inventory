import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_application/testing.dart';
import 'package:vet45_einvoice_domain/domain.dart';

void main() {
  group('EP-01 fake scenarios', () {
    test('connect_ok returns CONNECTED', () async {
      final module = FakeEInvoiceModule(scenario: FakeEInvoiceScenario.connectOk);
      final result = await module.executeCommandAsync(
        ConnectProviderCommand(
          tenantId: 't1',
          actorId: 'a1',
          username: 'u',
          password: 'p',
        ),
      );
      expect(result.status, ProviderConnectionStatus.connected);
    });

    test('connect_auth_failed throws ProviderAuthFailedException', () async {
      final module =
          FakeEInvoiceModule(scenario: FakeEInvoiceScenario.connectAuthFailed);
      expect(
        () => module.executeCommandAsync(
          ConnectProviderCommand(
            tenantId: 't1',
            actorId: 'a1',
            username: 'u',
            password: 'bad',
          ),
        ),
        throwsA(isA<ProviderAuthFailedException>()),
      );
    });

    test('config_readiness_ready returns READY', () async {
      final module =
          FakeEInvoiceModule(scenario: FakeEInvoiceScenario.configReadinessReady);
      final result = await module.executeQueryAsync(
        GetConfigurationReadinessQuery(tenantId: 't1', actorId: 'a1'),
      );
      expect(result.level, ConfigurationReadinessLevel.ready);
    });

    test('list_templates_ok returns 2 templates', () async {
      final module =
          FakeEInvoiceModule(scenario: FakeEInvoiceScenario.listTemplatesOk);
      final result = await module.executeQueryAsync(
        ListProviderTemplatesQuery(tenantId: 't1', actorId: 'a1'),
      );
      expect(result.length, 2);
    });
  });
}
