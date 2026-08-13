import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class ProductControlCenterSectionCard extends StatelessWidget {
  const ProductControlCenterSectionCard({
    super.key,
    this.icon,
    this.emoji,
    required this.title,
    required this.subtitle,
    this.onEdit,
    this.actionText = 'Sửa',
    this.hasError = false,
  });

  final VIcons? icon;
  final String? emoji;
  final String title;
  final String subtitle;
  final VoidCallback? onEdit;
  final String actionText;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return GestureDetector(
      onTap: onEdit,
      child: VCard(
        child: Row(
          children: [
            if (emoji != null && emoji!.isNotEmpty)
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: hasError ? dynamicColors.dangerBg : dynamicColors.surfaceBrand,
                  borderRadius: BorderRadius.circular(VRadius.iconBox),
                ),
                child: VText(
                  emoji!,
                  style: const TextStyle(fontSize: 20),
                ),
              )
            else
              VIconBox(
                icon: icon ?? VIcons.clipboard,
                size: 40,
                iconSize: 20,
                backgroundColor: hasError ? dynamicColors.dangerBg : dynamicColors.surfaceBrand,
                iconColor: hasError ? dynamicColors.danger : dynamicColors.primary,
              ),
            const VGap.horizontalMd(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VText(
                    title,
                    variant: VTextVariant.bodyDefault,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const VGap.xs(),
                  VText(
                    subtitle,
                    variant: VTextVariant.bodySmall,
                    color: dynamicColors.textSecondary,
                  ),
                  if (hasError) ...[
                    const VGap.xs(),
                    VText(
                      'Thiếu thông tin bắt buộc',
                      variant: VTextVariant.caption,
                      color: dynamicColors.textSecondary,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ],
              ),
            ),
            VButton(
              label: actionText,
              variant: VButtonVariant.tertiary,
              size: VButtonSize.small,
              onPressed: onEdit,
            ),
          ],
        ),
      ),
    );
  }
}
