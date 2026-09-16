import 'package:http/http.dart' as http;
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_misa/e_invoice.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/einvoice_error_mapper.dart';
import 'me_invoice_delivery_classifier.dart';
import 'tenant_me_invoice_client_factory.dart';

/// Worker-only MISA adapter for invoice email delivery (`sendEmail` only).
///
/// Never calls `getStatus`, download, preview, or observation APIs.
/// Does not log recipient addresses or provider payloads.
final class MeInvoiceDeliveryProviderAdapter
    implements IInvoiceDeliveryProviderPort {
  MeInvoiceDeliveryProviderAdapter({
    required SupabaseSchemaRpcClient rpcClient,
    required TenantMeInvoiceClientFactory clientFactory,
    required String defaultAppId,
    required String defaultBaseUrl,
    http.Client? httpClient,
    ILogger? logger,
  }) : _rpcClient = rpcClient,
       _clientFactory = clientFactory,
       _defaultAppId = defaultAppId,
       _defaultBaseUrl = defaultBaseUrl,
       _logger = logger,
       _httpClient = httpClient ?? http.Client();

  final SupabaseSchemaRpcClient _rpcClient;
  final TenantMeInvoiceClientFactory _clientFactory;
  final String _defaultAppId;
  final String _defaultBaseUrl;
  final http.Client _httpClient;
  final ILogger? _logger;

  @override
  Future<DeliveryProviderOutcome> sendEmail(
    DeliveryProviderContextDto context,
  ) async {
    try {
      final query = MeInvoiceInvoiceQuery.tryFromInvSeries(
        context.invoiceSeries,
      );
      if (query == null) {
        return const DeliveryProviderDefiniteFailure('INVOICE_SERIES_INVALID');
      }
      final creds = await _readCredentials(tenantId: context.tenantId);
      if (creds == null) {
        return const DeliveryProviderDefiniteFailure('PROVIDER_AUTH_FAILED');
      }

      final config = _configFromCredentials(creds);
      final client = _clientFactory.getOrCreate(
        tenantId: context.tenantId,
        config: config,
        httpClient: _httpClient,
      );

      final result = await client.sendEmail(
        MeInvoiceSendEmailRequest(
          sendEmailDatas: [
            MeInvoiceSendEmailData(
              transactionId: context.providerTransactionId,
              receiverEmail: context.recipientEmail,
              receiverName: context.recipientName,
            ),
          ],
          isInvoiceCode: query.invoiceWithCode,
          isInvoiceCalculatingMachine: query.invoiceCalcu,
        ),
      );

      final outcome = MeInvoiceDeliveryClassifier.classify(
        result,
        transactionId: context.providerTransactionId,
      );
      final resolved = outcome is DeliveryProviderSucceeded
          ? DeliveryProviderSucceeded(
              providerReference: context.providerTransactionId,
            )
          : outcome;
      _logger?.info({
        'event': 'einvoice_email_provider_result',
        'tenantId': context.tenantId,
        'providerTransactionId': context.providerTransactionId,
        'outcomeKind': switch (resolved) {
          DeliveryProviderSucceeded() => 'succeeded',
          DeliveryProviderDefiniteFailure() => 'definite_failure',
          DeliveryProviderRetryableFailure() => 'retryable_failure',
          DeliveryProviderUndetermined() => 'undetermined',
        },
        'safeCode': switch (resolved) {
          DeliveryProviderSucceeded() => null,
          DeliveryProviderDefiniteFailure(:final safeErrorCode) =>
            safeErrorCode,
          DeliveryProviderRetryableFailure(:final safeErrorCode) =>
            safeErrorCode,
          DeliveryProviderUndetermined(:final safeErrorCode) => safeErrorCode,
        },
      });
      return resolved;
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
