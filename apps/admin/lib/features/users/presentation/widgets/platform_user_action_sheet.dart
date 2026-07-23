import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class PlatformUserActionCard extends StatelessWidget {
  const PlatformUserActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  final VIcons icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final cardBg = isDestructive ? colors.dangerBg : colors.surface;
    final cardBorder = isDestructive
        ? colors.danger.withValues(alpha: 0.18)
        : colors.borderDefault;
    final textColor = isDestructive ? colors.danger : colors.textPrimary;
    final subtitleColor = isDestructive
        ? colors.danger.withValues(alpha: 0.7)
        : colors.textSecondary;
    final iconColor = isDestructive ? colors.danger : colors.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VRadius.r12),
        child: Ink(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(VRadius.r12),
            border: Border.all(color: cardBorder, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: VSpacing.space4,
              vertical: 14,
            ),
            child: Row(
              children: [
                VIcon(icon: icon, color: iconColor, size: 24),
                const VGap.horizontalMd(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VText(
                        title,
                        variant: VTextVariant.bodyDefault,
                        color: textColor,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const VGap.xs(),
                      VText(
                        subtitle,
                        variant: VTextVariant.bodySmall,
                        color: subtitleColor,
                      ),
                    ],
                  ),
                ),
                VIcon(
                  icon: VIcons.chevronRight,
                  color: isDestructive ? colors.danger : colors.textMuted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showPlatformUserConfirmSheet({
  required BuildContext context,
  required String title,
  required Color titleColor,
  required String description,
  required String actionLabel,
  required VButtonVariant actionVariant,
  required Future<void> Function(String reason) onConfirm,
  bool requireReason = false,
}) {
  final reasonController = TextEditingController();

  return showVBottomSheet(
    context: context,
    child: Padding(
      padding: const EdgeInsets.all(VSpacing.screenMobile),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VText(
            title,
            variant: VTextVariant.headingH3,
            style: TextStyle(fontWeight: FontWeight.w700, color: titleColor),
          ),
          const VGap.sm(),
          VText(
            description,
            variant: VTextVariant.bodyDefault,
            color: context.vColors.textSecondary,
          ),
          const VGap.md(),
          VTextFormField(
            controller: reasonController,
            label: 'Lý do',
            hintText: 'Nhập lý do',
            isRequired: requireReason,
            maxLines: 1,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: VSpacing.space3,
              vertical: VSpacing.space2,
            ),
            helperText: 'Lý do được lưu trong lịch sử quản trị.',
          ),
          const VGap.lg(),
          VButton(
            label: 'Quay lại',
            variant: VButtonVariant.outline,
            fullWidth: true,
            onPressed: () => Navigator.pop(context),
          ),
          const VGap.sm(),
          VButton(
            label: actionLabel,
            variant: actionVariant,
            fullWidth: true,
            onPressed: () {
              onConfirm(reasonController.text.trim());
            },
          ),
        ],
      ),
    ),
  );
}
