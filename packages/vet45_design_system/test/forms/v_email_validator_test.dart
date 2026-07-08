import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

void main() {
  group('VEmailValidator', () {
    test('optional empty value is valid', () {
      expect(VEmailValidator.isValid(''), isTrue);
      expect(
        VEmailValidator.validate('', isRequired: false),
        isNull,
      );
    });

    test('required empty value returns required message', () {
      expect(
        VEmailValidator.validate('', isRequired: true),
        VEmailValidator.defaultRequiredEmailMessage,
      );
      expect(
        VEmailValidator.validate('   ', isRequired: true),
        VEmailValidator.defaultRequiredEmailMessage,
      );
    });

    test('valid email formats pass', () {
      const validEmails = [
        'user@domain.com',
        'name.surname@company.co.uk',
        'a@b.co',
      ];

      for (final email in validEmails) {
        expect(VEmailValidator.isValid(email), isTrue, reason: email);
        expect(
          VEmailValidator.validate(email, isRequired: true),
          isNull,
          reason: email,
        );
      }
    });

    test('invalid email formats fail', () {
      const invalidEmails = [
        'bad-email',
        '@no-local.com',
        'no-at.com',
        'user@',
        'user@domain',
      ];

      for (final email in invalidEmails) {
        expect(VEmailValidator.isValid(email), isFalse, reason: email);
        expect(
          VEmailValidator.validate(email, isRequired: false),
          VEmailValidator.defaultInvalidEmailMessage,
          reason: email,
        );
      }
    });

    test('rejects email shorter than minLength', () {
      expect(VEmailValidator.isValid('abc'), isFalse);
      expect(
        VEmailValidator.validate('abc', isRequired: false),
        VEmailValidator.defaultMinLengthEmailMessage(VEmailValidator.defaultMinLength),
      );
    });

    test('rejects email longer than maxLength', () {
      final tooLong = '${'a' * 250}@b.com';
      expect(tooLong.length, greaterThan(VEmailValidator.defaultMaxLength));
      expect(VEmailValidator.isValid(tooLong), isFalse);
      expect(
        VEmailValidator.validate(tooLong, isRequired: false),
        VEmailValidator.defaultMaxLengthEmailMessage(VEmailValidator.defaultMaxLength),
      );
    });

    test('supports custom min and max length', () {
      expect(
        VEmailValidator.validate(
          'a@b.co',
          isRequired: false,
          minLength: 10,
        ),
        VEmailValidator.defaultMinLengthEmailMessage(10),
      );
      expect(
        VEmailValidator.validate(
          'short@x.com',
          isRequired: false,
          maxLength: 10,
        ),
        VEmailValidator.defaultMaxLengthEmailMessage(10),
      );
    });

    test('supports custom messages', () {
      expect(
        VEmailValidator.validate(
          '',
          isRequired: true,
          requiredEmailMessage: 'Custom required',
        ),
        'Custom required',
      );
      expect(
        VEmailValidator.validate(
          'invalid',
          isRequired: false,
          invalidEmailMessage: 'Custom invalid',
        ),
        'Custom invalid',
      );
    });
  });
}
