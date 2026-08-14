import 'package:test/test.dart';
import 'package:vet45_misa/e_invoice.dart';

MeInvoiceInvoiceData _sampleInvoice({String refId = 'r1'}) {
  return MeInvoiceInvoiceData(
    refId: refId,
    invSeries: '1C25TYY',
    invDate: '2026-01-01',
    buyerLegalName: 'Buyer',
    buyerAddress: 'Address',
    totalAmountWithoutVatOc: 1000,
    totalVatAmountOc: 100,
    totalDiscountAmountOc: 0,
    totalAmountOc: 1100,
    totalAmountInWords: 'One thousand one hundred',
    originalInvoiceDetail: const [
      MeInvoiceOriginalInvoiceDetail(
        itemType: 1,
        lineNumber: 1,
        sortOrder: 1,
        itemName: 'A',
        quantity: 1,
        unitPrice: 1000,
        amountOc: 1000,
        amountWithoutVatOc: 1000,
        vatRateName: '10%',
      ),
    ],
    taxRateInfo: const [
      MeInvoiceTaxRateInfo(
        vatRateName: '10%',
        amountWithoutVatOc: 1000,
        vatAmountOc: 100,
      ),
    ],
  );
}

void main() {
  group('FakeMeInvoiceClient', () {
    test('ok scenario returns templates and publish', () async {
      final client = FakeMeInvoiceClient();
      final templates = await client.listInvoiceTemplates(
        invoiceWithCode: true,
      );
      expect(templates.isSuccess, isTrue);
      expect(templates.data, isNotEmpty);

      final published = await client.publish(
        MeInvoicePublishRequest(
          signType: MeInvoiceSignType.hsmWithCks,
          invoiceData: [_sampleInvoice()],
        ),
      );
      expect(published.isSuccess, isTrue);
      expect(published.data!.single.transactionId, 'tx-fake-1');
      expect(client.publishCount, 1);
      expect(client.lastPublishRequest?.invoiceData.first.refId, 'r1');
    });

    test('failed and rateLimited scenarios', () async {
      final client = FakeMeInvoiceClient(scenario: FakeMeInvoiceScenario.failed);
      var result = await client.getStatus(
        ids: const ['tx'],
        inputType: MeInvoiceStatusInputType.transactionId,
        query: const MeInvoiceInvoiceQuery(invoiceWithCode: true),
      );
      expect(result.error, 'meinvoice_5xx');

      client.scenario = FakeMeInvoiceScenario.rateLimited;
      result = await client.getStatus(
        ids: const ['tx'],
        inputType: MeInvoiceStatusInputType.transactionId,
        query: const MeInvoiceInvoiceQuery(invoiceWithCode: true),
      );
      expect(result.rateLimited, isTrue);
    });

    test('missingCredentials scenario', () async {
      final client = FakeMeInvoiceClient(
        scenario: FakeMeInvoiceScenario.missingCredentials,
      );
      final result = await client.download(
        transactionIds: const ['tx'],
        query: const MeInvoiceInvoiceQuery(invoiceWithCode: true),
        downloadDataType: MeInvoiceDownloadDataType.xml,
      );
      expect(result.error, 'missing_MISA_MEINVOICE_APP_ID');
    });

    test('tokenExpiredThenOk fails once then succeeds', () async {
      final client = FakeMeInvoiceClient(
        scenario: FakeMeInvoiceScenario.tokenExpiredThenOk,
      );
      final first = await client.listInvoiceTemplates(invoiceWithCode: true);
      expect(first.error, 'TokenExpiredCode');

      final second = await client.listInvoiceTemplates(invoiceWithCode: true);
      expect(second.isSuccess, isTrue);
    });
  });
}
