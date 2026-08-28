import '../../issuance/commands/request_invoice_preview/request_invoice_preview_result.dart';
import '../../ports/i_invoice_preview_gateway.dart';

final class FakeInvoicePreviewGateway implements IInvoicePreviewGateway {
  FakeInvoicePreviewGateway({required this.requestId, this.cached});

  final String requestId;
  final InvoicePreviewResultDto? cached;
  String? enqueuedFor;
  String? storedRequestId;

  @override
  Future<String> persistRequestAndEnqueue({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
    required int expectedOrderVersion,
  }) async {
    enqueuedFor = salesOrderId;
    return requestId;
  }

  @override
  Future<InvoicePreviewResultDto?> readCached({
    required String tenantId,
    required String salesOrderId,
  }) async => cached;

  @override
  Future<void> storeResult({
    required String tenantId,
    required String previewRequestId,
    String? viewerRef,
    Map<String, Object?>? previewPayload,
  }) async {
    storedRequestId = previewRequestId;
  }
}
