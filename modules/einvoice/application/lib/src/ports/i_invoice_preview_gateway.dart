import '../issuance/commands/request_invoice_preview/request_invoice_preview_result.dart';

/// Persists a preview request (which enqueues the einvoice.preview_invoice job)
/// and reads back the cached preview result. Creates NO issuance state (DR-02).
abstract interface class IInvoicePreviewGateway {
  Future<String> persistRequestAndEnqueue({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
    required int expectedOrderVersion,
  });

  Future<InvoicePreviewResultDto?> readCached({
    required String tenantId,
    required String salesOrderId,
  });

  Future<void> storeResult({
    required String tenantId,
    required String previewRequestId,
    String? viewerRef,
    Map<String, Object?>? previewPayload,
  });
}
