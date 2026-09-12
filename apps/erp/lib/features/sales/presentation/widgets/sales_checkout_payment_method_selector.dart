import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import '../models/sales_order/sales_checkout_vm.dart';

class SalesCheckoutPaymentMethodSelector extends StatelessWidget {
  const SalesCheckoutPaymentMethodSelector({
    super.key,
    required this.selectedMode,
    required this.onModeSelected,
  });

  final SalesPaymentMode selectedMode;
  final ValueChanged<SalesPaymentMode> onModeSelected;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = switch (selectedMode) {
      SalesPaymentMode.cash => 0,
      SalesPaymentMode.bankTransfer => 1,
      SalesPaymentMode.mixed => 2,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const VText(
          'Phương thức',
          variant: VTextVariant.headingH4,
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const VGap.sm(),
        VSegmentedControl(
          segments: const ['Tiền mặt', 'Chuyển khoản', 'Kết hợp'],
          selectedIndex: selectedIndex,
          tone: VComponentTone.success,
          onChanged: (index) {
            switch (index) {
              case 0:
                onModeSelected(SalesPaymentMode.cash);
              case 1:
                onModeSelected(SalesPaymentMode.bankTransfer);
              case 2:
                onModeSelected(SalesPaymentMode.mixed);
            }
          },
        ),
      ],
    );
  }
}
