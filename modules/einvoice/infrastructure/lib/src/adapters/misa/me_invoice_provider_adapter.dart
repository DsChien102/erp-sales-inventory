import 'package:http/http.dart' as http;
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_misa/e_invoice.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import 'tenant_me_invoice_client_factory.dart';
import '../../errors/einvoice_error_mapper.dart';

/// Loads tenant MISA credentials via RPC and performs auth + template sync.
final class MeInvoiceProviderAdapter implements IMeInvoiceProviderPort {
  MeInvoiceProviderAdapter({
    required SupabaseSchemaRpcClient rpcClient,
    required TenantMeInvoiceClientFactory clientFactory,
    required String defaultAppId,
    required String defaultBaseUrl,
    http.Client? httpClient,
  }) : _rpcClient = rpcClient,
       _clientFactory = clientFactory,
       _defaultAppId = defaultAppId,
       _defaultBaseUrl = defaultBaseUrl,
       _httpClient = httpClient ?? http.Client();

  final SupabaseSchemaRpcClient _rpcClient;
  final TenantMeInvoiceClientFactory _clientFactory;
  final String _defaultAppId;
  final String _defaultBaseUrl;
  final http.Client _httpClient;

  @override
  Future<MeInvoiceAuthOutcome> authenticateAndListTemplates({
    required String tenantId,
    required String connectionId,
  }) async {
    try {
      final creds = await _readCredentials(tenantId: tenantId);
      if (creds == null) {
        return const MeInvoiceAuthOutcome.authFailed();
      }

      final client = _clientFactory.getOrCreate(
        tenantId: tenantId,
        config: MeInvoiceConfig(
          baseUrl: creds['base_url'] as String? ?? _defaultBaseUrl,
          appId: _defaultAppId,
          taxCode: creds['tax_code'] as String?,
          username: creds['username'] as String?,
          password: creds['password'] as String?,
        ),
        httpClient: _httpClient,
      );

      final tokenResult = await client.obtainAccessToken(forceLogin: true);
      if (!tokenResult.isSuccess) {
        _clientFactory.invalidate(tenantId);
        final message = tokenResult.error ?? '';
        if (message.toLowerCase().contains('missing credential')) {
          return const MeInvoiceAuthOutcome.authFailed();
        }
        if (message.toLowerCase().contains('unavailable') ||
            message.toLowerCase().contains('timeout')) {
          return const MeInvoiceAuthOutcome.providerUnavailable();
        }
        return const MeInvoiceAuthOutcome.authFailed();
      }

      final templatesResult = await client.listInvoiceTemplates(
        invoiceWithCode: true,
      );
      if (!templatesResult.isSuccess) {
        final message = templatesResult.error ?? '';
        if (message.toLowerCase().contains('unavailable') ||
            message.toLowerCase().contains('timeout')) {
          return const MeInvoiceAuthOutcome.providerUnavailable();
        }
        return const MeInvoiceAuthOutcome.authFailed();
      }

      final templates = templatesResult.data ?? const [];
      return MeInvoiceAuthOutcome.success(
        templateCount: templates.length,
        supportsEmailDelivery: true,
      );
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
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
