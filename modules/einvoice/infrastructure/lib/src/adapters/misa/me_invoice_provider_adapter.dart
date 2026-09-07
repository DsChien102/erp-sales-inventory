import 'package:http/http.dart' as http;
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_misa/e_invoice.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import 'tenant_me_invoice_client_factory.dart';
import '../../errors/einvoice_error_mapper.dart';
import 'me_invoice_canonical_mapper.dart';
import 'me_invoice_endpoint_capabilities.dart';
import 'me_invoice_issuance_status_classifier.dart';
import 'me_invoice_publish_classifier.dart';

/// Loads tenant MISA credentials via RPC and performs auth + template sync.
final class MeInvoiceProviderAdapter implements IMeInvoiceProviderPort {
  MeInvoiceProviderAdapter({
    required SupabaseSchemaRpcClient rpcClient,
    required TenantMeInvoiceClientFactory clientFactory,
    required String defaultAppId,
    required String defaultBaseUrl,
    bool emailDeliveryEnabled = false,
    http.Client? httpClient,
    ILogger? logger,
  }) : _rpcClient = rpcClient,
       _clientFactory = clientFactory,
       _defaultAppId = defaultAppId,
       _defaultBaseUrl = defaultBaseUrl,
       _emailDeliveryEnabled = emailDeliveryEnabled,
       _httpClient = httpClient ?? http.Client(),
       _logger = logger;

  final SupabaseSchemaRpcClient _rpcClient;
  final TenantMeInvoiceClientFactory _clientFactory;
  final String _defaultAppId;
  final String _defaultBaseUrl;
  final bool _emailDeliveryEnabled;
  final http.Client _httpClient;
  final ILogger? _logger;

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

