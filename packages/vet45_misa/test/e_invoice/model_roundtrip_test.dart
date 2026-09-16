import 'dart:convert';

import 'package:test/test.dart';
import 'package:vet45_misa/e_invoice.dart';

/// Round-trip tests using MISA curl fixture shapes (§4, §6).
void main() {
  group('MeInvoiceInvoiceData round-trip', () {
    test('parses and re-emits MISA keys from §4 unpublishview example', () {
      final json = <String, dynamic>{
        'RefID': '337f1acd-cac3-45bd-bb78-924b5d018853',
        'InvSeries': '1C25MLT',
        'InvDate': '2025-11-18',
        'CurrencyCode': 'VND',
        'ExchangeRate': 1.0,
        'PaymentMethodName': 'TM/CK',
        'IsInvoiceCalculatingMachine': true,
        'BuyerLegalName': 'Cong ty co phan MISA',
        'BuyerTaxCode': '0101243150',
        'BuyerAddress': 'Ha Noi',
        'BuyerCode': 'MS001',
        'TotalAmountWithoutVATOC': 5000000.0,
        'TotalVATAmountOC': 500000.0,
        'TotalDiscountAmountOC': 0,
        'TotalAmountOC': 5500000.0,
        'TotalAmountInWords': 'Nam trieu nam tram nghin dong.',
        'OriginalInvoiceDetail': [
          <String, dynamic>{
            'ItemType': 1,
            'LineNumber': 1,
            'ItemCode': 'AOSM01',
            'ItemName': 'M2',
            'UnitName': 'Chiec',
            'Quantity': 10.0,
            'UnitPrice': 500000.0,
            'DiscountRate': 0,
            'DiscountAmountOC': 0,
            'AmountOC': 5000000.0,
            'AmountWithoutVATOC': 5000000.0,
            'VATRateName': '10%',
          },
        ],
        'TaxRateInfo': [
          <String, dynamic>{
            'VATRateName': '10%',
            'AmountWithoutVATOC': 5000000.0,
            'VATAmountOC': 500000.0,
          },
        ],
      };

      final parsed = MeInvoiceInvoiceData.fromJson(json);
      expect(parsed.refId, '337f1acd-cac3-45bd-bb78-924b5d018853');
      expect(parsed.buyerLegalName, 'Cong ty co phan MISA');
      expect(parsed.originalInvoiceDetail, hasLength(1));
      expect(parsed.taxRateInfo, hasLength(1));

      final wire = parsed.toJson();
      expect(wire['RefID'], json['RefID']);
      expect(wire['BuyerLegalName'], json['BuyerLegalName']);
      expect(wire['OriginalInvoiceDetail'], isA<List<dynamic>>());
      expect(
        (wire['OriginalInvoiceDetail'] as List).first['VATRateName'],
        '10%',
      );
    });
  });

  group('MeInvoiceTemplate round-trip', () {
    test('maps §13.1 fields', () {
      const json = <String, dynamic>{
        'IPTemplateID': 'tpl-1',
        'CompanyID': 15388,
        'TemplateName': 'GTGT',
        'InvTemplateNo': '1',
        'InvSeries': '1C25TYY',
        'OrgInvSeries': '1KTYY',
        'CreatedDate': '2024-01-15',
        'Inactive': false,
        'IsSendSummary': true,
      };

      final parsed = MeInvoiceTemplate.fromJson(json);
      expect(parsed.ipTemplateId, 'tpl-1');
      expect(parsed.isSendSummary, isTrue);

      final wire = parsed.toJson();
      expect(wire['IPTemplateID'], 'tpl-1');
      expect(wire['IsSendSummary'], true);
    });
  });

  group('MeInvoicePublishRequest', () {
    test('emits HSM envelope', () {
      final request = MeInvoicePublishRequest(
        signType: MeInvoiceSignType.hsmNoCks,
        invoiceData: [
          MeInvoiceInvoiceData(refId: 'r1', invSeries: '5C25MMB'),
        ],
      );
      final wire = request.toJson();
      expect(wire['SignType'], 5);
      expect(wire['PublishInvoiceData'], isNull);
      expect(wire['InvoiceData'], isA<List<dynamic>>());
    });
  });

  group('MeInvoiceInvoiceQuery', () {
    test('fromInvSeries derives flags per MISA §1.6', () {
      final withCode = MeInvoiceInvoiceQuery.fromInvSeries('1C26TYY');
      expect(withCode.invoiceWithCode, isTrue);
      expect(withCode.invoiceCalcu, isFalse);

      final mtt = MeInvoiceInvoiceQuery.fromInvSeries('2C26MYY');
      expect(mtt.invoiceWithCode, isTrue);
      expect(mtt.invoiceCalcu, isTrue);

      final noCode = MeInvoiceInvoiceQuery.fromInvSeries('1K26TYY');
      expect(noCode.invoiceWithCode, isFalse);
    });

    test('fromInvSeries throws FormatException for malformed series', () {
      for (final invSeries in <String>[
        '',
        '1C2',
        '3C26TYY',
        '1X26TYY',
        '1C26XYY',
      ]) {
        expect(
          () => MeInvoiceInvoiceQuery.fromInvSeries(invSeries),
          throwsFormatException,
          reason: 'expected malformed InvSeries: $invSeries',
        );
      }
    });

    test('tryFromInvSeries returns null for malformed series', () {
      expect(MeInvoiceInvoiceQuery.tryFromInvSeries('3C26TYY'), isNull);
      expect(MeInvoiceInvoiceQuery.tryFromInvSeries('1X26TYY'), isNull);
      expect(MeInvoiceInvoiceQuery.tryFromInvSeries('1C26XYY'), isNull);
    });
  });

  group('MeInvoiceApiResponse', () {
    test('parses publishInvoiceResult envelope', () {
      final body = jsonEncode(<String, dynamic>{
        'success': true,
        'publishInvoiceResult': [
          <String, dynamic>{
            'TransactionID': 'tx-1',
            'InvNo': '0000001',
          },
        ],
      });
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final envelope = MeInvoiceApiResponse.fromJson(decoded);
      expect(envelope.success, isTrue);
      expect(envelope.publishInvoiceResult, hasLength(1));
      expect(envelope.publishInvoiceResult!.single.transactionId, 'tx-1');
    });
  });
}
