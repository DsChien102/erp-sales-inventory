import 'package:vet45_einvoice_domain/domain.dart';

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
    required String actorId,
    required String salesOrderId,
  });

  /// Worker ghi kết quả của đúng yêu cầu [requestId]; bỏ qua (không lỗi) khi
  /// đơn đã có yêu cầu mới hơn hoặc yêu cầu này đã có kết quả.
  Future<void> storeResult({
    required String tenantId,
    required String salesOrderId,
    required String requestId,
    required String status,
    String? viewerRef,
    String? failureCode,
    String? failureMessage,
    FailureSource? failureSource,
  });
}
