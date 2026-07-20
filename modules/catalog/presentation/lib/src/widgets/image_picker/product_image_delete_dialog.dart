import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class ProductImageDeleteDialog extends StatelessWidget {
  const ProductImageDeleteDialog({super.key});

  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const ProductImageDeleteDialog(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VRadius.sheet)),
      backgroundColor: dynamicColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(VSpacing.space3),
              decoration: BoxDecoration(
                color: dynamicColors.dangerBg,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.delete_outline, color: dynamicColors.danger, size: 32),
            ),
            const SizedBox(height: VSpacing.space4),
            VText(
              'Xóa ảnh sản phẩm?',
              variant: VTextVariant.headingH4,
              color: dynamicColors.textPrimary,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: VSpacing.space2),
            VText(
              'Ảnh này sẽ bị xóa vĩnh viễn. Nếu đây là ảnh mặc định, hệ thống sẽ chọn ảnh còn lại đầu tiên làm ảnh mặc định.',
              variant: VTextVariant.bodyDefault,
              color: dynamicColors.textSecondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: VSpacing.space6),
            Row(
              children: [
                Expanded(
                  child: VButton(
                    label: 'Hủy',
                    variant: VButtonVariant.outline,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: VSpacing.space4),
                Expanded(
                  child: VButton(
                    label: 'Xóa ảnh',
                    variant: VButtonVariant.danger,
                    onPressed: () => Navigator.of(context).pop(true),
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
