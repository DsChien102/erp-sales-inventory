import 'models/responses/send_email_result.dart';
import 'i_me_invoice_client.dart';
import 'models/me_invoice_session_token.dart';
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
  FakeMeInvoiceClient({
    this.scenario = FakeMeInvoiceScenario.ok,
    List<MeInvoiceResult<List<MeInvoiceInvoiceStatus>>>? getStatusQueue,
  }) : _getStatusQueue = getStatusQueue != null
           ? List<MeInvoiceResult<List<MeInvoiceInvoiceStatus>>>.from(
               getStatusQueue,
             )
           : <MeInvoiceResult<List<MeInvoiceInvoiceStatus>>>[];

  FakeMeInvoiceScenario scenario;
  final List<MeInvoiceResult<List<MeInvoiceInvoiceStatus>>> _getStatusQueue;

  /// Enqueue a scripted FIFO result for subsequent [getStatus] calls.
  void enqueueGetStatusResult(MeInvoiceResult<List<MeInvoiceInvoiceStatus>> result) {
    _getStatusQueue.add(result);
  }

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
  String? lastCompanyTaxCode;
  MeInvoiceInvoiceQuery? lastDownloadQuery;
  MeInvoiceDownloadDataType? lastDownloadDataType;
  MeInvoiceStatusInputType? lastStatusInputType;
  MeInvoiceInvoiceQuery? lastStatusQuery;
  MeInvoiceSendEmailRequest? lastSendEmailRequest;

  final List<MeInvoiceResult<String>> _previewPublishedQueue = <MeInvoiceResult<String>>[];
  final List<MeInvoiceResult<List<MeInvoiceInvoiceDataPublished>>> _downloadQueue =
      <MeInvoiceResult<List<MeInvoiceInvoiceDataPublished>>>[];
  final List<MeInvoiceResult<MeInvoiceSendEmailResponse>> _sendEmailQueue =
      <MeInvoiceResult<MeInvoiceSendEmailResponse>>[];

  void enqueuePreviewPublishedResult(MeInvoiceResult<String> result) {
    _previewPublishedQueue.add(result);
  }

  void enqueueDownloadResult(
    MeInvoiceResult<List<MeInvoiceInvoiceDataPublished>> result,
  ) {
    _downloadQueue.add(result);
  }

  /// Enqueue a scripted FIFO result for subsequent [sendEmail] calls.
  void enqueueSendEmailResult(MeInvoiceResult<MeInvoiceSendEmailResponse> result) {
    _sendEmailQueue.add(result);
  }

  /// Enqueue official Product envelope acknowledgement (`data=""`).
  void enqueueSendEmailEnvelopeAcknowledgement() {
    enqueueSendEmailResult(
      const MeInvoiceResult.ok(
        MeInvoiceSendEmailResponse.envelopeAcknowledgement(),
      ),
    );
  }

  int _tokenExpiredHits = 0;

  @override
  Future<MeInvoiceResult<MeInvoiceSessionToken>> obtainAccessToken({
    bool forceLogin = false,
  }) async {
    final early = _scenarioResult<MeInvoiceSessionToken>();
    if (early != null) {
      return early;
    }
    return MeInvoiceResult.ok(
      MeInvoiceSessionToken(
        value: 'fake-token',
        expiresAt: DateTime.utc(2099, 1, 1),
      ),
    );
  }

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
    return MeInvoiceResult.ok('https://meinvoice.vn/viewer/preview/unpublished');
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
    lastCompanyTaxCode = companyTaxCode;
    if (_previewPublishedQueue.isNotEmpty) {
      return _previewPublishedQueue.removeAt(0);
    }
    final early = _scenarioResult<String>();
    if (early != null) {
      return early;
    }
    return MeInvoiceResult.ok('https://meinvoice.vn/viewer/preview/published');
  }

  @override
  Future<MeInvoiceResult<List<MeInvoiceInvoiceDataPublished>>> download({
    required List<String> transactionIds,
    required MeInvoiceInvoiceQuery query,
    required MeInvoiceDownloadDataType downloadDataType,
  }) async {
    downloadCount++;
    lastTransactionIds = List<String>.from(transactionIds);
    lastDownloadQuery = query;
    lastDownloadDataType = downloadDataType;
    if (_downloadQueue.isNotEmpty) {
      return _downloadQueue.removeAt(0);
    }
    final early = _scenarioResult<List<MeInvoiceInvoiceDataPublished>>();
    if (early != null) {
      return early;
    }
    return MeInvoiceResult.ok(
      transactionIds
          .map(
            (id) => MeInvoiceInvoiceDataPublished(
              transactionId: id,
              data: 'JVBERi0xLjQ=',
              bytes: '%PDF-1.4 fake'.codeUnits,
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
    lastStatusInputType = inputType;
    lastStatusQuery = query;
    if (_getStatusQueue.isNotEmpty) {
      return _getStatusQueue.removeAt(0);
    }
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
  Future<MeInvoiceResult<MeInvoiceSendEmailResponse>> sendEmail(
    MeInvoiceSendEmailRequest request,
  ) async {
    sendEmailCount++;
    lastSendEmailRequest = request;
    if (_sendEmailQueue.isNotEmpty) {
      return _sendEmailQueue.removeAt(0);
    }
    final early = _scenarioResult<MeInvoiceSendEmailResponse>();
    if (early != null) {
      return early;
    }
    return MeInvoiceResult.ok(
      MeInvoiceSendEmailResponse.itemized(
        request.sendEmailDatas
            .map(
              (item) => MeInvoiceSendEmailResultItem(
                transactionId: item.transactionId,
                sendEmailStatus: 3,
              ),
            )
            .toList(growable: false),
      ),
    );
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
