import 'i_me_invoice_client.dart';
import 'models/me_invoice_result.dart';
import 'models/misa/invoice_data.dart';
import 'models/misa/invoice_status.dart';
import 'models/misa/template.dart';
import 'models/misa/ticket.dart';
import 'models/requests/invoice_publish_request.dart';
import 'models/requests/invoice_query.dart';
import 'models/requests/send_email_request.dart';
import 'models/responses/invoice_data_published.dart';
import 'models/responses/publish_invoice_result.dart';

/// Test scenarios for [FakeMeInvoiceClient].
enum FakeMeInvoiceScenario {
  ok,
  failed,
  rateLimited,
  missingCredentials,
  tokenExpiredThenOk,
}

/// Test double for [IMeInvoiceClient] — no network.
final class FakeMeInvoiceClient implements IMeInvoiceClient {
  FakeMeInvoiceClient({this.scenario = FakeMeInvoiceScenario.ok});

  FakeMeInvoiceScenario scenario;

  int listInvoiceTemplatesCount = 0;
  int listTicketTemplatesCount = 0;
  int previewUnpublishedCount = 0;
  int publishCount = 0;
  int previewPublishedCount = 0;
  int getStatusCount = 0;
  int downloadCount = 0;
  int sendEmailCount = 0;
  int convertToPaperCount = 0;

  MeInvoicePublishRequest? lastPublishRequest;
  MeInvoiceInvoiceData? lastPreviewInvoice;
  List<String>? lastTransactionIds;
  MeInvoiceSendEmailRequest? lastSendEmailRequest;

  int _tokenExpiredHits = 0;

  @override
  Future<MeInvoiceResult<List<MeInvoiceTemplate>>> listInvoiceTemplates({
    required bool invoiceWithCode,
    int? year,
  }) async {
    listInvoiceTemplatesCount++;
    final early = _scenarioResult<List<MeInvoiceTemplate>>();
    if (early != null) {
      return early;
    }
    return MeInvoiceResult.ok(<MeInvoiceTemplate>[
      const MeInvoiceTemplate(
        ipTemplateId: 'tpl-fake-1',
        companyId: 1,
        templateName: 'Hoa don GTGT',
        invTemplateNo: '1',
        invSeries: '1C25TYY',
        orgInvSeries: '1C25TYY',
      ),
    ]);
  }

  @override
  Future<MeInvoiceResult<List<MeInvoiceTicket>>> listTicketTemplates({
    required bool invoiceWithCode,
    int? year,
  }) async {
    listTicketTemplatesCount++;
    final early = _scenarioResult<List<MeInvoiceTicket>>();
    if (early != null) {
      return early;
    }
    return MeInvoiceResult.ok(<MeInvoiceTicket>[
      const MeInvoiceTicket(
        ticketTemplateId: 'ticket-fake-1',
        templateName: 'Ve dien tu',
        invSeries: '5C25MMB',
      ),
    ]);
  }

  @override
  Future<MeInvoiceResult<String>> previewUnpublished(
    MeInvoiceInvoiceData invoice,
  ) async {
    previewUnpublishedCount++;
    lastPreviewInvoice = invoice;
    final early = _scenarioResult<String>();
    if (early != null) {
      return early;
    }
    return MeInvoiceResult.ok('https://example.test/preview/unpublished');
  }

  @override
  Future<MeInvoiceResult<List<MeInvoicePublishInvoiceResultItem>>> publish(
    MeInvoicePublishRequest request,
  ) async {
    publishCount++;
    lastPublishRequest = request;
    final early = _scenarioResult<List<MeInvoicePublishInvoiceResultItem>>();
    if (early != null) {
      return early;
    }
    return MeInvoiceResult.ok(<MeInvoicePublishInvoiceResultItem>[
      MeInvoicePublishInvoiceResultItem(
        refId: request.invoiceData.firstOrNull?.refId,
        transactionId: 'tx-fake-$publishCount',
        invSeries: request.invoiceData.firstOrNull?.invSeries,
        invNo: '0000001',
      ),
    ]);
  }

  @override
  Future<MeInvoiceResult<String>> previewPublished({
    required List<String> transactionIds,
    required String companyTaxCode,
  }) async {
    previewPublishedCount++;
    lastTransactionIds = List<String>.from(transactionIds);
    final early = _scenarioResult<String>();
    if (early != null) {
      return early;
    }
    return MeInvoiceResult.ok('https://example.test/preview/published');
  }

  @override
  Future<MeInvoiceResult<List<MeInvoiceInvoiceDataPublished>>> download({
    required List<String> transactionIds,
    required MeInvoiceInvoiceQuery query,
    required MeInvoiceDownloadDataType downloadDataType,
  }) async {
    downloadCount++;
    lastTransactionIds = List<String>.from(transactionIds);
    final early = _scenarioResult<List<MeInvoiceInvoiceDataPublished>>();
    if (early != null) {
      return early;
    }
    return MeInvoiceResult.ok(
      transactionIds
          .map(
            (id) => MeInvoiceInvoiceDataPublished(
              transactionId: id,
              data: 'ZmFrZQ==',
              bytes: const <int>[102, 97, 107, 101],
            ),
          )
          .toList(),
    );
  }

  @override
  Future<MeInvoiceResult<List<MeInvoiceInvoiceStatus>>> getStatus({
    required List<String> ids,
    required MeInvoiceStatusInputType inputType,
    required MeInvoiceInvoiceQuery query,
  }) async {
    getStatusCount++;
    lastTransactionIds = List<String>.from(ids);
    final early = _scenarioResult<List<MeInvoiceInvoiceStatus>>();
    if (early != null) {
      return early;
    }
    return MeInvoiceResult.ok(
      ids
          .map(
            (id) => MeInvoiceInvoiceStatus(
              transactionId: id,
              publishStatus: 1,
              invNo: '0000001',
            ),
          )
          .toList(),
    );
  }

  @override
  Future<MeInvoiceResult<void>> sendEmail(
    MeInvoiceSendEmailRequest request,
  ) async {
    sendEmailCount++;
    lastSendEmailRequest = request;
    final early = _scenarioResult<void>();
    if (early != null) {
      return early;
    }
    return const MeInvoiceResult.ok(null);
  }

  @override
  Future<MeInvoiceResult<String>> convertToPaper({
    required List<String> transactionIds,
    required MeInvoiceInvoiceQuery query,
    required String converter,
    required String convertDate,
  }) async {
    convertToPaperCount++;
    lastTransactionIds = List<String>.from(transactionIds);
    final early = _scenarioResult<String>();
    if (early != null) {
      return early;
    }
    return MeInvoiceResult.ok('ZmFrZQ==');
  }

  MeInvoiceResult<T>? _scenarioResult<T>() {
    switch (scenario) {
      case FakeMeInvoiceScenario.ok:
        return null;
      case FakeMeInvoiceScenario.failed:
        return MeInvoiceResult.failed('meinvoice_5xx');
      case FakeMeInvoiceScenario.rateLimited:
        return MeInvoiceResult.failed(
          'meinvoice_429_rate_limited',
          rateLimited: true,
        );
      case FakeMeInvoiceScenario.missingCredentials:
        return MeInvoiceResult.failed('missing_MISA_MEINVOICE_APP_ID');
      case FakeMeInvoiceScenario.tokenExpiredThenOk:
        _tokenExpiredHits++;
        if (_tokenExpiredHits == 1) {
          return MeInvoiceResult.failed('TokenExpiredCode');
        }
        return null;
    }
  }
}
