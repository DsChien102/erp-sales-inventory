import 'package:http/http.dart' as http;
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_misa/e_invoice.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/einvoice_error_mapper.dart';
import 'me_invoice_document_classifier.dart';
import 'me_invoice_observation_classifier.dart';
import 'me_invoice_official_view_classifier.dart';
import 'tenant_me_invoice_client_factory.dart';

/// Worker-only MISA adapter for issued-invoice resources (official view, documents, observation).
final class MeInvoiceElectronicInvoiceProviderAdapter
    implements IElectronicInvoiceProviderPort {
  MeInvoiceElectronicInvoiceProviderAdapter({
    required SupabaseSchemaRpcClient rpcClient,
    required TenantMeInvoiceClientFactory clientFactory,
    required String defaultAppId,
    required String defaultBaseUrl,
    http.Client? httpClient,
    DateTime Function()? now,
  }) : _rpcClient = rpcClient,
       _clientFactory = clientFactory,
       _defaultAppId = defaultAppId,
       _defaultBaseUrl = defaultBaseUrl,
       _httpClient = httpClient ?? http.Client(),
       _now = now ?? DateTime.now;

  final SupabaseSchemaRpcClient _rpcClient;
  final TenantMeInvoiceClientFactory _clientFactory;
  final String _defaultAppId;
  final String _defaultBaseUrl;
  final http.Client _httpClient;
  final DateTime Function() _now;

  @override
  Future<OfficialViewProviderOutcome> fetchOfficialView(
    ElectronicInvoiceProviderContextDto context,
  ) async {
    try {
      final creds = await _readCredentials(tenantId: context.tenantId);
      if (creds == null) {
        return const OfficialViewProviderCheckRequired(
          safeErrorCode: 'PROVIDER_AUTH_FAILED',
        );
      }

      final companyTaxCode = (creds['tax_code'] as String?)?.trim();
      if (companyTaxCode == null || companyTaxCode.isEmpty) {
        return const OfficialViewProviderCheckRequired(
          safeErrorCode: 'PROVIDER_TAX_CODE_MISSING',
        );
      }

      final client = _clientFactory.getOrCreate(
        tenantId: context.tenantId,
        config: _configFromCredentials(creds),
        httpClient: _httpClient,
      );

      final result = await client.previewPublished(
        transactionIds: [context.providerInvoiceReference],
        companyTaxCode: companyTaxCode,
      );

      return MeInvoiceOfficialViewClassifier.classify(
        result: result,
        providerInvoiceReference: context.providerInvoiceReference,
        now: _now().toUtc(),
      );
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }

  @override
  Future<InvoiceDocumentProviderOutcome> downloadDocument(
    ElectronicInvoiceProviderContextDto context,
    InvoiceDocumentType documentType,
  ) async {
    try {
      final query = MeInvoiceInvoiceQuery.tryFromInvSeries(
        context.invoiceSeries,
      );
      if (query == null) {
        return const InvoiceDocumentProviderCheckRequired(
          safeErrorCode: 'INVOICE_SERIES_INVALID',
        );
      }
      final creds = await _readCredentials(tenantId: context.tenantId);
      if (creds == null) {
        return const InvoiceDocumentProviderCheckRequired(
          safeErrorCode: 'PROVIDER_AUTH_FAILED',
        );
      }

      final client = _clientFactory.getOrCreate(
        tenantId: context.tenantId,
        config: _configFromCredentials(creds),
        httpClient: _httpClient,
      );

      final result = await client.download(
        transactionIds: [context.providerInvoiceReference],
        query: query,
        downloadDataType: switch (documentType) {
          InvoiceDocumentType.pdf => MeInvoiceDownloadDataType.pdf,
          InvoiceDocumentType.xml => MeInvoiceDownloadDataType.xml,
        },
      );

      return MeInvoiceDocumentClassifier.classify(
        result: result,
        documentType: documentType,
        providerInvoiceReference: context.providerInvoiceReference,
      );
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }

  @override
  Future<ProviderObservationOutcome> observe(
    ElectronicInvoiceProviderContextDto context,
  ) async {
    try {
      final query = MeInvoiceInvoiceQuery.tryFromInvSeries(
        context.invoiceSeries,
      );
      if (query == null) {
        return const ProviderObservationAmbiguous(
          safeErrorCode: 'INVOICE_SERIES_INVALID',
        );
      }
      final creds = await _readCredentials(tenantId: context.tenantId);
      if (creds == null) {
        return const ProviderObservationAmbiguous(
          safeErrorCode: 'PROVIDER_AUTH_FAILED',
        );
      }

      final client = _clientFactory.getOrCreate(
        tenantId: context.tenantId,
        config: _configFromCredentials(creds),
        httpClient: _httpClient,
      );

      final result = await client.getStatus(
        ids: [context.providerInvoiceReference],
        inputType: MeInvoiceStatusInputType.transactionId,
        query: query,
      );

      return MeInvoiceObservationClassifier.classify(
        result: result,
        providerInvoiceReference: context.providerInvoiceReference,
        now: _now().toUtc(),
      );
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }

  MeInvoiceConfig _configFromCredentials(Map<String, dynamic> creds) {
    return MeInvoiceConfig(
      baseUrl: creds['base_url'] as String? ?? _defaultBaseUrl,
      appId: _defaultAppId,
      taxCode: creds['tax_code'] as String?,
      username: creds['username'] as String?,
      password: creds['password'] as String?,
    );
  }

  Future<Map<String, dynamic>?> _readCredentials({
    required String tenantId,
  }) async {
    final rows = await _rpcClient.callList(
      'read_provider_credentials',
      params: {'p_tenant_id': tenantId},
    );
    if (rows.isEmpty) {
      return null;
    }
    return Map<String, dynamic>.from(rows.first);
  }
}
