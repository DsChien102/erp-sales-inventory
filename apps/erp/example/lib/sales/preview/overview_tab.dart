import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import 'preview_helpers.dart';
import 'preview_section.dart';

/// Intro + coverage checklist grouped by canonical Theme-5 screen groups.
class SalesOverviewTab extends StatelessWidget {
  const SalesOverviewTab({super.key});

  static const coveredByGroup = <String, List<String>>{
    'SG-01 Bán hàng & đơn nháp': [
      'SalesDraftListBody',
      'SalesDraftListCard',
      'SalesDraftListCardSkeleton',
      'SalesDraftListSearchBar',
      'SalesDraftListEmptyState',
      'SalesDraftListErrorState',
      'SalesDraftListNoResultState',
      'showSalesDraftDiscardDialog',
    ],
    'SG-02 Soạn đơn bán hàng': [
      'SalesComposeCustomerCard',
      'SalesComposeLinesSection',
      'SalesComposeOrderNoteTile',
      'SalesComposeProductSearchBar',
      'SalesComposeSummaryBar',
      'SalesOrderLineRow',
      'SalesOrderLineQuantityControls',
      'showSalesComposeLeaveSheet',
      'SalesComposePriceAdjustSheet',
    ],
    'SG-03 Chọn sản phẩm': [
      'SalesProductPickerBody',
      'SalesProductPickerCard',
      'SalesProductPickerSearchBar',
      'SalesProductUnitSheet',
    ],
    'SG-04 Chọn khách hàng': [
      'SalesCustomerPickerBody',
      'SalesCustomerPickerBodyEmptyState',
      'SalesCustomerPickerBodyNoResultState',
      'SalesCustomerPickerBodyErrorState',
      'SalesCustomerPickerCard',
      'SalesCustomerPickerSearchBar',
      'showSalesCustomerSelectSheet',
      'SalesCustomerQuickCreateSheet',
    ],
    'SG-05 Thanh toán & hoàn tất': [
      'SalesCheckoutSummaryCard',
      'SalesCheckoutPaymentMethodSelector',
      'SalesCheckoutReceivableCard',
      'SalesPaymentQrCard',
      'SalesAmountHighlightRow',
      'showSalesCheckoutFinalizeSheet',
    ],
    'SG-06 Kết quả bán hàng': [
      'SalesResultLoadingView',
      'SalesResultFailureView',
      'SalesResultPartialBanner',
      'SalesResultHeaderCard',
      'SalesResultCustomerCard',
      'SalesResultPaymentSummaryCard',
      'SalesReceiptEntryCard',
      'SalesEInvoiceEntryCard',
      'SalesTransactionResultActionBar',
      'showSalesResultReceiptSheet',
      'OrderEInvoiceSection (host: SalesResultDocumentsSection)',
      'PostIssueEInvoiceActionSheet',
      'InvoiceDocumentsActionSheet',
      'OrderInvoiceSendSheet',
      'OrderInvoiceResendSheet',
      'InvoiceDeliveryHistoryView',
      'InvoiceDeliveryHistoryPage',
    ],
    'SG-07 Danh sách đơn hàng': [
      'SalesOrderListBody',
      'SalesOrderListCard',
      'SalesOrderListSearchBar',
      'SalesOrderSavedSearchChips',
      'SalesOrderListEmptyState',
      'SalesOrderListErrorState',
      'SalesOrderListNoResultState',
      'SalesOrderListBlockedState',
      'SalesOrderFilterBottomSheet',
    ],
    'SG-08 Chi tiết & lịch sử': [
      'SalesOrderDetailErrorState',
      'SalesDetailHeaderCard',
      'SalesDetailActionBar',
      'SalesOrderDetailBody',
      'SalesOrderDetailProductsSection',
      'SalesOrderDetailPaymentSummaryCard',
      'SalesOrderPaymentDebtPage',
      'SalesOrderDetailHistoryEntry',
      'SalesOrderDetailReturnsSection',
      'SalesOrderDetailDocumentsSection',
      'SalesReceiptEntryCard',
      'SalesEInvoiceEntryCard',
      'SalesOrderDetailGroupedSurface',
      'SalesOrderHistoryPage',
      'SalesOrderReturnListPage',
      'showSalesOrderActionsSheet',
      'showSalesReturnExchangeSlipSheet',
    ],
    'SG-10 Hủy đơn hàng': [
      'SalesOrderCancelSheet',
      'showSalesOrderCancelSheet',
      'SalesOrderDetailCancelReasonCard',
    ],
    'SG-11 Lập phiếu đổi/trả': [
      'SalesReturnExchangeSessionBody',
      'showSalesExchangeProductPickerSheet',
      'showSalesReturnDiscardDialog',
    ],
    'SG-12 Quyết toán chênh lệch': [
      'SalesReturnExchangeSettlementBody',
      'showSalesReturnConfirmSettlementSheet',
    ],
    'SG-13 Kết quả & chi tiết đổi/trả': [
      'SalesReturnExchangeResultBody',
      'SalesReturnExchangeDetailBody',
      'SalesReturnExchangeDetailHeaderCard',
      'SalesReturnExchangeSourceOrderCard',
      'SalesReturnExchangeDetailLinesSection',
      'SalesReturnExchangeDetailSummaryCard',
      'SalesReturnResultActionBar',
    ],
  };

