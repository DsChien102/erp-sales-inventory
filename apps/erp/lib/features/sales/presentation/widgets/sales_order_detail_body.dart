import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/sales/logic/sales_order_detail_state.dart';
import '../models/sales_order_cancellation/sales_order_cancellation_vm.dart';
import '../models/sales_order/sales_order_detail_vm.dart';
import '../models/sales_order_settlement/sales_order_payment_vm.dart';
import 'sales_detail_header_card.dart';
import 'sales_order_detail_cancel_reason_card.dart';
import 'sales_order_detail_documents_section.dart';
import 'sales_order_detail_payment_summary_card.dart';
import 'sales_order_detail_products_section.dart';

class SalesOrderDetailBody extends StatelessWidget {
  const SalesOrderDetailBody({
    super.key,
    required this.vm,
    required this.payment,
    required this.paymentStatus,
    required this.historyStatus,
    required this.returnSlips,
    required this.onOpenPaymentDebt,
    required this.onOpenReturnList,
    required this.onOpenHistory,
    required this.onOpenReceipt,
    this.onOpenEInvoice,
    this.eInvoiceSection,
    required this.onRetryPayment,
    required this.onRetryHistory,
    required this.cancellation,
    required this.cancellationStatus,
    required this.onRetryCancellation,
    this.cancellationErrorMessage,
    this.paymentErrorMessage,
    this.historyErrorMessage,
    this.showHistory = true,
    this.selectedTabIndex = 0,
    this.onTabSelected,
  });

  final SalesOrderDetailVm vm;
  // 0 = "Đơn gốc" (snapshot lines), 1 = "Sau đổi/trả" (current holdings).
  final int selectedTabIndex;
  final ValueChanged<int>? onTabSelected;
  final SalesOrderPaymentVm? payment;
  final SalesOrderDetailSectionStatus paymentStatus;
  final SalesOrderDetailSectionStatus historyStatus;
  final List<SalesReturnExchangeSlipItemVm> returnSlips;
  final SalesOrderCancellationVm? cancellation;
  final SalesOrderDetailSectionStatus cancellationStatus;
  final String? cancellationErrorMessage;
  final VoidCallback onRetryCancellation;
  final String? paymentErrorMessage;
  final String? historyErrorMessage;
  final VoidCallback onOpenPaymentDebt;
  final VoidCallback onOpenReturnList;
  final VoidCallback onOpenHistory;
  final VoidCallback onOpenReceipt;
  final VoidCallback? onOpenEInvoice;
  final Widget? eInvoiceSection;
  final VoidCallback onRetryPayment;
  final VoidCallback onRetryHistory;
  final bool showHistory;

  @override
  Widget build(BuildContext context) {
    final isCancelled = vm.isCancelled;
    final showCurrentHoldings = selectedTabIndex == 1;
    final displayedItems = (showCurrentHoldings && vm.currentItems.isNotEmpty)
        ? vm.currentItems
        : vm.items;

    final currentHoldingsTotal = vm.currentItems.fold<int>(
      0,
      (sum, item) => sum + item.totalAmountMinor,
    );

    final int currentTotalMinor;
    if (showCurrentHoldings && (vm.currentItems.isNotEmpty || returnSlips.isNotEmpty)) {
      currentTotalMinor = currentHoldingsTotal > 0
          ? currentHoldingsTotal
          : (payment?.orderTotalMinor ?? vm.totalAmountMinor);
    } else {
      currentTotalMinor = payment?.originalOrderBreakdown?.orderTotalMinor ?? vm.totalAmountMinor;
    }

    final showDocumentsSection =
        !isCancelled || historyStatus != SalesOrderDetailSectionStatus.idle;

    final paymentVm = payment;
    final displayData = paymentVm == null
        ? null
        : SalesOrderDetailPaymentDisplayData.resolve(
            isCancelled: isCancelled,
            payment: paymentVm,
            showCurrentHoldings: showCurrentHoldings,
            currentHoldingsTotal: currentHoldingsTotal,
            hasReturnSlips: returnSlips.isNotEmpty,
            hasCurrentItems: vm.currentItems.isNotEmpty,
          );

    final showTabs = returnSlips.isNotEmpty && onTabSelected != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showTabs) ...[
          const VGap(VSpacing.space2),
          VPagePadding(
            child: VTabs(
              key: const Key('wgt_sg08_order_detail_tabs'),
              selectedIndex: selectedTabIndex,
              onTabSelected: onTabSelected!,
              semanticLabel: 'Phiên bản đơn hàng',
              child: const VTabsList(
                children: [
                  VTabsTrigger(label: 'Đơn gốc'),
                  VTabsTrigger(label: 'Sau đổi/trả'),
                ],
              ),
            ),
          ),
        ],
        Expanded(
          child: SingleChildScrollView(
            child: VPagePadding(
              key: const Key('wgt_sg08_order_detail_body'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const VGap(VSpacing.space4),
                  SalesDetailHeaderCard(
                    vm: vm,
                    totalAmountMinor: currentTotalMinor,
                    showTotal: true,
                  ),
                  const VGap(VSpacing.space2),
                  if (cancellationStatus != SalesOrderDetailSectionStatus.idle &&
                      (cancellationStatus != SalesOrderDetailSectionStatus.loaded ||
                          (cancellation?.reason.trim().isNotEmpty ?? false))) ...[
                    SalesOrderDetailCancelReasonCard(
                      cancellation: cancellation,
                      status: cancellationStatus,
                      errorMessage: cancellationErrorMessage,
                      onRetry: onRetryCancellation,
                    ),
                    const VGap(VSpacing.space2),
                  ],
                  SalesOrderDetailPaymentSummaryCard(
                    status: paymentStatus,
                    data: displayData,
                    errorMessage: paymentErrorMessage,
                    onTap: onOpenPaymentDebt,
                    onRetry: onRetryPayment,
                  ),
                  const VGap(VSpacing.space2),
                  SalesOrderDetailProductsSection(items: displayedItems),
                  const VGap.cozy(),
                  if (showDocumentsSection) ...[
                    SalesOrderDetailDocumentsSection(
                      isCancelled: isCancelled,
                      eInvoiceStatus: vm.eInvoiceStatus,
                      historyStatus: historyStatus,
                      returnSlips: returnSlips,
                      historyErrorMessage: historyErrorMessage,
                      onOpenReceipt: onOpenReceipt,
                      onOpenEInvoice: onOpenEInvoice,
                      eInvoiceSection: eInvoiceSection,
                      onOpenReturnList: onOpenReturnList,
                      onOpenHistory: onOpenHistory,
                      onRetryHistory: onRetryHistory,
                      showHistory: showHistory,
                    ),
                    const VGap.cozy(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
