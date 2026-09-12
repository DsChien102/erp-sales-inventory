import 'package:flutter/material.dart';
import 'package:erp/features/sales/presentation.dart';

import 'fixtures.dart';
import 'preview_helpers.dart';
import 'preview_section.dart';

class SalesSg03ProductPickerTab extends StatelessWidget {
  const SalesSg03ProductPickerTab({super.key});

  @override
  Widget build(BuildContext context) {
    return previewList([
      PreviewSection(
        title: 'SalesProductPickerSearchBar',
        child: SalesProductPickerSearchBar(
          onSearch: (_) {},
          onScanTap: () {},
          initialQuery: 'Vaccine',
        ),
      ),
      PreviewSection(
        title: 'SalesProductPickerCard',
        child: Column(
          children: [
            PreviewStateRow(
              label: 'Sellable',
              child: SalesProductPickerCard(
                product: SalesPreviewFixtures.product,
                onTap: () {},
              ),
            ),
            PreviewStateRow(
              label: 'Blocked',
              child: SalesProductPickerCard(
                product: SalesPreviewFixtures.productBlocked,
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
      PreviewSection(
        title: 'SalesProductPickerBody',
        child: Column(
          children: [
            PreviewStateRow(
              label: 'Loading',
              child: PreviewEmbedFrame(
                height: 120,
                child: SalesProductPickerBody(
                  state: const SalesProductPickerLoading(query: ''),
                  onTapProduct: (_) {},
                  onClearSearch: () {},
                ),
              ),
            ),
            PreviewStateRow(
              label: 'Empty catalog',
              child: PreviewEmbedFrame(
                height: 240,
                child: SalesProductPickerBody(
                  state: const SalesProductPickerEmptyCatalog(),
                  onTapProduct: (_) {},
                  onClearSearch: () {},
                ),
              ),
            ),
            PreviewStateRow(
              label: 'No result',
              child: PreviewEmbedFrame(
                height: 260,
                child: SalesProductPickerBody(
                  state: const SalesProductPickerNoResult(query: 'xyz'),
                  onTapProduct: (_) {},
                  onClearSearch: () {},
                ),
              ),
            ),
            PreviewStateRow(
              label: 'Loaded',
              child: PreviewEmbedFrame(
                height: 240,
                child: SalesProductPickerBody(
                  state: SalesProductPickerLoaded(
                    query: '',
                    items: SalesPreviewFixtures.products,
                  ),
                  onTapProduct: (_) {},
                  onClearSearch: () {},
                ),
              ),
            ),
          ],
        ),
      ),
      PreviewSection(
        title: 'SalesProductUnitSheet',
        child: PreviewActionButton(
          label: 'Chọn đơn vị bán',
          onPressed: () => SalesProductUnitSheet.show(
            context,
            product: SalesPreviewFixtures.product,
          ),
        ),
      ),
    ]);
  }
}
