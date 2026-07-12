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

  final IconData? icon;
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
        padding: const EdgeInsets.all(16),
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
                child: Text(
                  emoji!,
                  style: const TextStyle(fontSize: 20),
                ),
              )
            else
              VIconBox(
                iconData: icon ?? Icons.assignment_outlined,
                size: 40,
                iconSize: 20,
                backgroundColor: hasError ? dynamicColors.dangerBg : dynamicColors.surfaceBrand,
                iconColor: hasError ? dynamicColors.danger : dynamicColors.primary,
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: VTypography.bodyDefault.copyWith(
                      color: dynamicColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: VTypography.bodySmall.copyWith(
                      color: dynamicColors.textSecondary,
                    ),
                  ),
                  if (hasError) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const SizedBox(width: 4),
                        Text(
                          'Thiếu thông tin bắt buộc',
                          style: VTypography.caption.copyWith(
                            color: dynamicColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            TextButton(
              onPressed: onEdit,
              child: Text(
                actionText,
                style: VTypography.bodyDefault.copyWith(
                  color: hasError ? dynamicColors.primary : null,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
