import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

import 'product_list_filter.dart';

class ProductCatalogFilterChips extends StatelessWidget {
  const ProductCatalogFilterChips({
    super.key,
    required this.selectedFilter,
    required this.globalCount,
    required this.onFilterChanged,
    this.filterCounts,
  });

  final ProductListFilter selectedFilter;
  final int? globalCount;
  final ValueChanged<ProductListFilter> onFilterChanged;
  final Map<ProductListFilter, int>? filterCounts;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: VSpacing.screenMobile),
      child: Wrap(
        spacing: VSpacing.space2,
        children: [
          ...ProductListFilter.values.map(
            (e) {
              final count = e == ProductListFilter.all ? globalCount : filterCounts?[e];
              final label = count != null ? '${e.label} ($count)' : e.label;
              return VChip(
                label: label,
                selected: selectedFilter == e,
                onTap: () => onFilterChanged(e),
              );
            },
          ),
        ],
      ),
    );
  }
}
