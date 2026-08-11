import 'package:test/test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';

void main() {
  group('RequestPasswordResetByEmailCommandValidator', () {
    final validator = RequestPasswordResetByEmailCommandValidator();

    test('accepts a normal email', () async {
      await validator.validate(
        RequestPasswordResetByEmailCommand(email: 'lan@example.com'),
      );
    });

    test('rejects empty or malformed email', () async {
      for (final email in ['', '  ', 'not-an-email', 'a@']) {
        await expectLater(
          validator.validate(RequestPasswordResetByEmailCommand(email: email)),
          throwsA(isA<ValidationException>()),
          reason: 'email=$email',
        );
      }
    });
  });
}
