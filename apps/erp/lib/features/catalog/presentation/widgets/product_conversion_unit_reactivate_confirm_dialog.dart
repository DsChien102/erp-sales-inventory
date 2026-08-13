import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class ProductConversionUnitReactivateConfirmDialog extends StatelessWidget {
  const ProductConversionUnitReactivateConfirmDialog({
    super.key,
    required this.unitName,
    required this.onConfirm,
  });

  final String unitName;
  final VoidCallback onConfirm;

  static Future<void> show(
    BuildContext context, {
    required String unitName,
    required VoidCallback onConfirm,
  }) {
    return showVBottomSheet(
      context: context,
      title: 'Bật lại đơn vị?',
      child: ProductConversionUnitReactivateConfirmDialog(
        unitName: unitName,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.space5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VText(
              'Đơn vị "$unitName" sẽ được dùng lại trong nhập/bán hàng.',
              variant: VTextVariant.bodyDefault,
              color: dynamicColors.textSecondary,
            ),
            const SizedBox(height: VSpacing.space6),
            Row(
              children: [
                Expanded(
                  child: VButton(
                    label: 'Huỷ',
                    onPressed: () => Navigator.of(context).pop(),
                    variant: VButtonVariant.secondary,
                  ),
                ),
                const SizedBox(width: VSpacing.space4),
                Expanded(
                  child: VButton(
                    key: const Key('btn_confirm_reactivate_conversion_unit'),
                    label: 'Bật',
                    onPressed: () {
                      Navigator.of(context).pop();
                      onConfirm();
                    },
                    variant: VButtonVariant.primary,
                    tone: VComponentTone.danger,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
