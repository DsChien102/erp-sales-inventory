import 'package:test/test.dart';
import 'package:vet45_einvoice_domain/domain.dart';

void main() {
  group('ConfigurationReadinessEvaluator', () {
    test('returns ready when all checks pass', () {
      final result = ConfigurationReadinessEvaluator.evaluate(
        const ConfigurationReadinessInput(
          hasLegalProfile: true,
          legalName: 'ACME',
          taxCode: '0123456789',
          connectionStatus: ProviderConnectionStatus.connected,
          hasDefaultTemplate: true,
          templateAvailable: true,
          signingMethod: SigningMethod.hsm,
          signingAvailable: true,
          signingSupportsAutoIssue: true,
        ),
      );
      expect(result.level, ConfigurationReadinessLevel.ready);
      expect(result.blockers, isEmpty);
    });

    test('returns notReady when connection missing', () {
      final result = ConfigurationReadinessEvaluator.evaluate(
        const ConfigurationReadinessInput(
          hasLegalProfile: true,
          legalName: 'ACME',
          taxCode: '0123456789',
        ),
      );
      expect(result.level, ConfigurationReadinessLevel.notReady);
      expect(
        result.blockers.map((b) => b.code),
        contains('provider_not_connected'),
      );
    });

    test('auto issue purpose blocked on warnings only', () {
      final result = ConfigurationReadinessEvaluator.evaluate(
        const ConfigurationReadinessInput(
          hasLegalProfile: true,
          legalName: 'ACME',
          taxCode: '0123456789',
          connectionStatus: ProviderConnectionStatus.connected,
          hasDefaultTemplate: true,
          templateAvailable: true,
          signingMethod: SigningMethod.hsm,
          signingAvailable: true,
          signingSupportsAutoIssue: true,
          templateDeprecated: true,
          purpose: IssuancePurpose.autoIssue,
        ),
      );
      expect(result.level, ConfigurationReadinessLevel.notReady);
    });
  });
}

