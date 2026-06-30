import 'package:test/test.dart';
import 'package:vet45_partner_domain/src/value_objects/partner_name.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

void main() {
  group('PartnerName', () {
    test('trims and stores valid value', () {
      final value = PartnerName('  Cong ty A  ');
      expect(value.value, 'Cong ty A');
    });

    test('throws when value is blank', () {
      expect(
        () => PartnerName('   '),
        throwsA(isA<DomainException>()),
      );
    });
  });
}
