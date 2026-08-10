import 'package:test/test.dart';
import 'package:vet45_iam_domain/domain.dart';

void main() {
  group('PasswordPolicy', () {
    test('accepts 8+ chars with a digit and a special char', () {
      expect(PasswordPolicy.validate('password1!'), isNull);
      expect(PasswordPolicy.isValid('password1!'), isTrue);
    });

    test('rejects empty with required message', () {
      expect(PasswordPolicy.validate(''), 'Vui lòng nhập mật khẩu');
      expect(PasswordPolicy.isValid(''), isFalse);
    });

    test('rejects too short even with digit + special', () {
      expect(PasswordPolicy.validate('a1!'), PasswordPolicy.violationMessage);
      expect(PasswordPolicy.isValid('a1!'), isFalse);
    });

    test('rejects missing digit', () {
      expect(PasswordPolicy.validate('password!!'), PasswordPolicy.violationMessage);
    });

    test('rejects missing special char', () {
      expect(PasswordPolicy.validate('password12'), PasswordPolicy.violationMessage);
    });
  });
}
