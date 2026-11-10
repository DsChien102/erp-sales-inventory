import 'package:erp/features/inventory/logic/stock/stock_indicator_rules.dart';
import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Badge chỉ báo tồn theo đặc tả Theme 7 (bj01 / cap01).
class StockIndicatorBadge extends StatelessWidget {
  final List<StockIndicator> indicators;
  final StockIndicator? filter;

  const StockIndicatorBadge({
    super.key,
    required this.indicators,
    this.filter,
  });

  @override
  Widget build(BuildContext context) {
    final primary = primaryIndicator(indicators, filter: filter);
    if (primary == null) {
      return const VBadge(
        label: 'Bình thường',
        tone: VComponentTone.success,
      );
    }

    if (primary.tone != null) {
      return VBadge(
        label: primary.label,
        tone: primary.tone,
        showDot: true,
      );
    }

    return VBadge(
      label: primary.label,
      tone: VComponentTone.neutral,
    );
  }
}