      final baseUrlUri = Uri.parse(
        creds['base_url'] as String? ?? _defaultBaseUrl,
      );
      final endpointCaps = MeInvoiceEndpointCapabilities.resolve(
        baseUrl: baseUrlUri,
        emailDeliveryEnabled: _emailDeliveryEnabled,
      );

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
        _logVerificationFailure(stage: 'token', error: message);
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
        _clientFactory.invalidate(tenantId);
        _logVerificationFailure(stage: 'templates', error: message);
        if (message.toLowerCase().contains('unavailable') ||
            message.toLowerCase().contains('timeout')) {
          return const MeInvoiceAuthOutcome.providerUnavailable();
        }
        return const MeInvoiceAuthOutcome.authFailed();
      }

      final templates = templatesResult.data ?? const [];
      final templateRefs = templates
          .where((t) => !t.inactive)
          .map(
            (t) => ProviderTemplateRef(
              templateId: t.ipTemplateId,
              name: t.templateName,
              serial: t.invTemplateNo,
              symbol: t.invSeries,
              isMtt: false,
              isAvailable: !t.inactive,
            ),
          )
          .toList(growable: false);

      return MeInvoiceAuthOutcome.success(
        templateCount: templateRefs.length,
        supportsEmailDelivery: endpointCaps.supportsEmailDelivery,
        supportedDocumentTypes: endpointCaps.supportedDocumentTypes,
        supportsPreview: endpointCaps.supportsPreview,
        templates: templateRefs,
      );
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }

  void _logVerificationFailure({required String stage, required String error}) {
    final reason = _safeFailureReason(error);
    _logger?.warning(
      'MISA connection verification failed stage=$stage reason=$reason',
    );
  }

  static String _safeFailureReason(String error) {
    final trimmed = error.trim();
    final lower = trimmed.toLowerCase();
    if (lower.contains('timeout')) {
      return 'TIMEOUT';
    }
    if (lower.contains('unavailable')) {
      return 'PROVIDER_UNAVAILABLE';
    }

    const rejectedPrefix = 'meinvoice_auth_rejected:';
    if (trimmed.startsWith(rejectedPrefix)) {
      return _safeCode(trimmed.substring(rejectedPrefix.length));
    }

    final separator = trimmed.indexOf(':');
    if (separator >= 0 && separator + 1 < trimmed.length) {
      final suffixCode = _safeCode(trimmed.substring(separator + 1));
      if (suffixCode != 'UNKNOWN_PROVIDER_FAILURE') {
        return suffixCode;
      }
    }

    if (trimmed.startsWith('missing_')) {
      return _safeCode(trimmed);
    }
    return _safeCode(trimmed);
  }

  static String _safeCode(String candidate) {
    final match = RegExp(
      r'^[A-Za-z][A-Za-z0-9_]{0,63}',
    ).firstMatch(candidate.trim());
    return match?.group(0) ?? 'UNKNOWN_PROVIDER_FAILURE';
  }

  /// Keeps short vendor detail (e.g. Errors list) without raw credential material.
  static String? _safePreviewFailureDetail(String message) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    const prefix = 'InvalidInvoiceData:';
    if (trimmed.startsWith(prefix)) {
      final rest = trimmed.substring(prefix.length).trim();
      if (rest.isEmpty || rest == 'InvalidInvoiceData') {
        return null;
      }
      return rest.length <= 180 ? rest : '${rest.substring(0, 180)}…';
    }
    final colon = trimmed.indexOf(':');
    if (colon > 0 && colon + 1 < trimmed.length) {
      final rest = trimmed.substring(colon + 1).trim();
      if (rest.isNotEmpty) {
        return rest.length <= 180 ? rest : '${rest.substring(0, 180)}…';
      }
    }
    return null;
  }

  @override
  Future<MeInvoicePreviewOutcome> previewUnpublished({
    required String tenantId,
    required Map<String, Object?> canonicalInvoice,
  }) async {
    try {
      final creds = await _readCredentials(tenantId: tenantId);
      if (creds == null) {
        return const MeInvoicePreviewOutcome.authFailed();
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

      final invoice = MeInvoiceCanonicalMapper.toPreviewInvoice(canonicalInvoice);
      final result = await client.previewUnpublished(invoice);
      if (!result.isSuccess) {
        final message = result.error ?? '';
        final reason = _safeFailureReason(message);
        final detail = _safePreviewFailureDetail(message);
        _logger?.warning(
          'MISA unpublished preview failed reason=$reason'
          '${detail == null ? '' : ' detail=$detail'}',
        );
        final lower = message.toLowerCase();
        if (lower.contains('unavailable') || lower.contains('timeout')) {
          return const MeInvoicePreviewOutcome.providerUnavailable();
        }
        return const MeInvoicePreviewOutcome.authFailed();
      }

      return MeInvoicePreviewOutcome.success(viewerRef: result.data ?? '');
    } on CanonicalValidationFault catch (fault) {
      _logger?.warning(
        'MISA preview canonical validation failed: ${fault.reasonCode}',
      );
      return const MeInvoicePreviewOutcome.authFailed();
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }

  @override
  void validateCanonical({required Map<String, Object?> canonicalInvoice}) {
    try {
      MeInvoiceCanonicalMapper.validate(canonicalInvoice);
    } on CanonicalValidationFault catch (error) {
      throw MeInvoiceCanonicalValidationException(
        error.reasonCode,
        message: error.message,
      );
    }
  }

  @override
  Future<MeInvoicePublishOutcome> publish({
    required String tenantId,
    required Map<String, Object?> canonicalInvoice,
    required String idempotencyKey,
  }) async {
    try {
      final creds = await _readCredentials(tenantId: tenantId);
      if (creds == null) {
        return MeInvoicePublishUndetermined(
          reasonCode: 'PROVIDER_AUTH_FAILED',
          safeProviderEvidence: MeInvoiceSafeProviderEvidence(
            refId: idempotencyKey,
          ),
        );
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

      final MeInvoicePublishRequest request;
      try {
        request = MeInvoiceCanonicalMapper.toPublishRequest(
          canonicalInvoice: canonicalInvoice,
          idempotencyKey: idempotencyKey,
        );
      } on CanonicalValidationFault catch (error) {
        throw MeInvoiceCanonicalValidationException(
          error.reasonCode,
          message: error.message,
        );
      }
      final result = await client.publish(request);
      return MeInvoicePublishClassifier.classify(
        idempotencyKey: idempotencyKey,
        result: result,
        canonicalInvoice: canonicalInvoice,
      );
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }

  @override
  Future<MeInvoiceIssuanceStatusOutcome> getStatus({
    required String tenantId,
    required String idempotencyKey,
    required String payloadHash,
    String? providerReference,
  }) async {
    try {
      final creds = await _readCredentials(tenantId: tenantId);
      if (creds == null) {
        return const MeInvoiceIssuanceStatusOutcome.undetermined(
          'PROVIDER_AUTH_FAILED',
        );
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

      final bool useTransactionId =
          providerReference != null && providerReference.trim().isNotEmpty;
      final statusResult = await client.getStatus(
        ids: [useTransactionId ? providerReference : idempotencyKey],
        inputType: useTransactionId
            ? MeInvoiceStatusInputType.transactionId
            : MeInvoiceStatusInputType.refId,
        query: const MeInvoiceInvoiceQuery(invoiceWithCode: true),
      );

      return MeInvoiceIssuanceStatusClassifier.classify(
        statusResult: statusResult,
        idempotencyKey: idempotencyKey,
        payloadHash: payloadHash,
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
