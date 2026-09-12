import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/sales/presentation.dart';

class SalesCheckoutPercentRow extends StatelessWidget {
  const SalesCheckoutPercentRow({
    super.key,
    required this.currentMode,
    required this.selectedPercent,
    required this.disableLowPercent,
    required this.onSelect,
  });

  final SalesPaymentMode currentMode;
  final int selectedPercent;
  final bool disableLowPercent;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = selectedPercent >= 75
        ? 2
        : selectedPercent >= 25
            ? 1
            : 0;

    if (!disableLowPercent) {
      return VSegmentedControl(
        segments: const ['0%', '50%', '100%'],
        selectedIndex: selectedIndex,
        tone: VComponentTone.success,
        onChanged: (index) => onSelect(switch (index) {
          0 => 0,
          1 => 50,
          _ => 100,
        }),
      );
    }

    return Row(
      children: [
        Expanded(
          child: VButton(
            key: const Key('btn_sg05_percent_0'),
            label: '0%',
            variant: VButtonVariant.secondary,
            enabled: false,
            onPressed: null,
          ),
        ),
        const VGap.horizontalXs(),
        Expanded(
          child: VButton(
            key: const Key('btn_sg05_percent_50'),
            label: '50%',
            variant: VButtonVariant.secondary,
            enabled: false,
            onPressed: null,
          ),
        ),
        const VGap.horizontalXs(),
        Expanded(
          child: VButton(
            key: const Key('btn_sg05_percent_100'),
            label: '100%',
            tone: VComponentTone.success,
            onPressed: () => onSelect(100),
          ),
        ),
      ],
    );
  }
}
