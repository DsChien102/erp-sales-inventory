import 'package:vet45_einvoice_domain/domain.dart';

import '../exceptions/me_invoice_canonical_validation_exception.dart';
import 'me_invoice_issuance_status_outcome.dart';
import 'me_invoice_publish_outcome.dart';

/// Outbound MISA provider operations (worker-only implementation).
abstract interface class IMeInvoiceProviderPort {
  Future<MeInvoiceAuthOutcome> authenticateAndListTemplates({
    required String tenantId,
    required String connectionId,
  });

  Future<MeInvoicePreviewOutcome> previewUnpublished({
    required String tenantId,
    required Map<String, Object?> canonicalInvoice,
  });

  /// Synchronous preflight before crossing the durable publish dispatch barrier.
  ///
  /// Throws [MeInvoiceCanonicalValidationException] when the canonical payload
  /// is structurally invalid.
  void validateCanonical({required Map<String, Object?> canonicalInvoice});

  Future<MeInvoicePublishOutcome> publish({
    required String tenantId,
    required Map<String, Object?> canonicalInvoice,
    required String idempotencyKey,
  });

  /// Query provider for invoice issuance status by idempotency key (RefID) or provider reference (TransactionID).
  Future<MeInvoiceIssuanceStatusOutcome> getStatus({
    required String tenantId,
    required String idempotencyKey,
    required String payloadHash,
    String? providerReference,
  });
}

/// Result of MISA auth + template listing for capability sync.
final class MeInvoiceAuthOutcome {
  const MeInvoiceAuthOutcome.success({
    required this.templateCount,
    required this.supportsEmailDelivery,
    this.supportedDocumentTypes = const {},
    this.supportsPreview = false,
    this.templates = const [],
  }) : authFailed = false,
       providerUnavailable = false;

  const MeInvoiceAuthOutcome.authFailed()
    : templateCount = 0,
      supportsEmailDelivery = false,
      supportedDocumentTypes = const {},
      supportsPreview = false,
      templates = const [],
      authFailed = true,
      providerUnavailable = false;

  const MeInvoiceAuthOutcome.providerUnavailable()
    : templateCount = 0,
      supportsEmailDelivery = false,
      supportedDocumentTypes = const {},
      supportsPreview = false,
      templates = const [],
      authFailed = false,
      providerUnavailable = true;

  final int templateCount;
  final bool supportsEmailDelivery;
  final Set<InvoiceDocumentType> supportedDocumentTypes;
  final bool supportsPreview;
  final List<ProviderTemplateRef> templates;
  final bool authFailed;
  final bool providerUnavailable;

  bool get isSuccess => !authFailed && !providerUnavailable;
}

/// Result of a MISA unpublished-preview request.
final class MeInvoicePreviewOutcome {
  const MeInvoicePreviewOutcome.success({required String viewerRef})
    : _viewerRef = viewerRef,
      authFailed = false,
      providerUnavailable = false;

  const MeInvoicePreviewOutcome.authFailed()
    : _viewerRef = null,
      authFailed = true,
      providerUnavailable = false;

  const MeInvoicePreviewOutcome.providerUnavailable()
    : _viewerRef = null,
      authFailed = false,
      providerUnavailable = true;

  final String? _viewerRef;
  final bool authFailed;
  final bool providerUnavailable;

  bool get isSuccess => !authFailed && !providerUnavailable;
  String? get viewerRef => _viewerRef;
}
