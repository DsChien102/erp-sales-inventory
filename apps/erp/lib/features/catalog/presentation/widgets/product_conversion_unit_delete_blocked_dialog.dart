import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class ProductConversionUnitDeleteBlockedDialog extends StatelessWidget {
  const ProductConversionUnitDeleteBlockedDialog({
    super.key,
    required this.message,
    required this.onDeactivate,
  });

  final String message;
  final VoidCallback onDeactivate;

  static Future<void> show(
    BuildContext context, {
    required String message,
    required VoidCallback onDeactivate,
  }) {
    return showVBottomSheet(
      context: context,
      title: 'Không thể xóa đơn vị',
      child: ProductConversionUnitDeleteBlockedDialog(
        message: message,
        onDeactivate: onDeactivate,
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
            Text(
              message,
              style: VTypography.bodyDefault.copyWith(
                color: dynamicColors.textSecondary,
              ),
            ),
            const SizedBox(height: VSpacing.space6),
            Row(
              children: [
                Expanded(
                  child: VButton(
                    label: 'Đóng',
                    onPressed: () => Navigator.of(context).pop(),
                    variant: VButtonVariant.outline,
                  ),
                ),
                const SizedBox(width: VSpacing.space4),
                Expanded(
                  child: VButton(
                    key: const Key('btn_suggest_deactivate_conversion_unit'),
                    label: 'Tắt đơn vị',
                    onPressed: () {
                      Navigator.of(context).pop();
                      onDeactivate();
                    },
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
