import 'dart:convert';
import 'models/responses/send_email_result.dart';
import 'package:http/http.dart' as http;

import 'i_me_invoice_client.dart';
import 'internal/api_response_parser.dart';
import 'internal/me_invoice_auth.dart';
import 'internal/me_invoice_http.dart';
import 'models/me_invoice_config.dart';
import 'models/me_invoice_result.dart';
import 'models/me_invoice_session_token.dart';
import 'models/misa/invoice_data.dart';
import 'models/misa/invoice_status.dart';
import 'models/misa/template.dart';
import 'models/misa/ticket.dart';
import 'models/requests/invoice_publish_request.dart';
import 'models/requests/invoice_query.dart';
import 'models/requests/send_email_request.dart';
import 'models/requests/transaction_ids_body.dart';
import 'models/responses/invoice_data_published.dart';
import 'models/responses/publish_invoice_result.dart';

/// Real MISA meInvoice HTTP client. Missing credentials soft-fail (no network).
final class MeInvoiceClient implements IMeInvoiceClient {
  MeInvoiceClient({
    required MeInvoiceConfig config,
    http.Client? httpClient,
  }) : _config = config,
       _httpClient = httpClient ?? http.Client() {
    if (config.hasCredentials) {
      MeInvoiceAuthToken? initial;
      final bearer = config.accessToken?.trim();
      if (bearer != null && bearer.isNotEmpty) {
        initial = MeInvoiceAuthToken(
          value: bearer,
          expiresAt:
              config.accessTokenExpiresAt?.toUtc() ??
              DateTime.now().toUtc().add(MeInvoiceConfig.recommendedTokenTtl),
        );
      }
      _auth = MeInvoiceAuth(
        baseUrl: config.baseUrl,
        appId: config.appId,
        taxCode: config.taxCode,
        username: config.username,
        password: config.password,
        httpClient: _httpClient,
        initialToken: initial,
        defaultTtl: MeInvoiceConfig.recommendedTokenTtl,
      );
      _api = MeInvoiceHttp(auth: _auth!, httpClient: _httpClient);
    }
  }

  final MeInvoiceConfig _config;
  final http.Client _httpClient;
  MeInvoiceAuth? _auth;
  MeInvoiceHttp? _api;

  static const maxTransactionIdsPerCall = 50;

  /// Login or return cached Bearer. Prefer rare calls (~7 day refresh; ~14 day MISA TTL); MISA may
  /// block IPs that hit `/auth/token` per invoice.
  @override
  Future<MeInvoiceResult<MeInvoiceSessionToken>> obtainAccessToken({
    bool forceLogin = false,
  }) async {
    final gate = _guard<MeInvoiceSessionToken>();
    if (gate != null) {
      return gate;
    }
    try {
      final token = await _auth!.getToken(forceRefresh: forceLogin);
      return MeInvoiceResult.ok(
        MeInvoiceSessionToken(value: token.value, expiresAt: token.expiresAt),
      );
    } on MeInvoiceAuthException catch (e) {
      return MeInvoiceResult.failed(e.message);
    }
  }

  @override
  Future<MeInvoiceResult<List<MeInvoiceTemplate>>> listInvoiceTemplates({
    required bool invoiceWithCode,
    int? year,
  }) {
    return _listTemplates(
      invoiceWithCode: invoiceWithCode,
      ticket: false,
      year: year,
      fromJson: MeInvoiceTemplate.fromJson,
    );
  }

  @override
  Future<MeInvoiceResult<List<MeInvoiceTicket>>> listTicketTemplates({
    required bool invoiceWithCode,
    int? year,
  }) {
    return _listTemplates(
      invoiceWithCode: invoiceWithCode,
      ticket: true,
      year: year,
      fromJson: MeInvoiceTicket.fromJson,
    );
  }

  Future<MeInvoiceResult<List<T>>> _listTemplates<T>({
    required bool invoiceWithCode,
    required bool ticket,
    required int? year,
    required T Function(Map<String, dynamic> json) fromJson,
  }) async {
    final gate = _guard<List<T>>();
    if (gate != null) {
      return gate;
    }
    final query = <String, String>{
      'invoiceWithCode': invoiceWithCode.toString(),
      'ticket': ticket.toString(),
      if (year != null) 'year': '$year',
    };
    final raw = await _api!.get('/invoice/templates', query: query);
    if (!raw.isSuccess) {
      return MeInvoiceResult.failed(
        raw.error!,
        rateLimited: raw.rateLimited,
      );
    }
    final items = MeInvoiceApiResponseParser.parseDataList(
      raw.data!.data,
      fromJson,
    );
    return MeInvoiceResult.ok(items);
  }

