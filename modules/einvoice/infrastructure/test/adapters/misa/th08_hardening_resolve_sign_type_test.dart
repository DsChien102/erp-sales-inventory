import 'package:test/test.dart';
import 'package:vet45_einvoice_infrastructure/src/adapters/misa/me_invoice_canonical_mapper.dart';
import 'package:vet45_misa/e_invoice.dart';

Map<String, Object?> _baseCanonical({int? signType}) => {
  'invSeries': '1C26TAA',
  'invDate': '2026-09-03',
  'buyerLegalName': 'Công ty Test',
  'buyerAddress': 'Hà Nội',
  'totalAmount': 100000,
  'totalSaleAmount': 100000,
  'totalAmountWithoutVat': 100000,
  'totalVatAmount': 0,
  if (signType != null) 'signType': signType,
  'originalInvoiceDetail': [
    {
      'lineNumber': 1,
      'itemName': 'SP',
      'quantity': 1,
      'unitPrice': 100000,
      'amount': 100000,
    },
  ],
  'taxRateInfo': [
    {'vatRateName': 'KCT', 'turnover': 100000, 'vatAmount': 0},
  ],
};

void main() {
  group('th08_hardening_resolve — SignType fail-closed', () {
    test('missing signType is rejected', () {
      expect(
        () => MeInvoiceCanonicalMapper.validate(_baseCanonical()),
        throwsA(
          isA<CanonicalValidationFault>().having(
            (f) => f.reasonCode,
            'reasonCode',
            'CANONICAL_MISSING_SIGN_TYPE',
          ),
        ),
      );
    });

    test('MTT series with SignType 2 is rejected', () {
      expect(
        () => MeInvoiceCanonicalMapper.validate(
          _baseCanonical(signType: 2)..['invSeries'] = '2C26MYY',
        ),
        throwsA(
          isA<CanonicalValidationFault>().having(
            (f) => f.reasonCode,
            'reasonCode',
            'CANONICAL_INVALID_SIGN_TYPE',
          ),
        ),
      );
    });

    test('non-MTT series with SignType 5 is rejected', () {
      expect(
        () => MeInvoiceCanonicalMapper.validate(_baseCanonical(signType: 5)),
        throwsA(
          isA<CanonicalValidationFault>().having(
            (f) => f.reasonCode,
            'reasonCode',
            'CANONICAL_INVALID_SIGN_TYPE',
          ),
        ),
      );
    });

    test('publish uses resolved SignType 2 without fallback', () {
      final request = MeInvoiceCanonicalMapper.toPublishRequest(
        canonicalInvoice: _baseCanonical(signType: 2),
        idempotencyKey: 'ref-1',
      );
      expect(request.signType, MeInvoiceSignType.hsmWithCks);
      expect(request.toJson()['SignType'], 2);
    });

    test('publish uses SignType 5 for MTT', () {
      final request = MeInvoiceCanonicalMapper.toPublishRequest(
        canonicalInvoice: _baseCanonical(signType: 5)
          ..['invSeries'] = '2C26MYY',
        idempotencyKey: 'ref-2',
      );
      expect(request.signType, MeInvoiceSignType.hsmNoCks);
      expect(request.toJson()['SignType'], 5);
    });
  });
}
