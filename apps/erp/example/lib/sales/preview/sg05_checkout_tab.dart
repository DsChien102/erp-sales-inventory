import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/sales/presentation.dart';

import 'fixtures.dart';
import 'preview_helpers.dart';
import 'preview_section.dart';

class SalesSg05CheckoutTab extends StatelessWidget {
  const SalesSg05CheckoutTab({super.key});

  @override
  Widget build(BuildContext context) {
    return previewList([
      PreviewSection(
        title: 'SalesCheckoutSummaryCard',
        child: Column(
          children: [
            const PreviewStateRow(
              label: 'Named + nợ cũ',
              child: SalesCheckoutSummaryCard(
                vm: SalesPreviewFixtures.checkoutNamed,
              ),
            ),
            const PreviewStateRow(
              label: 'Walk-in (ẩn nợ cũ)',
              child: SalesCheckoutSummaryCard(
                vm: SalesPreviewFixtures.checkoutWalkIn,
              ),
            ),
          ],
        ),
      ),
      const PreviewSection(
        title: 'SalesAmountHighlightRow',
        description: 'Hàng tiền nổi bật dùng chung cho SG-05 / SG-06.',
        child: Column(
          children: [
            PreviewStateRow(
              label: 'Primary (công nợ phát sinh)',
              child: SalesAmountHighlightRow(
                label: 'Công nợ phát sinh',
                amountMinor: 350000,
              ),
            ),
            PreviewStateRow(
              label: 'Success + heading mono (tổng đơn)',
              child: SalesAmountHighlightRow(
                label: 'Tổng đơn',
                amountMinor: 1250000,
                tone: VComponentTone.success,
                amountVariant: VTextVariant.headingH4Mono,
                emphasizeLabel: false,
              ),
            ),
          ],
        ),
      ),
      PreviewSection(
        title: 'SalesCheckoutPaymentMethodSelector',
        child: SalesCheckoutPaymentMethodSelector(
          selectedMode: SalesPaymentMode.cash,
          onModeSelected: (_) {},
        ),
      ),
      PreviewSection(
        title: 'SalesCheckoutReceivableCard',
        child: Column(
          children: [
            PreviewStateRow(
              label: 'Enabled remainder',
              child: SalesCheckoutReceivableCard(
                vm: SalesPreviewFixtures.checkoutNamed,
                onDueDateSelected: (_) {},
              ),
            ),
            PreviewStateRow(
              label: 'Disabled',
              child: SalesCheckoutReceivableCard(
                vm: SalesPreviewFixtures.checkoutNamed,
                enabled: false,
                onDueDateSelected: (_) {},
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
              label: 'Finalize checkout',
              onPressed: () => showSalesCheckoutFinalizeSheet(context),
            ),
          ],
        ),
      ),
    ]);
  }
}
