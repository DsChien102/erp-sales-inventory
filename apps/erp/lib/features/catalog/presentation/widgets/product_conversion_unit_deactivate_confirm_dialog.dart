import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class ProductConversionUnitDeactivateConfirmDialog extends StatelessWidget {
  const ProductConversionUnitDeactivateConfirmDialog({
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
      title: 'Tắt đơn vị này?',
      child: ProductConversionUnitDeactivateConfirmDialog(
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
            Text(
              'Đơn vị "$unitName" sẽ ẩn khỏi lựa chọn khi nhập/bán, '
              'dữ liệu cũ vẫn giữ nguyên.',
              style: VTypography.bodyDefault.copyWith(
                color: dynamicColors.textSecondary,
              ),
            ),
            const SizedBox(height: VSpacing.space6),
            Row(
              children: [
                Expanded(
                  child: VButton(
                    label: 'Huỷ',
                    onPressed: () => Navigator.of(context).pop(),
                    variant: VButtonVariant.outline,
                  ),
                ),
                const SizedBox(width: VSpacing.space4),
                Expanded(
                  child: VButton(
                    key: const Key('btn_confirm_deactivate_conversion_unit'),
                    label: 'Tắt',
                    onPressed: () {
                      Navigator.of(context).pop();
                      onConfirm();
                    },
                    variant: VButtonVariant.danger,
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
