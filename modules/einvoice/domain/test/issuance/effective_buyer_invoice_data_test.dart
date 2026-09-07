import 'package:test/test.dart';
import 'package:vet45_einvoice_domain/domain.dart';

void main() {
  group('BuyerType', () {
    test('contains retail, individual, and organization', () {
      expect(
        BuyerType.values,
        containsAll([
          BuyerType.retail,
          BuyerType.individual,
          BuyerType.organization,
        ]),
      );
      expect(BuyerType.values.length, 3);
    });
  });

  group('EffectiveBuyerInvoiceData', () {
    test('retail with name is complete', () {
      const data = EffectiveBuyerInvoiceData(
        buyerType: BuyerType.retail,
        name: 'Khách lẻ',
      );
      expect(data.isComplete, isTrue);
      expect(data.isMissingOnlyOrgTaxCode, isFalse);
    });

    test('retail with empty or whitespace name is incomplete', () {
      const dataEmpty = EffectiveBuyerInvoiceData(
        buyerType: BuyerType.retail,
        name: '',
      );
      const dataWhitespace = EffectiveBuyerInvoiceData(
        buyerType: BuyerType.retail,
        name: '   ',
      );
      expect(dataEmpty.isComplete, isFalse);
      expect(dataWhitespace.isComplete, isFalse);
    });

    test('individual with name is complete', () {
      const data = EffectiveBuyerInvoiceData(
        buyerType: BuyerType.individual,
        name: 'Nguyễn Văn A',
        email: 'a@example.com',
      );
      expect(data.isComplete, isTrue);
      expect(data.isMissingOnlyOrgTaxCode, isFalse);
    });

    test('individual with empty name is incomplete', () {
      const data = EffectiveBuyerInvoiceData(
        buyerType: BuyerType.individual,
        name: '',
      );
      expect(data.isComplete, isFalse);
    });

    test('organization with name and taxCode is complete', () {
      const data = EffectiveBuyerInvoiceData(
        buyerType: BuyerType.organization,
        name: 'Công ty TNHH ABC',
        taxCode: '0101234567',
        address: '123 Đường XYZ',
      );
      expect(data.isComplete, isTrue);
      expect(data.isMissingOnlyOrgTaxCode, isFalse);
    });

    test(
      'organization with name but missing/empty taxCode is incomplete and isMissingOnlyOrgTaxCode is true',
      () {
        const dataNullTax = EffectiveBuyerInvoiceData(
          buyerType: BuyerType.organization,
          name: 'Công ty TNHH ABC',
        );
        const dataEmptyTax = EffectiveBuyerInvoiceData(
          buyerType: BuyerType.organization,
          name: 'Công ty TNHH ABC',
          taxCode: '',
        );
        const dataWhitespaceTax = EffectiveBuyerInvoiceData(
          buyerType: BuyerType.organization,
          name: 'Công ty TNHH ABC',
          taxCode: '   ',
        );

        expect(dataNullTax.isComplete, isFalse);
        expect(dataNullTax.isMissingOnlyOrgTaxCode, isTrue);

        expect(dataEmptyTax.isComplete, isFalse);
        expect(dataEmptyTax.isMissingOnlyOrgTaxCode, isTrue);

        expect(dataWhitespaceTax.isComplete, isFalse);
        expect(dataWhitespaceTax.isMissingOnlyOrgTaxCode, isTrue);
      },
    );

    test('organization with empty name is incomplete and isMissingOnlyOrgTaxCode is false', () {
      const data = EffectiveBuyerInvoiceData(
        buyerType: BuyerType.organization,
        name: '',
        taxCode: '0101234567',
      );
      expect(data.isComplete, isFalse);
      expect(data.isMissingOnlyOrgTaxCode, isFalse);

      const dataNoTax = EffectiveBuyerInvoiceData(
        buyerType: BuyerType.organization,
        name: '   ',
      );
      expect(dataNoTax.isComplete, isFalse);
      expect(dataNoTax.isMissingOnlyOrgTaxCode, isFalse);
    });

    test('props and equality check', () {
      const data1 = EffectiveBuyerInvoiceData(
        buyerType: BuyerType.organization,
        name: 'Công ty ABC',
        email: 'abc@example.com',
        taxCode: '0123456789',
        address: '123 Wall St',
      );
      const data2 = EffectiveBuyerInvoiceData(
        buyerType: BuyerType.organization,
        name: 'Công ty ABC',
        email: 'abc@example.com',
        taxCode: '0123456789',
        address: '123 Wall St',
      );
      const data3 = EffectiveBuyerInvoiceData(
        buyerType: BuyerType.organization,
        name: 'Công ty XYZ',
        email: 'abc@example.com',
        taxCode: '0123456789',
        address: '123 Wall St',
      );

      expect(data1, equals(data2));
      expect(data1.hashCode, equals(data2.hashCode));
      expect(data1, isNot(equals(data3)));
      expect(
        data1.props,
        equals([
          BuyerType.organization,
          'Công ty ABC',
          'abc@example.com',
          '0123456789',
          '123 Wall St',
        ]),
      );
    });
  });
}
