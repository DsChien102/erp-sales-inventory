import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'package:erp/core/formatting/money_formatter.dart';

import 'package:erp/features/sales/logic/sales_transaction_result_cubit.dart';
import 'package:erp/features/sales/logic/sales_transaction_result_state.dart';
import 'package:erp/features/einvoice/logic/i_invoice_document_exporter.dart';
import 'package:erp/features/einvoice/logic/i_invoice_viewer_launcher.dart';
import 'package:erp/features/einvoice/presentation/widgets/order_einvoice_section.dart';
import '../navigation/sales_typed_routes.dart';
import '../support/order_einvoice_payable.dart';
import '../support/sales_pdf_runner.dart';
import '../support/sales_receipt_pdf_generator.dart';
import 'sales_einvoice_entry_card.dart';
import 'sales_receipt_entry_card.dart';
import 'sales_result_receipt_sheet.dart';

class SalesResultDocumentsSection extends StatelessWidget {
  const SalesResultDocumentsSection({
    super.key,
    required this.state,
    required this.cubit,
    this.eInvoiceMediator,
    this.executionContext,
    this.viewerLauncher,
    this.documentExporter,
  });

  final SalesTransactionResultState state;
  final SalesTransactionResultCubit cubit;
  final IModuleMediator? eInvoiceMediator;
  final IExecutionContext? executionContext;
  final IInvoiceViewerLauncher? viewerLauncher;
  final IInvoiceDocumentExporter? documentExporter;

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

    final order = state.order?.order;
    final salesOrderId = order?.salesOrderId ?? state.checkout?.salesOrderId;
    final orderVersion = order?.version ?? state.checkout?.salesOrderVersion;
    final orderCode = order?.orderNumber;
    final originalTotalMinor = order?.total.amountMinor;
    final totalMinor = originalTotalMinor == null && state.payment?.orderTotal == null
        ? null
        : OrderEInvoicePayable.minor(
            originalTotalMinor: originalTotalMinor ?? 0,
            currentPayableMinor: state.payment?.orderTotal.amountMinor,
          );

    final resolvedMediator =
        eInvoiceMediator ??
        (GetIt.instance.isRegistered<IEInvoiceModule>() ? GetIt.instance<IEInvoiceModule>() : null);
    final resolvedExecutionContext =
        executionContext ??
        (GetIt.instance.isRegistered<IExecutionContext>()
            ? GetIt.instance<IExecutionContext>()
            : null);

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

        // Card 2: Hóa đơn điện tử — live projection via OrderEInvoiceSection
        if (salesOrderId != null &&
            salesOrderId.isNotEmpty &&
            orderVersion != null &&
            orderCode != null &&
            orderCode.isNotEmpty &&
            resolvedMediator != null &&
            resolvedExecutionContext != null)
          OrderEInvoiceSection(
            key: const Key('sales_result_einvoice_section'),
            salesOrderId: salesOrderId,
            orderVersion: orderVersion,
            orderCode: orderCode,
            orderTotalFormatted: totalMinor == null ? null : MoneyFormatter.formatMinor(totalMinor),
            initialProjection: OrderInvoiceProjectionDto(
              salesOrderId: salesOrderId,
              issuanceDisplayState: IssuanceDisplayState.notIssued,
              actions: const [OrderInvoiceAction.issue],
            ),
            hasLoadedInitialProjection: false,
            mediator: resolvedMediator,
            executionContext: resolvedExecutionContext,
            viewerLauncher: viewerLauncher,
            documentExporter: documentExporter,
            buyerPartnerId: state.order?.customer?.customerId,
          )
        else
          const SalesEInvoiceEntryCard(
            badgeLabel: 'Chưa tải được',
            badgeTone: VComponentTone.warning,
            onTap: null,
          ),
      ],
    );
  }
}
