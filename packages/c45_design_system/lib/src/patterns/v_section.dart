import 'package:flutter/material.dart';
// contract: na tone/emphasis/state

import '../foundation/v_context_extensions.dart';
import '../foundation/v_inspector_scope.dart';
import '../patterns/v_gap.dart';
import '../primitives/v_text.dart';
import '../tokens/v_spacing.dart';

/// Section block: optional title row + content with standard spacing.
class VSection extends StatelessWidget {
  const VSection({
    super.key,
    this.title,
    this.subtitle,
    this.trailing,
    required this.child,
    this.gapAfterHeader = VSpacing.sm,
  });

  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  final double gapAfterHeader;

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final hasHeader = title != null || subtitle != null || trailing != null;

    return vInspectorHide(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasHeader) ...[
            Row(
              // A lone title centers on a 44px trailing action; with a subtitle
              // the action stays aligned to the title line.
              crossAxisAlignment: subtitle == null
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null)
                        VText(
                          title!,
                          variant: VTextVariant.headingH3,
                        ),
                      if (subtitle != null) ...[
                        if (title != null) const VGap.xs(),
                        VText(
                          subtitle!,
                          variant: VTextVariant.bodySmall,
                          color: dynamicColors.textSecondary,
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const VGap.horizontalSm(),
                  vInspectorShow(trailing!),
                ],
              ],
            ),
            VGap(gapAfterHeader),
          ],
          vInspectorShow(child),
        ],
      ),
    );
  }
}
