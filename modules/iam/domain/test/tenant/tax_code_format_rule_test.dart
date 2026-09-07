import 'package:test/test.dart';
import 'package:vet45_iam_domain/domain.dart';

void main() {
  group('TaxCodeFormatRule', () {
    test('accepts 10-digit tax codes for enterprise and household business', () {
      expect(
        TaxCodeFormatRule(
          entityType: LegalEntityType.enterprise,
          taxCode: '0123456789',
        ).isBroken(),
        isFalse,
      );
      expect(
        TaxCodeFormatRule(
          entityType: LegalEntityType.householdBusiness,
          taxCode: '0123456789',
        ).isBroken(),
        isFalse,
      );
    });

    test('accepts 12-digit tax codes for enterprise and household business', () {
      expect(
        TaxCodeFormatRule(
          entityType: LegalEntityType.enterprise,
          taxCode: '012345678901',
        ).isBroken(),
        isFalse,
      );
      expect(
        TaxCodeFormatRule(
          entityType: LegalEntityType.householdBusiness,
          taxCode: '012345678901',
        ).isBroken(),
        isFalse,
      );
    });

    test('accepts 13-digit tax codes', () {
      expect(
        TaxCodeFormatRule(
          entityType: LegalEntityType.enterprise,
          taxCode: '0123456789012',
        ).isBroken(),
        isFalse,
      );
    });

    test('accepts 10-digit tax code with 3-digit branch dash (0123456789-001)', () {
      expect(
        TaxCodeFormatRule(
          entityType: LegalEntityType.enterprise,
          taxCode: '0123456789-001',
        ).isBroken(),
        isFalse,
      );
      expect(
        TaxCodeFormatRule(
          entityType: LegalEntityType.householdBusiness,
          taxCode: '0123456789-001',
        ).isBroken(),
        isFalse,
      );
    });

    test('rejects tax code with fewer than 10 digits', () {
      expect(
        TaxCodeFormatRule(
          entityType: LegalEntityType.enterprise,
          taxCode: '123456789',
        ).isBroken(),
        isTrue,
      );
    });

    test('rejects tax code with more than 13 digits', () {
      expect(
        TaxCodeFormatRule(
          entityType: LegalEntityType.enterprise,
          taxCode: '12345678901234',
        ).isBroken(),
        isTrue,
      );
    });

    test('rejects tax code with invalid characters or bad dash position', () {
      expect(
        TaxCodeFormatRule(
          entityType: LegalEntityType.enterprise,
          taxCode: '012345678A',
        ).isBroken(),
        isTrue,
      );
      expect(
        TaxCodeFormatRule(
          entityType: LegalEntityType.enterprise,
          taxCode: '0123456789-01',
        ).isBroken(),
        isTrue,
      );
      expect(
        TaxCodeFormatRule(
          entityType: LegalEntityType.enterprise,
          taxCode: '01234567-0001',
        ).isBroken(),
        isTrue,
      );
    });
  });
}
