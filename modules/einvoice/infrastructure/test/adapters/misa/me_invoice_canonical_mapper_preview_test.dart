import 'package:test/test.dart';
import 'package:vet45_einvoice_infrastructure/src/adapters/misa/me_invoice_canonical_mapper.dart';

void main() {
  group('MeInvoiceCanonicalMapper preview mapping', () {
    final validCanonical = <String, Object?>{
      'invSeries': '1C26TAA',
      'invDate': '2026-09-03',
      'buyerLegalName': 'Nguyễn Văn Kiểm Thử',
      'buyerAddress': 'Số 123 Đường Kiểm Thử, TP. Hồ Chí Minh',
      'totalAmount': 1100000,
      'totalSaleAmount': 1000000,
      'totalAmountWithoutVat': 1000000,
      'totalVatAmount': 100000,
      'originalInvoiceDetail': [
        {
          'lineNumber': 1,
          'itemCode': 'SP-01',
          'itemName': 'Dịch vụ kiểm thử',
          'unitName': 'Lần',
          'quantity': 1,
          'unitPrice': 1000000,
          'amount': 1000000,
          'vatRate': 10,
          'vatAmount': 100000,
        }
      ],
      'taxRateInfo': [
        {
          'vatRateName': '10%',
          'vatRate': 10,
          'turnover': 1000000,
          'vatAmount': 100000,
        }
      ],
    };

    test('maps lowerCamel canonical payload to PascalCase MeInvoiceInvoiceData for preview', () {
      final invoice = MeInvoiceCanonicalMapper.toPreviewInvoice(validCanonical);

      expect(invoice.invSeries, equals('1C26TAA'));
      expect(invoice.invDate, equals('2026-09-03'));
      expect(invoice.buyerLegalName, equals('Nguyễn Văn Kiểm Thử'));
      expect(invoice.buyerAddress, equals('Số 123 Đường Kiểm Thử, TP. Hồ Chí Minh'));
      expect(invoice.totalAmount, equals(1100000));
      expect(invoice.originalInvoiceDetail, isNotNull);
      expect(invoice.originalInvoiceDetail!.length, equals(1));
      expect(invoice.originalInvoiceDetail!.first.itemName, equals('Dịch vụ kiểm thử'));
      expect(invoice.originalInvoiceDetail!.first.quantity, equals(1));
      expect(invoice.originalInvoiceDetail!.first.unitPrice, equals(1000000));
      expect(invoice.taxRateInfo, isNotNull);
      expect(invoice.taxRateInfo!.length, equals(1));
      expect(invoice.taxRateInfo!.first.vatRateName, equals('10%'));
    });

    test('mirrors *Oc / AmountOC fields for seed-shaped VND payloads', () {
      final invoice = MeInvoiceCanonicalMapper.toPreviewInvoice(validCanonical);
      final wire = invoice.toJson();

      expect(wire['TotalAmountOC'], equals(1100000));
      expect(wire['TotalAmount'], equals(1100000));
      expect(wire['TotalSaleAmountOC'], equals(1000000));
      expect(wire['TotalAmountWithoutVATOC'], equals(1000000));
      expect(wire['TotalVATAmountOC'], equals(100000));
      expect(wire['TotalDiscountAmountOC'], equals(0));
      expect(wire['TotalAmountInWords'], isA<String>());
      expect(
        (wire['TotalAmountInWords'] as String).toLowerCase(),
        contains('đồng'),
      );

      final line = (wire['OriginalInvoiceDetail'] as List).first as Map;
      expect(line['AmountOC'], equals(1000000));
      expect(line['AmountWithoutVATOC'], equals(1000000));
      expect(line['VATAmountOC'], equals(100000));
      expect(line['VATRateName'], equals('10%'));
      expect(line.containsKey('VATRate'), isFalse);
      expect(line['ItemType'], equals(1));
      expect(line['DiscountRate'], equals(0));
      expect(line['DiscountAmountOC'], equals(0));

      final tax = (wire['TaxRateInfo'] as List).first as Map;
      expect(tax['AmountWithoutVATOC'], equals(1000000));
      expect(tax['VATAmountOC'], equals(100000));
      expect(tax['VATRateName'], equals('10%'));
      expect(tax.containsKey('VATRate'), isFalse);
      expect(tax.containsKey('Turnover'), isFalse);
    });

    test('vndAmountInWords covers acceptance fixture total', () {
      expect(
        MeInvoiceCanonicalMapper.vndAmountInWords(1100000),
        equals('Một triệu một trăm nghìn đồng'),
      );
    });

    test('throws CanonicalValidationFault when invSeries is missing', () {
      final invalid = Map<String, Object?>.from(validCanonical)..remove('invSeries');
      expect(
        () => MeInvoiceCanonicalMapper.toPreviewInvoice(invalid),
        throwsA(isA<CanonicalValidationFault>()),
      );
    });

    test('throws CanonicalValidationFault when totalAmount is non-positive or missing', () {
      final invalid = Map<String, Object?>.from(validCanonical)..['totalAmount'] = 0;
      expect(
        () => MeInvoiceCanonicalMapper.toPreviewInvoice(invalid),
        throwsA(isA<CanonicalValidationFault>()),
      );
    });

    test('throws CanonicalValidationFault when originalInvoiceDetail is empty', () {
      final invalid = Map<String, Object?>.from(validCanonical)
        ..['originalInvoiceDetail'] = [];
      expect(
        () => MeInvoiceCanonicalMapper.toPreviewInvoice(invalid),
        throwsA(isA<CanonicalValidationFault>()),
      );
    });
  });
}
