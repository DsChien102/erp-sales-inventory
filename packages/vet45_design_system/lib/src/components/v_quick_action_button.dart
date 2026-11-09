import 'package:flutter/material.dart';

import '../foundation/v_context_extensions.dart';
import '../foundations/icons/v_icons.dart';
import '../patterns/v_gap.dart';
import '../primitives/v_icon_box.dart';
import '../primitives/v_text.dart';
import '../tokens/v_opacity.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_spacing.dart';

class VQuickActionButton extends StatelessWidget {
  const VQuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.semanticLabel,
  });

  final VIcons icon;
  final String label;
  final VoidCallback? onPressed;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final isEnabled = onPressed != null;

    final content = ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: VSpacing.minTouchTarget,
        minHeight: VSpacing.minTouchTarget,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.space2,
          vertical: VSpacing.space1,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            VIconBox(
              icon: icon,
              size: 44,
              iconSize: 22,
              backgroundColor: colors.surfaceBrand,
              iconColor: colors.primary,
              borderRadius: VRadius.r12,
            ),
            const VGap.xs(),
            VText(
              label,
              variant: VTextVariant.bodySmall,
              color: colors.textSecondary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    return Semantics(
      container: true,
      button: true,
      enabled: isEnabled,
      label: semanticLabel ?? label,
      child: vDisabledOpacity(
        enabled: isEnabled,
        child: Material(
          type: MaterialType.transparency,
          child: isEnabled
              ? InkWell(
                  onTap: onPressed,
                  borderRadius: BorderRadius.circular(VRadius.r12),
                  child: content,
                )
              : content,
        ),
      ),
    );
  }
}
