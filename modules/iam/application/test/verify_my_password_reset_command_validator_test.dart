import 'package:test/test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';

void main() {
  group('VerifyMyPasswordResetCommandValidator', () {
    final validator = VerifyMyPasswordResetCommandValidator();

    test('accepts 6-digit code', () async {
      await validator.validate(
        VerifyMyPasswordResetCommand(
          operationId: 'op-1',
          code: '123456',
        ),
      );
    });

    test('rejects empty operationId', () async {
      await expectLater(
        validator.validate(
          VerifyMyPasswordResetCommand(
            operationId: '  ',
            code: '123456',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects non-6-digit codes', () async {
      for (final code in ['', '12345', '1234567', 'abcdef', '12 456', '12345a']) {
        await expectLater(
          validator.validate(
            VerifyMyPasswordResetCommand(
              operationId: 'op-1',
              code: code,
            ),
          ),
          throwsA(isA<ValidationException>()),
          reason: 'code=$code',
        );
      }
    });
  });
}
