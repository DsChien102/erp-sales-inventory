import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

class UsersEmptyState extends StatelessWidget {
  const UsersEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionText,
    this.onAction,
    this.iconBgColor,
    this.iconColor,
    this.titleColor,
    this.actionColor,
    this.actionVariant = VButtonVariant.primary,
  });

  final VIcons icon;
  final String title;
  final String subtitle;
  final String actionText;
  final VoidCallback? onAction;
  final Color? iconBgColor;
  final Color? iconColor;
  final Color? titleColor;
  final Color? actionColor;
  final VButtonVariant actionVariant;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final isDanger = actionColor == colors.danger;
    return Padding(
      padding: const EdgeInsets.all(VSpacing.screenMobile),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VIconBox(
            icon: icon,
            size: 56,
            iconSize: 28,
            backgroundColor: iconBgColor ?? colors.surfaceAlt,
            iconColor: iconColor ?? colors.textPrimary,
            borderRadius: VRadius.r12,
          ),
          const VGap.md(),
          Semantics(
            header: true,
            child: VText(
              title,
              variant: VTextVariant.headingH4,
              color: titleColor,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const VGap.sm(),
          VText(
            subtitle,
            variant: VTextVariant.bodySmall,
            color: colors.textSecondary,
            textAlign: TextAlign.center,
          ),
          if (onAction != null) ...[
            const VGap.lg(),
            VButton(
              label: actionText,
              variant: actionVariant,
              tone: isDanger ? VComponentTone.danger : VComponentTone.primary,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}

class UsersEmptyScroll extends StatelessWidget {
  const UsersEmptyScroll({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: 480,
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}
