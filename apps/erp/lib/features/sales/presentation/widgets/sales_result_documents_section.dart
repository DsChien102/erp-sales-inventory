import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_sales_application/application.dart';

import '../bloc/sales_order/sales_transaction_result_cubit.dart';
import '../bloc/sales_order/sales_transaction_result_state.dart';
import '../navigation/sales_typed_routes.dart';
import '../support/sales_pdf_runner.dart';
import '../support/sales_receipt_pdf_generator.dart';
import 'sales_einvoice_entry_card.dart';
import 'sales_receipt_entry_card.dart';
import 'sales_result_einvoice_sheet.dart';
import 'sales_result_receipt_sheet.dart';

class SalesResultDocumentsSection extends StatelessWidget {
  const SalesResultDocumentsSection({
    super.key,
    required this.state,
    required this.cubit,
  });

  final SalesTransactionResultState state;
  final SalesTransactionResultCubit cubit;

  @override
  Widget build(BuildContext context) {
    final receiptStatus = state.receipt.status;
    final receiptBusy =
        receiptStatus == SalesReceiptOperationStatus.generating ||
        receiptStatus == SalesReceiptOperationStatus.printing ||
        receiptStatus == SalesReceiptOperationStatus.sharing;
    final String receiptTitle = receiptStatus == SalesReceiptOperationStatus.error
        ? 'Tạo lại phiếu bán hàng'
        : 'Phiếu bán hàng';
    final String receiptSubtitle = switch (receiptStatus) {
      SalesReceiptOperationStatus.idle => 'Xem, in hoặc gửi phiếu cho khách',
      SalesReceiptOperationStatus.generating => 'Đang tạo phiếu bán hàng',
      SalesReceiptOperationStatus.ready => 'Xem, in hoặc gửi phiếu cho khách',
      SalesReceiptOperationStatus.printing => 'Đang in phiếu bán hàng',
      SalesReceiptOperationStatus.sharing => 'Đang chia sẻ phiếu bán hàng',
      SalesReceiptOperationStatus.activityWarning =>
        'Đã xử lý trên thiết bị, cần đồng bộ hoạt động',
      SalesReceiptOperationStatus.error => 'Không thể tạo phiếu, hãy thử lại',
    };
    // US-06 delivery tracking is deferred, so the e-invoice card stays cosmetic
    // on `notRequired` until an e-invoice integration owner exists.
    const eInvoiceStatus = IntegrationDeliveryStatus.notRequired;
    final (eInvoiceLabel, eInvoiceTone) = _eInvoiceBadge(eInvoiceStatus);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const VText(
          'Chứng từ & hóa đơn',
          variant: VTextVariant.bodyDefault,
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const VGap.sm(),

        // Card 1: Phiếu bán hàng
        SalesReceiptEntryCard(
          title: receiptTitle,
          subtitle: receiptSubtitle,
          onTap: receiptBusy
              ? null
              : () async {
                  final action = await showSalesResultReceiptSheet(context);
                  if (!context.mounted || action == null) return;
                  final receipt = state.receipt.value;
                  final orderId = state.order?.order.salesOrderId ?? state.checkout?.salesOrderId;

                  try {
                    if (action == SalesResultReceiptAction.view &&
                        receipt != null &&
                        orderId != null) {
                      SalesOrderPreviewRoute(
                        orderId: orderId,
                        $extra: receipt,
                      ).push(context);
                      return;
                    }
                    if (action == SalesResultReceiptAction.print) {
                      await cubit.printReceipt((document) async {
                        final pdfBytes = await SalesReceiptPdfGenerator.generate(document);
                        if (!context.mounted) return;
                        await SalesPdfRunner.print(
                          context: context,
                          bytes: pdfBytes,
                          name: SalesReceiptPdfGenerator.sanitizeFileName(document.receiptNumber),
                        );
                      });
                      return;
                    }
                    if (action == SalesResultReceiptAction.share) {
                      await cubit.shareReceipt((document) async {
                        final pdfBytes = await SalesReceiptPdfGenerator.generate(document);
                        if (!context.mounted) return;
                        await SalesPdfRunner.share(
                          context: context,
                          bytes: pdfBytes,
                          filename: SalesReceiptPdfGenerator.sanitizeFileName(
                            document.receiptNumber,
                          ),
                        );
                      });
                      return;
                    }
                    await cubit.ensureReceipt();
                  } catch (e) {
                    if (context.mounted) {
                      VToast.show(
                        context,
                        title: 'Thao tác PDF thất bại',
                        message: '$e',
                        type: VToastType.danger,
                      );
                    }
                  }
                },
        ),
        const VGap.sm(),

        // Card 2: Hóa đơn điện tử (read-only integration status)
        SalesEInvoiceEntryCard(
          badgeLabel: eInvoiceLabel,
          badgeTone: eInvoiceTone,
          onTap: () async {
            await showSalesResultEInvoiceSheet(
              context,
              status: eInvoiceStatus,
            );
          },
        ),
      ],
    );
  }

  static (String label, VComponentTone tone) _eInvoiceBadge(
    IntegrationDeliveryStatus status,
  ) => switch (status) {
    IntegrationDeliveryStatus.notRequired => ('Chưa phát hành', VComponentTone.neutral),
    IntegrationDeliveryStatus.queued => ('Đang xử lý', VComponentTone.primary),
    IntegrationDeliveryStatus.delivered => ('Đã phát hành', VComponentTone.success),
    IntegrationDeliveryStatus.retryScheduled => ('Sẽ thử lại', VComponentTone.primary),
    IntegrationDeliveryStatus.failed ||
    IntegrationDeliveryStatus.deadLetter => ('Lỗi', VComponentTone.danger),
    IntegrationDeliveryStatus.unknown => ('Không rõ', VComponentTone.neutral),
  };
}
