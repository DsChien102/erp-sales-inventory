import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_invoice_preview_gateway.dart';
import '../../../ports/i_me_invoice_provider_port.dart';
import 'preview_invoice_command.dart';

@CommandHandlerFor(PreviewInvoiceCommand)
final class PreviewInvoiceCommandHandler implements ICommandHandler<PreviewInvoiceCommand, void> {
  PreviewInvoiceCommandHandler({
    required IMeInvoiceProviderPort providerPort,
    required IInvoicePreviewGateway previewGateway,
  }) : _providerPort = providerPort,
       _previewGateway = previewGateway;

  final IMeInvoiceProviderPort _providerPort;
  final IInvoicePreviewGateway _previewGateway;

  @override
  Future<void> handle(PreviewInvoiceCommand command) async {
    final canonical = Map<String, Object?>.from(command.canonicalInvoice);
    // MISA unpublishview requires RefID; reuse the preview request id.
    canonical.putIfAbsent('refId', () => command.previewRequestId);

    // Xem trước không tạo gì ở MISA nên gọi lại an toàn: lỗi mạng/timeout ném
    // ra ngoài, dòng giữ PENDING cho hàng đợi thử lại; hết lượt thì
    // PreviewCommandDeadLetterHandler ghi FAILED.
    final outcome = await _providerPort.previewUnpublished(
      tenantId: command.tenantId,
      canonicalInvoice: canonical,
    );

    final viewerRef = outcome.viewerRef;
    if (viewerRef != null) {
      await _previewGateway.storeResult(
        tenantId: command.tenantId,
        salesOrderId: command.salesOrderId,
        requestId: command.previewRequestId,
        status: 'READY',
        viewerRef: viewerRef,
      );
      return;
    }

    if (outcome.providerUnavailable) {
      throw StateError('PROVIDER_UNAVAILABLE');
    }

    // Kết quả chắc chắn: thử lại cũng vậy → ghi FAILED, không ném lỗi.
    // Dữ liệu sai và sai tài khoản giữ hai mã riêng — xem ADR trên
    // MeInvoicePreviewOutcome.invalidData.
    await _previewGateway.storeResult(
      tenantId: command.tenantId,
      salesOrderId: command.salesOrderId,
      requestId: command.previewRequestId,
      status: 'FAILED',
      failureCode: outcome.invalidData
          ? 'PROVIDER_REJECTED_INVOICE_DATA'
          : 'PROVIDER_AUTH_FAILED',
      failureMessage: outcome.reasonDetail,
      failureSource: FailureSource.provider,
    );
  }
}
