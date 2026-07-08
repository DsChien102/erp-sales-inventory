import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

void main() {
  group('VSelectValidator', () {
    test('null value is valid when optional', () {
      expect(VSelectValidator.isValid<String>(null), isFalse);
      expect(VSelectValidator.validate<String>(null, isRequired: false), isNull);
    });

    test('null value returns required message when required', () {
      expect(
        VSelectValidator.validate<String>(null, isRequired: true),
        VSelectValidator.defaultRequiredMessage,
      );
    });

    test('non-null value passes', () {
      expect(
        VSelectValidator.validate('active', isRequired: true),
        isNull,
      );
    });

    test('supports custom message', () {
      expect(
        VSelectValidator.validate<String>(
          null,
          isRequired: true,
          requiredMessage: 'Custom required',
        ),
        'Custom required',
      );
    });
  });
}
