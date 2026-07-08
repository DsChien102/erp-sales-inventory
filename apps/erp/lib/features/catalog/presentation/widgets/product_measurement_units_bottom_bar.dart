import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

class ProductMeasurementUnitsBottomBar extends StatelessWidget {
  const ProductMeasurementUnitsBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: dynamicColors.background,
          border: Border(top: BorderSide(color: dynamicColors.borderDefault)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton(
              onPressed: () => context.pop(),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: dynamicColors.borderDefault),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                'Huỷ',
                style: VTypography.bodyDefault.copyWith(color: dynamicColors.textPrimary),
              ),
            ),
            VButton(
              label: 'Lưu thay đổi',
              onPressed: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }
}
