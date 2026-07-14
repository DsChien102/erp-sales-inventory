import 'package:test/test.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

void main() {
  group('PersonTitle', () {
    test('accepts free-form honorific text', () {
      final title = PersonTitle('Ông');

      expect(title.value, 'Ông');
    });

    test('rejects blank value', () {
      expect(
        () => PersonTitle('   '),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });
  });
}
