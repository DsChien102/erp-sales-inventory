import 'package:flutter/material.dart';

import '../foundation/v_context_extensions.dart';
import '../foundations/icons/v_icons.dart';
import '../primitives/v_icon.dart';
import '../primitives/v_icon_box.dart';
import '../primitives/v_text.dart';
import '../tokens/v_opacity.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_spacing.dart';

enum VListRowType {
  navigation,
  selection,
  plain,
}

class VListRow extends StatelessWidget {
  const VListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.contentBelow,
    this.leading,
    this.trailing,
    this.type = VListRowType.navigation,
    this.selected = false,
    this.enabled = true,
    this.onTap,
    this.semanticLabel,
    this.asCard = false,
    this.bareLeading = false,
    this.leadingBackgroundColor,
    this.leadingIconColor,
    this.padding,
    this.minHeight,
  });

  final String title;
  final String? subtitle;
  final Widget? contentBelow;
  final VIcons? leading;
  final Widget? trailing;
  final VListRowType type;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool asCard;
  final bool bareLeading;
  final Color? leadingBackgroundColor;
  final Color? leadingIconColor;
  final EdgeInsetsGeometry? padding;
  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    Widget leadingWidget;
    if (leading == null) {
      leadingWidget = const SizedBox.shrink();
    } else if (bareLeading) {
      leadingWidget = Padding(
        padding: const EdgeInsets.only(right: VSpacing.space3),
        child: VIcon(
          icon: leading!,
          size: 24,
          color: leadingIconColor ?? colors.textPrimary,
        ),
      );
    } else if (leadingBackgroundColor != null) {
      leadingWidget = Padding(
        padding: const EdgeInsets.only(right: VSpacing.space3),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: leadingBackgroundColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: VIcon(
              icon: leading!,
              size: 18,
              color: leadingIconColor ?? colors.primary,
            ),
          ),
        ),
      );
    } else {
      leadingWidget = Padding(
        padding: const EdgeInsets.only(right: VSpacing.space3),
        child: VIconBox(
          icon: leading,
          size: 36,
          iconSize: 20,
          backgroundColor: colors.surfaceBrand,
          iconColor: colors.primary,
          borderRadius: VRadius.r8,
        ),
      );
    }

    Widget content = Padding(
      padding: padding ??
          (asCard
              ? const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                )
              : const EdgeInsets.symmetric(
                  horizontal: VSpacing.space3,
                  vertical: VSpacing.space2,
                )),
      child: Row(
        children: [
          if (leading != null) leadingWidget,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                VText(
                  title,
                  variant: VTextVariant.bodyDefault,
                  color: colors.textPrimary,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  VText(
                    subtitle!,
                    variant: VTextVariant.bodySmall,
                    color: colors.textSecondary,
                  ),
                ],
                if (contentBelow != null) ...[
                  const SizedBox(height: 4),
                  contentBelow!,
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: VSpacing.space2),
            trailing!,
          ],
          if (type == VListRowType.navigation) ...[
            const SizedBox(width: VSpacing.space2),
            VIcon(
              icon: VIcons.chevronRight,
              size: 20,
              color: colors.textSecondary,
            ),
          ],
        ],
      ),
    );

    content = ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: minHeight ??
            (asCard ? 64 : VSpacing.minTouchTarget),
      ),
      child: Center(
        child: content,
      ),
    );

    if (asCard) {
      content = Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(VRadius.r12),
          border: Border.all(color: colors.borderDefault),
        ),
        child: content,
      );
    }

    final isTappable = enabled && onTap != null;

    return Semantics(
      container: true,
      button: onTap != null,
      enabled: enabled,
      selected: type == VListRowType.selection ? selected : null,
      label: semanticLabel ?? title,
      child: vDisabledOpacity(
        enabled: enabled,
        child: Material(
          type: MaterialType.transparency,
          child: isTappable
              ? InkWell(
                  onTap: onTap,
                  borderRadius: asCard ? BorderRadius.circular(VRadius.r12) : null,
                  child: content,
                )
              : content,
        ),
      ),
    );
  }
}
