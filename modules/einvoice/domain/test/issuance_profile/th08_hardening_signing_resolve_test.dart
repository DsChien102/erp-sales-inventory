import 'package:test/test.dart';
import 'package:vet45_einvoice_domain/domain.dart';

void main() {
  group('th08_hardening_resolve — SigningConfigurationRef wire SignType', () {
    test('HSM on non-MTT resolves to 2', () {
      const signing = SigningConfigurationRef(
        signingConfigId: 'sign-hsm',
        method: SigningMethod.hsm,
      );
      expect(signing.resolveWireSignType(templateIsMtt: false), 2);
    });

    test('noSign on MTT resolves to 5', () {
      const signing = SigningConfigurationRef(
        signingConfigId: 'sign-nosign',
        method: SigningMethod.noSign,
      );
      expect(signing.resolveWireSignType(templateIsMtt: true), 5);
    });

    test('HSM on MTT is incompatible', () {
      const signing = SigningConfigurationRef(
        signingConfigId: 'sign-hsm',
        method: SigningMethod.hsm,
      );
      expect(signing.resolveWireSignType(templateIsMtt: true), isNull);
    });

    test('noSign on non-MTT is incompatible', () {
      const signing = SigningConfigurationRef(
        signingConfigId: 'sign-nosign',
        method: SigningMethod.noSign,
      );
      expect(signing.resolveWireSignType(templateIsMtt: false), isNull);
    });
  });
}
