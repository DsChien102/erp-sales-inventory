import 'package:test/test.dart';
import 'package:vet45_shared_application/application.dart';

void main() {
  group('ValidationException', () {
    test('exposes message', () {
      final error = ValidationException('invalid title');
      expect(error.toString(), 'invalid title');
    });

    test('CommandValidationException is a typedef alias', () {
      final error = CommandValidationException('legacy');
      expect(error, isA<ValidationException>());
    });
  });

  group('ApplicationException', () {
    test('exposes message', () {
      final error = ApplicationException('failed');
      expect(error.toString(), 'failed');
    });
  });
}
