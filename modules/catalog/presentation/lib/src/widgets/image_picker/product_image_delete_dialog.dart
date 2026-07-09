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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: VColors.dangerBg,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.delete_outline, color: VColors.danger, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              'Xóa ảnh sản phẩm?',
              style: VTypography.headingH4.copyWith(
                color: dynamicColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Ảnh này sẽ bị xóa vĩnh viễn. Nếu đây là ảnh mặc định, hệ thống sẽ chọn ảnh còn lại đầu tiên làm ảnh mặc định.',
              style: VTypography.bodyDefault.copyWith(
                color: dynamicColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: VButton(
                    label: 'Hủy',
                    variant: VButtonVariant.outline,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 16),
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
