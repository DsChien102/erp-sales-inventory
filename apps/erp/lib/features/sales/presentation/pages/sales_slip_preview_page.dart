import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:vet45_design_system/design_system.dart';

import '../models/return_exchange_order/sales_return_exchange_detail_vm.dart';
import '../support/sales_pdf_runner.dart';
import '../support/sales_slip_pdf_generator.dart';

/// Màn hình xem trước phiếu đổi/trả dưới dạng PDF (authoritative detail bắt buộc).
class SalesSlipPreviewPage extends StatelessWidget {
  const SalesSlipPreviewPage({
    super.key,
    required this.detail,
    required this.orderNumber,
    required this.customerDisplayName,
    this.storeName,
    this.storeCode,
    this.customerPhoneNumber,
    this.existingCustomerDebtMinor,
  });

  final SalesReturnExchangeDetailVm detail;
  final String orderNumber;
  final String customerDisplayName;
  final String? storeName;
  final String? storeCode;
  final String? customerPhoneNumber;
  final int? existingCustomerDebtMinor;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final pdfFileName = SalesSlipPdfGenerator.sanitizeFileName(
      detail.referenceNumber,
    );

    return VPageScaffold(
      key: const Key('wgt_sg13_slip_preview_page'),
      title: 'Phiếu đổi/trả',
      showBackButton: true,
      actions: [
        IconButton(
          key: const Key('btn_preview_options'),
          icon: VIcon(
            icon: VIcons.moreVert,
            color: colors.textPrimary,
          ),
          onPressed: () async {
            showDialog(
              context: context,
              barrierDismissible: false,
              barrierColor: Colors.black12,
              builder: (dialogContext) => const PopScope(
                canPop: false,
                child: Center(
                  child: VLoading(),
                ),
              ),
            );

            try {
              final pdfBytes = await SalesSlipPdfGenerator.generateReturnExchange(
                detail: detail,
                orderNumber: orderNumber,
                customerDisplayName: customerDisplayName,
                storeName: storeName,
                storeCode: storeCode,
                customerPhoneNumber: customerPhoneNumber,
                existingCustomerDebtMinor: existingCustomerDebtMinor,
              );
              if (!context.mounted) return;
              await SalesPdfRunner.share(
                context: context,
                bytes: pdfBytes,
                filename: pdfFileName,
              );
            } catch (e) {
              if (context.mounted) {
                VToast.show(
                  context,
                  title: 'Xuất PDF thất bại',
                  message: 'Không thể sinh file PDF: $e',
                  type: VToastType.danger,
                );
              }
            } finally {
              if (context.mounted && Navigator.of(context, rootNavigator: true).canPop()) {
                Navigator.of(context, rootNavigator: true).pop();
              }
            }
          },
        ),
      ],
      body: PdfPreview(
        build: (format) => SalesSlipPdfGenerator.generateReturnExchange(
          detail: detail,
          orderNumber: orderNumber,
          customerDisplayName: customerDisplayName,
          storeName: storeName,
          storeCode: storeCode,
          customerPhoneNumber: customerPhoneNumber,
          existingCustomerDebtMinor: existingCustomerDebtMinor,
        ),
        pdfFileName: pdfFileName,
        useActions: false,
        scrollViewDecoration: BoxDecoration(
          color: colors.background,
        ),
        canChangeOrientation: false,
        canChangePageFormat: false,
        maxPageWidth: 700,
        loadingWidget: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const VLoading(),
              const VGap.sm(),
              VText(
                'Đang tạo bản xem trước PDF...',
                variant: VTextVariant.bodySmall,
                color: colors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
