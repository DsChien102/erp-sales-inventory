import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_sales_application/application.dart'
    hide SalesSettlementStatus, SalesOrderLifecycleStatus;
import 'package:erp/features/sales/presentation.dart';

import 'preview_helpers.dart';
import 'preview_section.dart';

class SalesSg06ResultTab extends StatelessWidget {
  const SalesSg06ResultTab({super.key});

  static const _loadedState = SalesTransactionResultState(
    status: SalesTransactionResultStatus.loaded,
  );

  @override
  Widget build(BuildContext context) {
    return previewList([
      const PreviewSection(
        title: 'SalesResultLoadingView',
        child: SizedBox(height: 120, child: SalesResultLoadingView()),
      ),
      PreviewSection(
        title: 'SalesResultFailureView',
        child: SalesResultFailureView(
          message: 'Đơn đã được tạo. Thử tải lại và không thanh toán lại.',
          onRetry: () {},
        ),
      ),
      PreviewSection(
        title: 'SalesReceiptEntryCard / SalesEInvoiceEntryCard',
        description: 'Hàng chứng từ dùng chung cho hub SG-06 và SG-08.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PreviewStateRow(
              label: 'Phiếu — idle',
              child: SalesReceiptEntryCard(onTap: () {}),
            ),
            const PreviewStateRow(
              label: 'Phiếu — đang tạo (khóa tap)',
              child: SalesReceiptEntryCard(
                subtitle: 'Đang tạo phiếu bán hàng',
                onTap: null,
              ),
            ),
            PreviewStateRow(
              label: 'Phiếu — lỗi',
              child: SalesReceiptEntryCard(
                title: 'Tạo lại phiếu bán hàng',
                subtitle: 'Không thể tạo phiếu, hãy thử lại',
                onTap: () {},
              ),
            ),
            PreviewStateRow(
              label: 'HĐĐT — chưa phát hành',
              child: SalesEInvoiceEntryCard(
                badgeLabel: 'Chưa phát hành',
                onTap: () {},
              ),
            ),
            PreviewStateRow(
              label: 'HĐĐT — đang xử lý',
              child: SalesEInvoiceEntryCard(
                badgeLabel: 'Đang xử lý',
                badgeTone: VComponentTone.primary,
                onTap: () {},
              ),
            ),
            PreviewStateRow(
              label: 'HĐĐT — đã phát hành',
              child: SalesEInvoiceEntryCard(
                badgeLabel: 'Đã phát hành',
                badgeTone: VComponentTone.success,
                onTap: () {},
              ),
            ),
            PreviewStateRow(
              label: 'HĐĐT — lỗi',
              child: SalesEInvoiceEntryCard(
                badgeLabel: 'Lỗi',
                badgeTone: VComponentTone.danger,
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
      const PreviewSection(
        title: 'SalesResultPartialBanner',
        child: SalesResultPartialBanner(
          issues: [SalesTransactionResultIssue.projectionPending],
        ),
      ),
      PreviewSection(
        title: 'SalesResultHeaderCard / CustomerCard / PaymentSummary',
        description:
            'Leaf widgets nhận SalesTransactionResultState. Body đầy đủ '
            'cần Cubit — không preview ở catalog.',
        child: Column(
          children: [
            PreviewStateRow(
              label: 'Header',
              child: SalesResultHeaderCard(
                state: _loadedState,
                onViewOrderDetail: () {},
              ),
            ),
            const PreviewStateRow(
              label: 'Customer',
              child: SalesResultCustomerCard(state: _loadedState),
            ),
            const PreviewStateRow(
              label: 'Payment summary',
              child: SalesResultPaymentSummaryCard(state: _loadedState),
            ),
          ],
        ),
      ),
      PreviewSection(
        title: 'SalesTransactionResultActionBar',
        child: Column(
          children: [
            PreviewStateRow(
              label: 'Success',
              child: SalesTransactionResultActionBar(
                onGoHome: () {},
                onCreateNewOrder: () {},
              ),
            ),
            PreviewStateRow(
              label: 'Error',
              child: SalesTransactionResultActionBar(
                isErrorState: true,
                onGoHome: () {},
                onCreateNewOrder: () {},
                onRetryLoad: () {},
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
              label: 'Receipt actions',
              onPressed: () => showSalesResultReceiptSheet(context),
            ),
            PreviewActionButton(
              label: 'E-invoice (queued)',
              onPressed: () => showSalesResultEInvoiceSheet(
                context,
                status: IntegrationDeliveryStatus.queued,
              ),
            ),
          ],
        ),
      ),
    ]);
  }
}
