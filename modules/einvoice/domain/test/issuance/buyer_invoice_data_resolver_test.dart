import 'package:test/test.dart';
import 'package:vet45_einvoice_domain/domain.dart';

void main() {
  group('BuyerInvoiceDataResolver', () {
    test('uses base snapshot as-is when base is complete and completionSource is null', () {
      const base = BuyerInvoiceSourceFields(
        buyerType: BuyerType.organization,
        name: 'Công ty TNHH Thú Y PetCare',
        email: 'petcare@example.com',
        taxCode: '0109998888',
        address: '100 Lê Duẩn, Hà Nội',
      );

      final result = BuyerInvoiceDataResolver.resolve(base: base);

      expect(
        result,
        equals(const EffectiveBuyerInvoiceData(
          buyerType: BuyerType.organization,
          name: 'Công ty TNHH Thú Y PetCare',
          email: 'petcare@example.com',
          taxCode: '0109998888',
          address: '100 Lê Duẩn, Hà Nội',
        )),
      );
      expect(result.isComplete, isTrue);
    });

    test('uses base snapshot as-is when complete and ignores completionSource non-empty fields', () {
      const base = BuyerInvoiceSourceFields(
        buyerType: BuyerType.organization,
        name: 'Công ty A',
        email: 'a@example.com',
        taxCode: '0101112222',
        address: '123 Base Street',
      );
      const completion = BuyerInvoiceSourceFields(
        buyerType: BuyerType.individual,
        name: 'Công ty B Override',
        email: 'b@example.com',
        taxCode: '0999999999',
        address: '456 Source Street',
      );

      final result = BuyerInvoiceDataResolver.resolve(
        base: base,
        completionSource: completion,
      );

      expect(result.name, equals('Công ty A'));
      expect(result.email, equals('a@example.com'));
      expect(result.taxCode, equals('0101112222'));
      expect(result.address, equals('123 Base Street'));
      expect(result.buyerType, equals(BuyerType.organization));
    });

    test('base buyerType is authoritative even if completion source has different buyerType', () {
      const base = BuyerInvoiceSourceFields(
        buyerType: BuyerType.retail,
        name: 'Khách lẻ',
      );
      const completion = BuyerInvoiceSourceFields(
        buyerType: BuyerType.organization,
        name: 'Khách lẻ override',
        taxCode: '0101234567',
      );

      final result = BuyerInvoiceDataResolver.resolve(
        base: base,
        completionSource: completion,
      );

      expect(result.buyerType, equals(BuyerType.retail));
      expect(result.name, equals('Khách lẻ'));
      expect(result.taxCode, equals('0101234567'));
    });

    test('fills missing null fields from completion source', () {
      const base = BuyerInvoiceSourceFields(
        buyerType: BuyerType.organization,
        name: 'Công ty C',
      );
      const completion = BuyerInvoiceSourceFields(
        buyerType: BuyerType.organization,
        email: 'c@example.com',
        taxCode: '0103334444',
        address: '789 Completion Ave',
      );

      final result = BuyerInvoiceDataResolver.resolve(
        base: base,
        completionSource: completion,
      );

      expect(result.name, equals('Công ty C'));
      expect(result.email, equals('c@example.com'));
      expect(result.taxCode, equals('0103334444'));
      expect(result.address, equals('789 Completion Ave'));
      expect(result.isComplete, isTrue);
    });

    test('empty or whitespace-only base fields fall back to completion source', () {
      const base = BuyerInvoiceSourceFields(
        buyerType: BuyerType.individual,
        name: '   ',
        email: '',
        taxCode: '  ',
        address: '\t\n',
      );
      const completion = BuyerInvoiceSourceFields(
        buyerType: BuyerType.individual,
        name: 'Nguyễn Văn Fallback',
        email: 'fallback@example.com',
        taxCode: '0108887777',
        address: '999 Đường Mới',
      );

      final result = BuyerInvoiceDataResolver.resolve(
        base: base,
        completionSource: completion,
      );

      expect(result.name, equals('Nguyễn Văn Fallback'));
      expect(result.email, equals('fallback@example.com'));
      expect(result.taxCode, equals('0108887777'));
      expect(result.address, equals('999 Đường Mới'));
      expect(result.isComplete, isTrue);
    });

    test('handles whitespace in completionSource by treating it as missing/null', () {
      const base = BuyerInvoiceSourceFields(
        buyerType: BuyerType.individual,
        name: '   ',
      );
      const completion = BuyerInvoiceSourceFields(
        buyerType: BuyerType.individual,
        name: '   ',
        email: '   ',
        taxCode: '',
        address: '  \n',
      );

      final result = BuyerInvoiceDataResolver.resolve(
        base: base,
        completionSource: completion,
      );

      expect(result.name, equals(''));
      expect(result.email, isNull);
      expect(result.taxCode, isNull);
      expect(result.address, isNull);
      expect(result.isComplete, isFalse);
    });

    test('defaults name to empty string when missing in both base and completionSource', () {
      const base = BuyerInvoiceSourceFields(
        buyerType: BuyerType.retail,
      );

      final result = BuyerInvoiceDataResolver.resolve(base: base);

      expect(result.name, equals(''));
      expect(result.isComplete, isFalse);
    });
  });
}
