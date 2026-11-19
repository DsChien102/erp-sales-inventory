import 'package:flutter/material.dart';

import '../foundation/v_context_extensions.dart';
import '../foundations/icons/v_icons.dart';
import '../primitives/v_icon.dart';
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

    final content = Container(
      constraints: const BoxConstraints(
        minWidth: VSpacing.minTouchTarget,
        minHeight: 86,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(VRadius.r12),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFEDF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: VIcon(
                icon: icon,
                size: 20,
                color: colors.primary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          VText(
            label,
            variant: VTextVariant.bodyDefault,
            color: colors.textPrimary,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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
