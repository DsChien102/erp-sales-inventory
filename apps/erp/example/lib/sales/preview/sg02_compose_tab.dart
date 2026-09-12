import 'package:flutter/material.dart';
import 'package:erp/features/sales/presentation.dart';

import 'fixtures.dart';
import 'preview_helpers.dart';
import 'preview_section.dart';

class SalesSg02ComposeTab extends StatelessWidget {
  const SalesSg02ComposeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return previewList([
      PreviewSection(
        title: 'SalesComposeCustomerCard',
        child: Column(
          children: [
            PreviewStateRow(
              label: 'Walk-in',
              child: SalesComposeCustomerCard(
                customer: SalesPreviewFixtures.walkInCustomer,
                onSelectCustomer: () {},
                onCreateCustomer: () {},
              ),
            ),
            PreviewStateRow(
              label: 'Named',
              child: SalesComposeCustomerCard(
                customer: SalesPreviewFixtures.namedCustomer,
                onSelectCustomer: () {},
                onCreateCustomer: () {},
              ),
            ),
          ],
        ),
      ),
      PreviewSection(
        title: 'SalesComposeProductSearchBar',
        child: SalesComposeProductSearchBar(
          onSelectProduct: (_) {},
          onScanTap: () {},
          searchProducts: (query, {int limit = 20}) async =>
              SalesPreviewFixtures.products,
          resolveBarcode: (_) async => SalesPreviewFixtures.products,
        ),
      ),
      PreviewSection(
        title: 'SalesOrderLineRow + quantity',
        child: Column(
          children: [
            PreviewStateRow(
              label: 'Enabled',
              child: SalesOrderLineRow(
                productName: 'Vaccine A',
                unitPriceLabel: '1.250.000đ/Lọ',
                quantity: 2,
                onQuantityChanged: (_) {},
                onDiscount: () {},
                onDelete: () {},
              ),
            ),
            PreviewStateRow(
              label: 'Low stock warning',
              child: SalesOrderLineRow(
                productName: 'Khoáng chất B',
                unitPriceLabel: '75.000đ/Hộp',
                quantity: 1,
                warningText: 'Chỉ còn 2 Hộp',
                maxQuantity: 2,
                onQuantityChanged: (_) {},
              ),
            ),
            PreviewStateRow(
              label: 'Quantity controls',
              child: SalesOrderLineQuantityControls(
                quantity: 2,
                enabled: true,
                onDecrement: () {},
                onIncrement: () {},
              ),
            ),
          ],
        ),
      ),
      PreviewSection(
        title: 'SalesComposeLinesSection',
        description: 'Empty vs filled grouped surface.',
        child: Column(
          children: [
            PreviewStateRow(
              label: 'Empty',
              child: PreviewEmbedFrame(
                height: 200,
                child: Column(
                  children: [
                    Expanded(
                      child: SalesComposeLinesSection(
                        lines: const [],
                        totals: SalesComposeTotals.empty,
                        onQuantityChanged: (id, qty) => null,
                        onDiscount: (_) {},
                        onDelete: (_) {},
                      ),
                    ),
                  ],
                ),
              ),
            ),
            PreviewStateRow(
              label: 'Filled',
              child: PreviewEmbedFrame(
                height: 280,
                child: Column(
                  children: [
                    Expanded(
                      child: SalesComposeLinesSection(
                        lines: SalesPreviewFixtures.composeLines,
                        totals: SalesComposeTotals.fromLines(
                          SalesPreviewFixtures.composeLines,
                        ),
                        onQuantityChanged: (id, qty) => null,
                        onDiscount: (_) {},
                        onDelete: (_) {},
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      PreviewSection(
        title: 'SalesComposeOrderNoteTile',
        child: Column(
          children: [
            PreviewStateRow(
              label: 'Empty',
              child: SalesComposeOrderNoteTile(note: null, onChanged: (_) {}),
            ),
            PreviewStateRow(
              label: 'Filled',
              child: SalesComposeOrderNoteTile(
                note: 'Giao trước 16:00 — gọi trước khi đến.',
                onChanged: (_) {},
              ),
            ),
          ],
        ),
      ),
      PreviewSection(
        title: 'SalesComposeSummaryBar',
        child: Column(
          children: [
            PreviewStateRow(
              label: 'Ready',
              child: SalesComposeSummaryBar(
                subtotalMinor: 1325000,
                canCheckout: true,
                canSaveDraft: true,
                onCheckout: () {},
                onSaveDraft: () {},
              ),
            ),
            PreviewStateRow(
              label: 'Disabled + refreshing (skeleton total)',
              child: SalesComposeSummaryBar(
                subtotalMinor: 0,
                canCheckout: false,
                canSaveDraft: false,
                disabledReason: 'Thêm sản phẩm để thanh toán',
                pricingStatus: SalesComposePricingStatus.refreshing,
                onCheckout: () {},
                onSaveDraft: () {},
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
              label: 'Leave sheet',
              onPressed: () => showSalesComposeLeaveSheet(context),
            ),
            PreviewActionButton(
              label: 'Price adjust',
              onPressed: () => SalesComposePriceAdjustSheet.show(
                context,
                line: SalesPreviewFixtures.composeLine,
                canSavePrivatePrice: true,
              ),
            ),
          ],
        ),
      ),
    ]);
  }
}
