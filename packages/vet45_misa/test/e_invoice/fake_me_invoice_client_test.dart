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

    test('ok sendEmail returns status 3 for requested invoice', () async {
      final client = FakeMeInvoiceClient();
      final result = await client.sendEmail(
        const MeInvoiceSendEmailRequest(
          sendEmailDatas: [
            MeInvoiceSendEmailData(
              transactionId: 'tx-1',
              receiverEmail: 'buyer@example.com',
            ),
          ],
          isInvoiceCode: true,
          isInvoiceCalculatingMachine: false,
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.single.transactionId, 'tx-1');
      expect(result.data!.single.sendEmailStatus, 3);
      expect(client.sendEmailCount, 1);
      expect(client.lastSendEmailRequest?.sendEmailDatas.single.transactionId, 'tx-1');
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

    test('previewPublished and download queues are FIFO', () async {
      final client = FakeMeInvoiceClient();
      client.enqueuePreviewPublishedResult(
        MeInvoiceResult.ok('https://preview/queued'),
      );
      client.enqueueDownloadResult(
        MeInvoiceResult.ok([
          MeInvoiceInvoiceDataPublished(
            transactionId: 'tx-1',
            data: '%PDF',
            bytes: '%PDF'.codeUnits,
          ),
        ]),
      );

      final preview = await client.previewPublished(
        transactionIds: ['tx-1'],
        companyTaxCode: '0100109106',
      );
      expect(preview.data, 'https://preview/queued');

      final download = await client.download(
        transactionIds: ['tx-1'],
        query: const MeInvoiceInvoiceQuery(invoiceWithCode: true),
        downloadDataType: MeInvoiceDownloadDataType.pdf,
      );
      expect(download.isSuccess, isTrue);
      expect(download.data!.single.bytes, '%PDF'.codeUnits);
    });

    test('getStatusQueue FIFO overrides scenario and pops sequentially', () async {
      final client = FakeMeInvoiceClient(
        scenario: FakeMeInvoiceScenario.ok,
        getStatusQueue: [
          const MeInvoiceResult.ok(<MeInvoiceInvoiceStatus>[
            MeInvoiceInvoiceStatus(
              refId: 'r1',
              transactionId: 'tx-1',
              publishStatus: 0,
            ),
          ]),
          const MeInvoiceResult.failed('meinvoice_network_timeout'),
        ],
      );

      final first = await client.getStatus(
        ids: const ['r1'],
        inputType: MeInvoiceStatusInputType.refId,
        query: const MeInvoiceInvoiceQuery(invoiceWithCode: true),
      );
      expect(first.isSuccess, isTrue);
      expect(first.data!.single.publishStatus, 0);

      final second = await client.getStatus(
        ids: const ['r1'],
        inputType: MeInvoiceStatusInputType.refId,
        query: const MeInvoiceInvoiceQuery(invoiceWithCode: true),
      );
      expect(second.isSuccess, isFalse);
      expect(second.error, 'meinvoice_network_timeout');

      // Now queue is empty, falls back to scenario (ok)
      final third = await client.getStatus(
        ids: const ['r1'],
        inputType: MeInvoiceStatusInputType.refId,
        query: const MeInvoiceInvoiceQuery(invoiceWithCode: true),
      );
      expect(third.isSuccess, isTrue);
      expect(third.data!.single.publishStatus, 1);

      // Dynamically enqueue
      client.enqueueGetStatusResult(
        const MeInvoiceResult.ok(<MeInvoiceInvoiceStatus>[
          MeInvoiceInvoiceStatus(
            refId: 'r1',
            transactionId: 'tx-dynamic',
            publishStatus: 1,
            invNo: '999',
          ),
        ]),
      );
      final fourth = await client.getStatus(
        ids: const ['r1'],
        inputType: MeInvoiceStatusInputType.refId,
        query: const MeInvoiceInvoiceQuery(invoiceWithCode: true),
      );
      expect(fourth.isSuccess, isTrue);
      expect(fourth.data!.single.invNo, '999');
    });
  });
}
