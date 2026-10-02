import 'package:test/test.dart';
import 'package:vet45_einvoice_infrastructure/src/adapters/misa/me_invoice_canonical_mapper.dart';

void main() {
  test('toPublishRequest encodes sample canonical', () {
    final request = MeInvoiceCanonicalMapper.toPublishRequest(
      canonicalInvoice: {
        'invSeries': '1C25TYY',
        'signType': 2,
        'invDate': '2026-08-01',
        'buyerLegalName': 'ABC',
        'buyerAddress': 'HN',
        'totalAmount': 110000,
        'originalInvoiceDetail': [
          {'itemName': 'Svc', 'quantity': 1, 'unitPrice': 100000},
        ],
        'taxRateInfo': [
          {'vatRateName': '10%'},
        ],
      },
      idempotencyKey: 'attempt-key-42',
    );

    expect(request.invoiceData.single.refId, 'attempt-key-42');
    expect(request.toJson()['InvoiceData'], isNotNull);
  });

  test('toPublishRequest sends OptionUserDefined decimal digits', () {
    final request = MeInvoiceCanonicalMapper.toPublishRequest(
      canonicalInvoice: {
        'invSeries': '2C26MMH',
        'signType': 5,
        'invDate': '2026-08-01',
        'buyerFullName': 'Anh A',
        'totalAmount': 100000,
        'originalInvoiceDetail': [
          {'itemName': 'Svc', 'quantity': 1, 'unitPrice': 100000},
        ],
        'taxRateInfo': [
          {'vatRateName': 'KCT'},
        ],
      },
      idempotencyKey: 'attempt-key-43',
    );

    final invoice =
        (request.toJson()['InvoiceData'] as List).single as Map<String, dynamic>;
    expect(invoice['OptionUserDefined'], {
      'MainCurrency': 'VND',
      'QuantityDecimalDigits': '0',
      'UnitPriceOCDecimalDigits': '0',
      'UnitPriceDecimalDigits': '0',
      'AmountOCDecimalDigits': '0',
      'AmountDecimalDigits': '0',
      'CoefficientDecimalDigits': '2',
      'ExchangRateDecimalDigits': '0',
    });
  });

  group('DiscountRate', () {
    Map<String, dynamic> wireLine(Map<String, Object?> line) {
      final request = MeInvoiceCanonicalMapper.toPublishRequest(
        canonicalInvoice: {
          'invSeries': '2C26MMH',
          'signType': 5,
          'invDate': '2026-08-01',
          'buyerFullName': 'Anh A',
          'totalAmount': 100000,
          'originalInvoiceDetail': [line],
          'taxRateInfo': [
            {'vatRateName': 'KCT'},
          ],
        },
        idempotencyKey: 'attempt-key-rate',
      );
      final invoice =
          (request.toJson()['InvoiceData'] as List).single as Map<String, dynamic>;
      return (invoice['OriginalInvoiceDetail'] as List).single as Map<String, dynamic>;
    }

    test('is 0 without discount', () {
      final line = wireLine({'itemName': 'A', 'quantity': 2, 'unitPrice': 85000, 'amount': 170000});
      expect(line['DiscountRate'], 0);
    });

    test('is derived from discount / amount with 2 decimals', () {
      final percent = wireLine({
        'itemName': 'A', 'quantity': 2, 'unitPrice': 85000,
        'amount': 170000, 'discountAmount': 25500, 'amountWithoutVat': 144500,
      });
      expect(percent['DiscountRate'], 15.0);

      final amount = wireLine({
        'itemName': 'A', 'quantity': 1, 'unitPrice': 85000,
        'amount': 85000, 'discountAmount': 10000, 'amountWithoutVat': 75000,
      });
      expect(amount['DiscountRate'], 11.76);
    });
  });

  group('BuyerTaxCode', () {
    String? wireTaxCode(Object? taxCode) {
      final request = MeInvoiceCanonicalMapper.toPublishRequest(
        canonicalInvoice: {
          'invSeries': '2C26MYY',
          'signType': 5,
          'invDate': '2026-09-30',
          'buyerLegalName': 'Mắt Môi Tay Chân',
          'buyerAddress': 'Xã Hát Môn',
          'buyerTaxCode': taxCode,
          'totalAmount': 100000,
          'originalInvoiceDetail': [
            {'itemName': 'Svc', 'quantity': 1, 'unitPrice': 100000},
          ],
          'taxRateInfo': [
            {'vatRateName': 'KCT'},
          ],
        },
        idempotencyKey: 'attempt-key-tax',
      );
      return request.invoiceData.single.buyerTaxCode;
    }

    test('13 contiguous digits are sent as 10-3', () {
      expect(wireTaxCode('6868686868773'), '6868686868-773');
    });

    test('whitespace is stripped before formatting', () {
      expect(wireTaxCode(' 6868686868 773 '), '6868686868-773');
    });

    test('10 digits, 12 digits and 10-3 are sent unchanged', () {
      expect(wireTaxCode('0101234567'), '0101234567');
      expect(wireTaxCode('001099012345'), '001099012345');
      expect(wireTaxCode('0101234567-001'), '0101234567-001');
    });

    test('missing tax code stays absent', () {
      expect(wireTaxCode(null), isNull);
    });
  });
}
