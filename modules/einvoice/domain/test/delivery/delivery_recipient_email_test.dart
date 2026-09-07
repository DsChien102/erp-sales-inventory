import 'package:test/test.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

void main() {
  group('DeliveryRecipientEmail', () {
    test('accepts a valid email', () {
      final email = DeliveryRecipientEmail('buyer@clinic.vn');
      expect(email.value, 'buyer@clinic.vn');
    });

    test('trims surrounding whitespace', () {
      final email = DeliveryRecipientEmail('  buyer@clinic.vn  ');
      expect(email.value, 'buyer@clinic.vn');
    });

    test('rejects empty and blank input', () {
      expect(
        () => DeliveryRecipientEmail(''),
        throwsA(isA<BusinessRuleValidationException>()),
      );
      expect(
        () => DeliveryRecipientEmail('   '),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });

    test('rejects invalid format', () {
      expect(
        () => DeliveryRecipientEmail('not-an-email'),
        throwsA(isA<BusinessRuleValidationException>()),
      );
      expect(
        () => DeliveryRecipientEmail('missing@tld'),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });
  });

  group('DeliveryRecipientSnapshot', () {
    test('is immutable and preserves source', () {
      final snapshot = DeliveryRecipientSnapshot(
        toEmail: DeliveryRecipientEmail('buyer@clinic.vn'),
        source: DeliveryRecipientSource.userInput,
      );

      expect(snapshot.toEmail.value, 'buyer@clinic.vn');
      expect(snapshot.source, DeliveryRecipientSource.userInput);
      expect(
        snapshot,
        equals(
          DeliveryRecipientSnapshot(
            toEmail: DeliveryRecipientEmail('buyer@clinic.vn'),
            source: DeliveryRecipientSource.userInput,
          ),
        ),
      );
    });
  });
}
