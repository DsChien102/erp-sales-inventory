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

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    Widget content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.space3,
        vertical: VSpacing.space2,
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            VIconBox(
              icon: leading,
              size: 36,
              iconSize: 20,
              backgroundColor: colors.surfaceBrand,
              iconColor: colors.primary,
              borderRadius: VRadius.r8,
            ),
            const SizedBox(width: VSpacing.space3),
          ],
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
      constraints: const BoxConstraints(minHeight: VSpacing.minTouchTarget),
      child: Center(
        child: content,
      ),
    );

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
                  child: content,
                )
              : content,
        ),
      ),
    );
  }
}
