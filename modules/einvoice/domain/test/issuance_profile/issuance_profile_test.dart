import 'package:test/test.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

void main() {
  group('IssuanceProfile', () {
    test('setDefault compatible HSM + regular template', () {
      final profile = IssuanceProfile.reconstitute(
        id: const IssuanceProfileId('prof-1'),
        tenantId: TenantId('tenant-1'),
        connectionId: const ProviderConnectionId('conn-1'),
        profileVersion: 1,
      );
      profile.setDefault(
        template: ProviderTemplateRef.create(
          templateId: 'tpl-1',
          name: 'Standard',
          invoiceSeries: '1C26TYY',
          isSendSummary: false,
        ),
        signing: const SigningConfigurationRef(
          signingConfigId: 'sign-hsm',
          method: SigningMethod.hsm,
        ),
      );
      expect(profile.defaultConfiguration?.template.templateId, 'tpl-1');
      expect(profile.profileVersion, 2);
    });

    test('setDefault rejects noSign on non-MTT template', () {
      final profile = IssuanceProfile.reconstitute(
        id: const IssuanceProfileId('prof-1'),
        tenantId: TenantId('tenant-1'),
        connectionId: const ProviderConnectionId('conn-1'),
        profileVersion: 1,
      );
      expect(
        () => profile.setDefault(
          template: ProviderTemplateRef.create(
            templateId: 'tpl-1',
            name: 'Standard',
            invoiceSeries: '1C26TYY',
            isSendSummary: false,
          ),
          signing: const SigningConfigurationRef(
            signingConfigId: 'sign-nosign',
            method: SigningMethod.noSign,
          ),
        ),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });
  });
}