  @override
  Future<MeInvoiceResult<String>> previewUnpublished(
    MeInvoiceInvoiceData invoice,
  ) async {
    final gate = _guard<String>();
    if (gate != null) {
      return gate;
    }
    final raw = await _api!.postJson(
      '/invoice/unpublishview',
      body: invoice.toJson(),
    );
    if (!raw.isSuccess) {
      return MeInvoiceResult.failed(
        raw.error!,
        rateLimited: raw.rateLimited,
      );
    }
    final link = MeInvoiceApiResponseParser.parseDataString(raw.data!.data);
    if (link == null || link.isEmpty) {
      return const MeInvoiceResult.failed('meinvoice_preview_empty_data');
    }
    return MeInvoiceResult.ok(link);
  }

  @override
  Future<MeInvoiceResult<List<MeInvoicePublishInvoiceResultItem>>> publish(
    MeInvoicePublishRequest request,
  ) async {
    final gate = _guard<List<MeInvoicePublishInvoiceResultItem>>();
    if (gate != null) {
      return gate;
    }
    final raw = await _api!.postJson('/invoice', body: request.toJson());
    if (!raw.isSuccess) {
      return MeInvoiceResult.failed(
        raw.error!,
        rateLimited: raw.rateLimited,
      );
    }
    final items = raw.data!.publishInvoiceResult;
    if (items == null || items.isEmpty) {
      return const MeInvoiceResult.failed(
        'meinvoice_publish_empty_or_invalid_result',
      );
    }
    return MeInvoiceResult.ok(items);
  }

  @override
  Future<MeInvoiceResult<String>> previewPublished({
    required List<String> transactionIds,
    required String companyTaxCode,
  }) async {
    final gate = _guard<String>();
    if (gate != null) {
      return gate;
    }
    final idError = _validateTransactionIds(transactionIds);
    if (idError != null) {
      return MeInvoiceResult.failed(idError);
    }
    final raw = await _api!.postRaw(
      '/invoice/publishview',
      body: encodeTransactionIdsBody(transactionIds),
      extraHeaders: <String, String>{'CompanyTaxCode': companyTaxCode},
    );
    if (!raw.isSuccess) {
      return MeInvoiceResult.failed(
        raw.error!,
        rateLimited: raw.rateLimited,
      );
    }
    final link = MeInvoiceApiResponseParser.parseDataString(raw.data!.data);
    if (link == null || link.isEmpty) {
      return const MeInvoiceResult.failed('meinvoice_preview_empty_data');
    }
    return MeInvoiceResult.ok(link);
  }

  @override
  Future<MeInvoiceResult<List<MeInvoiceInvoiceDataPublished>>> download({
    required List<String> transactionIds,
    required MeInvoiceInvoiceQuery query,
    required MeInvoiceDownloadDataType downloadDataType,
  }) async {
    final gate = _guard<List<MeInvoiceInvoiceDataPublished>>();
    if (gate != null) {
      return gate;
    }
    final idError = _validateTransactionIds(transactionIds);
    if (idError != null) {
      return MeInvoiceResult.failed(idError);
    }
    final raw = await _api!.postRaw(
      '/invoice/download',
      body: encodeTransactionIdsBody(transactionIds),
      query: query.toQueryParameters(
        downloadDataType: downloadDataType,
      ),
    );
    if (!raw.isSuccess) {
      return MeInvoiceResult.failed(
        raw.error!,
        rateLimited: raw.rateLimited,
      );
    }
    final items = MeInvoiceApiResponseParser.parseDataList(
      raw.data!.data,
      MeInvoiceInvoiceDataPublished.fromJson,
    );
    if (items.isEmpty) {
      return const MeInvoiceResult.failed('meinvoice_download_empty_data');
    }
    return MeInvoiceResult.ok(items);
  }

