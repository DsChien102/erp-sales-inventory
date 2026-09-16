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
}