  static const erpOnly = <String>[
    'ERP thin pages SG-01..SG-13 (apps/erp/lib/features/sales)',
  ];

  static const cubitHosted = <String>[
    'SalesTransactionResultBody — preview qua leaf SG-06 (cần Cubit)',
    'SalesResultDocumentsSection — preview qua sheet SG-06 (cần Cubit)',
    'SalesReceiptPreviewPage / SalesSlipPreviewPage — PDF host',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final coveredCount = coveredByGroup.values.fold<int>(
      0,
      (sum, items) => sum + items.length,
    );
    return previewList([
      PreviewSection(
        title: 'Sales presentation example',
        description:
            'Catalog theo Theme-5 §5.5 screen groups. Fake-only — không ERP '
            'shell, không live Supabase, không env:doctor. DS example = '
            'primitives; tab SG = BC widgets.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Package: package:erp/features/sales/presentation.dart',
              style: VTypography.bodyDefault,
            ),
            const SizedBox(height: VSpacing.space1),
            Text(
              'Coverage: $coveredCount public widgets / show* helpers',
              style: VTypography.bodySmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      for (final entry in coveredByGroup.entries)
        PreviewSection(
          title: entry.key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final name in entry.value) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_box, size: 18, color: colors.success),
                    const SizedBox(width: VSpacing.space2),
                    Expanded(child: Text(name, style: VTypography.bodySmall)),
                  ],
                ),
                const SizedBox(height: VSpacing.space2),
              ],
            ],
          ),
        ),
      PreviewSection(
        title: 'ERP-only (không import apps/erp)',
        description:
            'Phase 1 EP-04 form chỉnh ghi chú sống ở ERP page. Catalog chỉ '
            'preview tile/sheet dùng chung từ module.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final name in erpOnly) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_box_outline_blank,
                    size: 18,
                    color: colors.textSecondary,
                  ),
                  const SizedBox(width: VSpacing.space2),
                  Expanded(child: Text(name, style: VTypography.bodySmall)),
                ],
              ),
              const SizedBox(height: VSpacing.space2),
            ],
          ],
        ),
      ),
      PreviewSection(
        title: 'Cubit / PDF hosts',
        description:
            'Không invent constructor loading/empty. Preview qua sibling '
            'state widgets hoặc sheet public.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final name in cubitHosted) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: colors.textSecondary,
                  ),
                  const SizedBox(width: VSpacing.space2),
                  Expanded(child: Text(name, style: VTypography.bodySmall)),
                ],
              ),
              const SizedBox(height: VSpacing.space2),
            ],
          ],
        ),
      ),
    ]);
  }
}