  @override
  Future<MeInvoiceResult<List<MeInvoiceInvoiceStatus>>> getStatus({
    required List<String> ids,
    required MeInvoiceStatusInputType inputType,
    required MeInvoiceInvoiceQuery query,
  }) async {
    final gate = _guard<List<MeInvoiceInvoiceStatus>>();
    if (gate != null) {
      return gate;
    }
    final idError = _validateTransactionIds(ids);
    if (idError != null) {
      return MeInvoiceResult.failed(idError);
    }
    final raw = await _api!.postRaw(
      '/invoice/status',
      body: encodeTransactionIdsBody(ids),
      query: query.toQueryParameters(inputType: inputType),
    );
    if (!raw.isSuccess) {
      return MeInvoiceResult.failed(
        raw.error!,
        rateLimited: raw.rateLimited,
      );
    }
    final items = MeInvoiceApiResponseParser.parseDataList(
      raw.data!.data,
      MeInvoiceInvoiceStatus.fromJson,
    );
    if (items.isEmpty) {
      return const MeInvoiceResult.failed('meinvoice_status_empty_data');
    }
    return MeInvoiceResult.ok(items);
  }

  @override
  Future<MeInvoiceResult<List<MeInvoiceSendEmailResultItem>>> sendEmail(
    MeInvoiceSendEmailRequest request,
  ) async {
    final gate = _guard<List<MeInvoiceSendEmailResultItem>>();
    if (gate != null) {
      return gate;
    }
    final raw = await _api!.postJson(
      '/invoice/sendemail',
      body: request.toJson(),
    );
    if (!raw.isSuccess) {
      return MeInvoiceResult.failed(
        raw.error!,
        rateLimited: raw.rateLimited,
      );
    }
    try {
      final envelope = raw.data!;
      final errors = envelope.errors;
      if (errors != null &&
          errors != '' &&
          !(errors is List && errors.isEmpty) &&
          !(errors is Map && errors.isEmpty)) {
        return const MeInvoiceResult.failed('meinvoice_send_email_invalid_response');
      }
      final data = envelope.data is String ? jsonDecode(envelope.data as String) : envelope.data;
      if (data is! List || data.isEmpty || data.any((item) => item is! Map)) {
        return const MeInvoiceResult.failed('meinvoice_send_email_invalid_response');
      }
      return MeInvoiceResult.ok(
        data
            .map(
              (item) =>
                  MeInvoiceSendEmailResultItem.fromJson(Map<String, dynamic>.from(item as Map)),
            )
            .toList(),
      );
    } on Object {
      return const MeInvoiceResult.failed('meinvoice_send_email_invalid_response');
    }
  }

  @override
  Future<MeInvoiceResult<String>> convertToPaper({
    required List<String> transactionIds,
    required MeInvoiceInvoiceQuery query,
    required String converter,
    required String convertDate,
  }) async {
    final gate = _guard<String>();
    if (gate != null) {
      return gate;
    }
    final idError = _validateTransactionIds(transactionIds);
    if (idError != null) {
      return MeInvoiceResult.failed(idError);
    }
    final raw = await _api!.postRaw(
      '/invoice/voucher-paper',
      body: encodeTransactionIdsBody(transactionIds),
      query: query.toQueryParameters(
        converter: converter,
        convertDate: convertDate,
      ),
    );
    if (!raw.isSuccess) {
      return MeInvoiceResult.failed(
        raw.error!,
        rateLimited: raw.rateLimited,
      );
    }
    final data = MeInvoiceApiResponseParser.parseDataString(raw.data!.data);
    if (data == null || data.isEmpty) {
      return const MeInvoiceResult.failed('meinvoice_voucher_paper_empty_data');
    }
    return MeInvoiceResult.ok(data);
  }

  String? _validateTransactionIds(List<String> ids) {
    if (ids.isEmpty) {
      return 'meinvoice_empty_transaction_ids';
    }
    if (ids.length > maxTransactionIdsPerCall) {
      return 'meinvoice_too_many_transaction_ids';
    }
    return null;
  }

  MeInvoiceResult<T>? _guard<T>() {
    final missing = _config.missingCredentialError;
    if (missing != null) {
      return MeInvoiceResult.failed(missing);
    }
    return null;
  }
}
