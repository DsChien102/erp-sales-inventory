import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import 'product_list_filter.dart';

class ProductCatalogFilterChips extends StatelessWidget {
  const ProductCatalogFilterChips({
    super.key,
    required this.selectedFilter,
    required this.globalCount,
    required this.onFilterChanged,
  });

  final ProductListFilter selectedFilter;
  final int? globalCount;
  final ValueChanged<ProductListFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: VSpacing.screenMobile),
      child: Wrap(
        spacing: VSpacing.space2,
        children: [
          ...ProductListFilter.values.map(
            (e) => VChip(
              label: e == ProductListFilter.all && globalCount != null
                  ? '${e.label} ($globalCount)'
                  : e.label,
              selected: selectedFilter == e,
              onTap: () => onFilterChanged(e),
            ),
          ),
        ],
      ),
    );
  }
}
