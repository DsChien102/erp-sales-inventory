import 'package:vet45_einvoice_domain/domain.dart';

import '../exceptions/me_invoice_canonical_validation_exception.dart';
import '../issuance/shared/issuance_provider_status_lookup.dart';
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

  /// Query provider for invoice issuance status.
  ///
  /// [statusLookupKey] is interpreted per [statusLookup] (transaction id vs RefID).
  Future<MeInvoiceIssuanceStatusOutcome> getStatus({
    required String tenantId,
    required String statusLookupKey,
    required String invoiceSeries,
    required String idempotencyKey,
    required String payloadHash,
    IssuanceProviderStatusLookup statusLookup = IssuanceProviderStatusLookup.providerTransactionId,
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
      providerUnavailable = false,
      invalidData = false,
      reasonDetail = null;

  const MeInvoicePreviewOutcome.authFailed()
    : _viewerRef = null,
      authFailed = true,
      providerUnavailable = false,
      invalidData = false,
      reasonDetail = null;

  const MeInvoicePreviewOutcome.providerUnavailable()
    : _viewerRef = null,
      authFailed = false,
      providerUnavailable = true,
      invalidData = false,
      reasonDetail = null;

  /// Provider đọc được payload nhưng từ chối vì nội dung sai, hoặc canonical
  /// không qua được validation cục bộ.
  ///
  /// Tách riêng khỏi [authFailed]: gộp chung khiến lỗi dữ liệu hiện ra là
  /// `PROVIDER_NOT_CONNECTED`, chỉ sai hướng điều tra. Bằng chứng thực tế
  /// 2026-09-14: `Invalid_[Invoice.TaxRateInfo]` bị báo thành mất kết nối.
  const MeInvoicePreviewOutcome.invalidData({String? detail})
    : _viewerRef = null,
      authFailed = false,
      providerUnavailable = false,
      invalidData = true,
      reasonDetail = detail;

  final String? _viewerRef;
  final bool authFailed;
  final bool providerUnavailable;
  final bool invalidData;

  /// Mô tả ngắn phục vụ log; không dùng để hiển thị cho người dùng cuối.
  final String? reasonDetail;

  bool get isSuccess => !authFailed && !providerUnavailable && !invalidData;
  String? get viewerRef => _viewerRef;
}
