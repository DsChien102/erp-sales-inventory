import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

import '../models/sales_order/sales_order_saved_search_preset.dart';

/// Quick saved-search chips — Figma: Tất cả / Còn phải thu / Chưa phát hành HĐĐT.
/// Selected style uses strong emphasis (light green + green text) to match Figma.
class SalesOrderSavedSearchChips extends StatelessWidget {
  const SalesOrderSavedSearchChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final SalesOrderSavedSearchPreset selected;
  final ValueChanged<SalesOrderSavedSearchPreset> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: VSpacing.sm,
        children: [
          for (final preset in SalesOrderSavedSearchPreset.values)
            VChip(
              key: Key('chip_sales_saved_search_${preset.name}'),
              label: preset.label,
              tone: selected == preset ? VComponentTone.success : VComponentTone.neutral,
              onTap: () => onSelected(preset),
            ),
        ],
      ),
    );
  }
}
