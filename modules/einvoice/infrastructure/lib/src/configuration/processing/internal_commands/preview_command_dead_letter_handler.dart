import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';

import 'i_einvoice_internal_command_client.dart';
import 'i_einvoice_internal_command_dead_letter_handler.dart';

/// Hết lượt thử lại mà MISA vẫn không trả lời: ghi FAILED để màn hình thôi
/// chờ. Dòng đã có yêu cầu mới hơn hoặc đã có kết quả thì hàm ghi tự bỏ qua.
final class PreviewCommandDeadLetterHandler
    implements IEinvoiceInternalCommandDeadLetterHandler {
  PreviewCommandDeadLetterHandler({
    required IInvoicePreviewGateway previewGateway,
  }) : _previewGateway = previewGateway;

  final IInvoicePreviewGateway _previewGateway;

  @override
  Future<void> handleDeadLetter({
    required String tenantId,
    required ClaimedInternalCommand command,
    required Object error,
  }) async {
    final salesOrderId = command.payload['sales_order_id']?.toString();
    final requestId = command.payload['preview_request_id']?.toString();
    if (salesOrderId == null ||
        salesOrderId.isEmpty ||
        requestId == null ||
        requestId.isEmpty) {
      return;
    }

    await _previewGateway.storeResult(
      tenantId: tenantId,
      salesOrderId: salesOrderId,
      requestId: requestId,
      status: 'FAILED',
      failureCode: 'PROVIDER_UNAVAILABLE',
      failureMessage: error.toString(),
      failureSource: FailureSource.internal,
    );
  }
}
