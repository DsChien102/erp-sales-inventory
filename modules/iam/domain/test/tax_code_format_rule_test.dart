import 'package:test/test.dart';
import 'package:vet45_iam_domain/domain.dart';

void main() {
  group('TaxCodeFormatRule', () {
    bool broken(String taxCode, [LegalEntityType type = LegalEntityType.enterprise]) =>
        TaxCodeFormatRule(entityType: type, taxCode: taxCode).isBroken();

    test('normalize strips every non-digit', () {
      expect(TaxCodeFormatRule.normalize(' 0101234567-001 '), '0101234567001');
    });

    test('accepts 10 to 13 digits for any entity type', () {
      expect(broken('0101234567'), isFalse);
      expect(broken('01012345678'), isFalse);
      expect(broken('010123456789', LegalEntityType.enterprise), isFalse);
      expect(broken('0101234567001', LegalEntityType.householdBusiness), isFalse);
    });

    test('accepts dashed input after normalization', () {
      expect(broken('0101234567-001'), isFalse);
    });

    test('rejects fewer than 10 or more than 13 digits', () {
      expect(broken('123456789'), isTrue);
      expect(broken('01012345670011'), isTrue);
      expect(broken('---'), isTrue);
    });
  });
}
