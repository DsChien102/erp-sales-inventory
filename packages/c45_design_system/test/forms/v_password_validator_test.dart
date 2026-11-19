import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';

void main() {
  group('VPasswordValidator', () {
    test('optional empty value is valid', () {
      expect(VPasswordValidator.isValid(''), isTrue);
      expect(
        VPasswordValidator.validate('', isRequired: false),
        isNull,
      );
    });

    test('required empty value returns required message', () {
      expect(
        VPasswordValidator.validate('', isRequired: true),
        VPasswordValidator.defaultRequiredPasswordMessage,
      );
    });

    test('does not trim — whitespace-only counts toward length', () {
      expect(
        VPasswordValidator.validate('   ', isRequired: false),
        VPasswordValidator.defaultMinLengthPasswordMessage(
          VPasswordValidator.defaultMinLength,
        ),
      );
      expect(VPasswordValidator.isValid('        '), isTrue);
    });

    test('rejects password shorter than minLength', () {
      expect(VPasswordValidator.isValid('short'), isFalse);
      expect(
        VPasswordValidator.validate('short', isRequired: false),
        VPasswordValidator.defaultMinLengthPasswordMessage(
          VPasswordValidator.defaultMinLength,
        ),
      );
    });

    test('rejects password longer than maxLength', () {
      final tooLong = 'a' * (VPasswordValidator.defaultMaxLength + 1);
      expect(VPasswordValidator.isValid(tooLong), isFalse);
      expect(
        VPasswordValidator.validate(tooLong, isRequired: false),
        VPasswordValidator.defaultMaxLengthPasswordMessage(
          VPasswordValidator.defaultMaxLength,
        ),
      );
    });

    test('accepts password within length bounds', () {
      expect(VPasswordValidator.isValid('password'), isTrue);
      expect(
        VPasswordValidator.validate('password', isRequired: true),
        isNull,
      );
    });

    test('supports custom min and max length', () {
      expect(
        VPasswordValidator.validate(
          'abc',
          isRequired: false,
          minLength: 10,
        ),
        VPasswordValidator.defaultMinLengthPasswordMessage(10),
      );
      expect(
        VPasswordValidator.validate(
          'abcdefghij',
          isRequired: false,
          maxLength: 8,
        ),
        VPasswordValidator.defaultMaxLengthPasswordMessage(8),
      );
    });

    test('supports custom messages', () {
      expect(
        VPasswordValidator.validate(
          '',
          isRequired: true,
          requiredPasswordMessage: 'Custom required',
        ),
        'Custom required',
      );
      expect(
        VPasswordValidator.validate(
          'short',
          isRequired: false,
          minLengthPasswordMessage: 'Custom min',
        ),
        'Custom min',
      );
    });
  });
}
