import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

enum ProductImageSource {
  camera,
  gallery,
  file,
}

class ProductImageAddSheet extends StatelessWidget {
  const ProductImageAddSheet({super.key});

  static Future<ProductImageSource?> show(BuildContext context) {
    return showModalBottomSheet<ProductImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const ProductImageAddSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return Container(
      decoration: BoxDecoration(
        color: dynamicColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(VRadius.sheet)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              VText(
                'Thêm ảnh sản phẩm',
                variant: VTextVariant.headingH4,
                color: dynamicColors.textPrimary,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: VSpacing.space4),
              _buildOption(
                context,
                icon: Icons.camera_alt,
                iconColor: dynamicColors.success,
                title: 'Chụp ảnh',
                subtitle: 'Dùng camera của thiết bị',
                onTap: () => Navigator.of(context).pop(ProductImageSource.camera),
              ),
              const SizedBox(height: VSpacing.space2),
              _buildOption(
                context,
                icon: Icons.photo_library,
                iconColor: dynamicColors.primary,
                title: 'Chọn từ thư viện',
                subtitle: 'Chọn ảnh đã có trên máy',
                onTap: () => Navigator.of(context).pop(ProductImageSource.gallery),
              ),
              const SizedBox(height: VSpacing.space2),
              _buildOption(
                context,
                icon: Icons.folder,
                iconColor: dynamicColors.primary,
                title: 'Chọn tệp',
                subtitle: 'Tải ảnh từ thư mục',
                onTap: () => Navigator.of(context).pop(ProductImageSource.file),
              ),
              const SizedBox(height: VSpacing.space6),
              VButton(
                label: 'Hủy',
                variant: VButtonVariant.outline,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final dynamicColors = context.vColors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(VSpacing.space3),
        decoration: BoxDecoration(
          border: Border.all(color: dynamicColors.borderDefault),
          borderRadius: BorderRadius.circular(VRadius.card),
          color: dynamicColors.background,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(VSpacing.space2),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(VRadius.card),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: VSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VText(
                    title,
                    variant: VTextVariant.bodyDefault,
                    color: dynamicColors.textPrimary,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const VGap.xs(),
                  VText(
                    subtitle,
                    variant: VTextVariant.bodySmall,
                    color: dynamicColors.textSecondary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
