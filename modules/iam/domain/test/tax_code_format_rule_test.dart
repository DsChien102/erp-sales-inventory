import 'package:test/test.dart';
import 'package:vet45_iam_domain/domain.dart';

void main() {
  group('TaxCodeFormatRule', () {
    bool broken(String taxCode, [LegalEntityType type = LegalEntityType.enterprise]) =>
        TaxCodeFormatRule(entityType: type, taxCode: taxCode).isBroken();

    test('normalize trims whitespace and keeps the branch dash', () {
      expect(TaxCodeFormatRule.normalize(' 0101234567-001 '), '0101234567-001');
    });

    test('accepts 10 digits, 12 digits and 10-3 branch format for any entity type', () {
      expect(broken('0101234567'), isFalse);
      expect(broken('010123456789', LegalEntityType.householdBusiness), isFalse);
      expect(broken('0101234567-001'), isFalse);
      expect(broken('0101234567-001', LegalEntityType.householdBusiness), isFalse);
    });

    test('rejects 11 digits and 13 continuous digits', () {
      expect(broken('01012345678'), isTrue);
      expect(broken('0101234567001'), isTrue);
    });

    test('rejects malformed input', () {
      expect(broken('123456789'), isTrue);
      expect(broken('12345-678'), isTrue);
      expect(broken('0101234567-01'), isTrue);
      expect(broken('0101234567 001'), isTrue);
      expect(broken('---'), isTrue);
    });

    test('message names the three accepted formats', () {
      expect(
        TaxCodeFormatRule(entityType: LegalEntityType.enterprise, taxCode: '1').message,
        'Mã số thuế phải gồm 10 hoặc 12 chữ số, hoặc dạng chi nhánh 10 số-3 số (VD: 0123456789-001).',
      );
    });
  });
}
