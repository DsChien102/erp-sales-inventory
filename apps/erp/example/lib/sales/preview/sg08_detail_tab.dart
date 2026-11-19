import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/sales/presentation.dart';

import 'fixtures.dart';
import 'preview_helpers.dart';
import 'preview_section.dart';

class SalesSg08DetailTab extends StatelessWidget {
  const SalesSg08DetailTab({super.key});

  @override
  Widget build(BuildContext context) {
    return previewList([
      PreviewSection(
        title: 'SalesOrderDetailErrorState',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PreviewStateRow(
              label: 'Blocked',
              child: SalesOrderDetailErrorState(
                kind: SalesOrderDetailErrorKind.blocked,
                onBack: () {},
              ),
            ),
            PreviewStateRow(
              label: 'Not found',
              child: SalesOrderDetailErrorState(
                kind: SalesOrderDetailErrorKind.notFound,
                onBack: () {},
              ),
            ),
            PreviewStateRow(
              label: 'Projection pending',
              child: SalesOrderDetailErrorState(
                kind: SalesOrderDetailErrorKind.projectionPending,
                onRetry: () {},
              ),
            ),
            PreviewStateRow(
              label: 'Error',
              child: SalesOrderDetailErrorState(
                kind: SalesOrderDetailErrorKind.error,
                message: 'network down',
                onRetry: () {},
              ),
            ),
          ],
        ),
      ),
      const PreviewSection(
        title: 'SalesDetailHeaderCard',
        child: SalesDetailHeaderCard(vm: SalesPreviewFixtures.orderDetail),
      ),
      PreviewSection(
        title: 'SalesDetailActionBar',
        child: Column(
          children: [
            PreviewStateRow(
              label: 'Committed',
              child: SalesDetailActionBar(
                vm: SalesPreviewFixtures.orderDetail,
                onOpenActions: () {},
              ),
            ),
            PreviewStateRow(
              label: 'Cancelled (hidden)',
              child: SalesDetailActionBar(
                vm: SalesPreviewFixtures.orderDetailCancelled,
                onOpenActions: () {},
              ),
            ),
          ],
        ),
      ),
      PreviewSection(
        title: 'Hub rows + grouped surface',
        child: Column(
          children: [
            PreviewStateRow(
              label: 'Receipt card',
              child: SalesReceiptEntryCard(onTap: () {}),
            ),
            PreviewStateRow(
              label: 'E-invoice card',
              child: SalesEInvoiceEntryCard(
                subtitle: 'Quản lý HĐĐT',
                badgeLabel: 'Chưa phát hành',
                onTap: () {},
              ),
            ),
            PreviewStateRow(
              label: 'Grouped',
              child: SalesOrderDetailGroupedSurface(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(VSpacing.space3),
                    child: VText('Dòng 1', variant: VTextVariant.bodyDefault),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(VSpacing.space3),
                    child: VText('Dòng 2', variant: VTextVariant.bodyDefault),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      PreviewSection(
        title: 'S17–S18 section states',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PreviewStateRow(
              label: 'Payment projection pending',
              child: SalesOrderDetailPaymentSummaryCard(
                status: SalesOrderDetailSectionStatus.projectionPending,
                onTap: () {},
                onRetry: () {},
              ),
            ),
            PreviewStateRow(
              label: 'Payment loaded partial',
              child: SalesOrderDetailPaymentSummaryCard(
                data: SalesOrderDetailPaymentDisplayData.resolve(
                  isCancelled: false,
                  payment: SalesPreviewFixtures.paymentLoaded,
                  showCurrentHoldings: false,
                  currentHoldingsTotal: 0,
                  hasReturnSlips: false,
                  hasCurrentItems: false,
                ),
                status: SalesOrderDetailSectionStatus.loaded,
                onTap: () {},
                onRetry: () {},
              ),
            ),
            PreviewStateRow(
              label: 'Payment disabled',
              child: SalesOrderDetailPaymentSummaryCard(
                data: SalesOrderDetailPaymentDisplayData.resolve(
                  isCancelled: true,
                  payment: SalesPreviewFixtures.paymentLoaded,
                  showCurrentHoldings: false,
                  currentHoldingsTotal: 0,
                  hasReturnSlips: false,
                  hasCurrentItems: false,
                ),
                status: SalesOrderDetailSectionStatus.loaded,
                onTap: () {},
                onRetry: () {},
              ),
            ),
            const PreviewStateRow(
              label: 'Payment debt D-02',
              child: PreviewEmbedFrame(
                child: SalesOrderPaymentDebtPage(
                  orderNumber: 'DH-000129',
                  customerName: 'Nguyễn Văn An',
                  payment: SalesPreviewFixtures.paymentLoaded,
                ),
              ),
            ),
            PreviewStateRow(
              label: 'History entry',
              child: SalesOrderDetailHistoryEntry(
                status: SalesOrderDetailSectionStatus.loaded,
                onTap: () {},
                onRetry: () {},
              ),
            ),
            PreviewStateRow(
              label: 'Returns loaded',
              child: SalesOrderDetailReturnsSection(
                slips: const [SalesPreviewFixtures.returnSlip],
                status: SalesOrderDetailSectionStatus.loaded,
                onTap: () {},
                onRetry: () {},
              ),
            ),
            const PreviewStateRow(
              label: 'Products',
              child: SalesOrderDetailProductsSection(
                items: [SalesPreviewFixtures.orderDetailItem],
              ),
            ),
            PreviewStateRow(
              label: 'Documents hub',
              child: SalesOrderDetailDocumentsSection(
                isCancelled: false,
                eInvoiceStatus: SalesEInvoiceStatus.notIssued,
                historyStatus: SalesOrderDetailSectionStatus.loaded,
                returnSlips: const [SalesPreviewFixtures.returnSlip],
                onOpenReceipt: () {},
                onOpenEInvoice: () {},
                onOpenReturnList: () {},
                onOpenHistory: () {},
                onRetryHistory: () {},
              ),
            ),
          ],
        ),
      ),
      PreviewSection(
        title: 'SalesOrderDetailBody',
        child: PreviewEmbedFrame(
          height: 520,
          child: SalesOrderDetailBody(
            vm: SalesPreviewFixtures.orderDetail,
            payment: SalesPreviewFixtures.paymentLoaded,
            paymentStatus: SalesOrderDetailSectionStatus.loaded,
            historyStatus: SalesOrderDetailSectionStatus.loaded,
            returnSlips: const [SalesPreviewFixtures.returnSlip],
            onOpenPaymentDebt: () {},
            onOpenReturnList: () {},
            onOpenHistory: () {},
            onOpenReceipt: () {},
            onOpenEInvoice: () {},
            onRetryPayment: () {},
            onRetryHistory: () {},
            cancellation: null,
            cancellationStatus: SalesOrderDetailSectionStatus.idle,
            onRetryCancellation: () {},
          ),
        ),
      ),
      PreviewSection(
        title: 'History / return list pages',
        child: Column(
          children: [
            PreviewStateRow(
              label: 'History page',
              child: PreviewEmbedFrame(
                height: 360,
                child: SalesOrderHistoryPage(
                  orderNumber: 'DH-000129',
                  customerName: 'Nguyễn Văn An',
                  history: SalesPreviewFixtures.history,
                ),
              ),
            ),
            PreviewStateRow(
              label: 'Return list page',
              child: PreviewEmbedFrame(
                height: 280,
                child: SalesOrderReturnListPage(
                  orderId: 'so-1',
                  orderNumber: 'DH-000129',
                  customerName: 'Nguyễn Văn An',
                  returns: const [SalesPreviewFixtures.returnSlip],
                  onOpenReturnDetail: (_) {},
                ),
              ),
            ),
          ],
        ),
      ),
      PreviewSection(
        title: 'Sheets',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PreviewActionButton(
              label: 'Order actions',
              onPressed: () => showSalesOrderActionsSheet(
                context,
                canReturnExchange: true,
                canCancel: true,
              ),
            ),
            PreviewActionButton(
              label: 'Return slip actions',
              onPressed: () => showSalesReturnExchangeSlipSheet(context),
            ),
          ],
        ),
      ),
    ]);
  }
}
