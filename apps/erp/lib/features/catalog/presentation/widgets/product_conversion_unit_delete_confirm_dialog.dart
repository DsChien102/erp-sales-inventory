import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class ProductConversionUnitDeleteConfirmDialog extends StatelessWidget {
  const ProductConversionUnitDeleteConfirmDialog({
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
      title: 'Xoá đơn vị quy đổi?',
      child: ProductConversionUnitDeleteConfirmDialog(
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
              'Đơn vị "$unitName" sẽ bị xóa vĩnh viễn khỏi sản phẩm. '
              'Chỉ dùng khi đơn vị chưa có giao dịch hoặc khung giá. '
              'Nếu đã phát sinh dữ liệu, hệ thống sẽ gợi ý "Tắt đơn vị" thay vì xóa.',
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
                    variant: VButtonVariant.outline,
                  ),
                ),
                const SizedBox(width: VSpacing.space4),
                Expanded(
                  child: VButton(
                    key: const Key('btn_confirm_delete_conversion_unit'),
                    label: 'Xoá',
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
