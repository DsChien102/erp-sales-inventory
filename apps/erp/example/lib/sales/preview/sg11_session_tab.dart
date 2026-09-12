import 'package:flutter/material.dart';
import 'package:erp/features/sales/presentation.dart';

import 'fixtures.dart';
import 'preview_helpers.dart';
import 'preview_section.dart';
import 'sales_return_exchange_session_preview_section.dart';

class SalesSg11SessionTab extends StatelessWidget {
  const SalesSg11SessionTab({super.key});

  @override
  Widget build(BuildContext context) {
    return previewList([
      const SalesReturnExchangeSessionPreviewSection(),
      PreviewSection(
        title: 'Sheets',
        description:
            'Line rows không barrel-export — preview qua session body filled.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PreviewActionButton(
              label: 'Exchange product picker',
              onPressed: () => showSalesExchangeProductPickerSheet(
                context,
                searchProducts: (_) async {
                  final product = SalesPreviewFixtures.product;
                  return [
                    SalesProductSelection.fromProductUnit(
                      product: product,
                      unit: product.defaultUnit!,
                    ),
                  ];
                },
              ),
            ),
            PreviewActionButton(
              label: 'Discard session dialog',
              onPressed: () => showSalesReturnDiscardDialog(context),
            ),
          ],
        ),
      ),
    ]);
  }
}
