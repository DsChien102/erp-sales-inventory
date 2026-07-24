import 'package:flutter/material.dart';
// contract: na tone/emphasis/state

import '../patterns/v_gap.dart';
import '../primitives/v_text.dart';
import '../foundation/v_context_extensions.dart';

/// Section block: optional title row + content with standard spacing.
class VSection extends StatelessWidget {
  const VSection({
    super.key,
    this.title,
    this.subtitle,
    this.trailing,
    required this.child,
    this.gapAfterHeader = VGapSize.sm,
  });

  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  final VGapSize gapAfterHeader;

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final hasHeader = title != null || subtitle != null || trailing != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasHeader) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              ?trailing,
            ],
          ),
          VGap(gapAfterHeader),
        ],
        child,
      ],
    );
  }
}
