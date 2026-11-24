import 'package:flutter/material.dart';

import '../foundation/v_context_extensions.dart';
import '../primitives/v_badge.dart';
import '../tokens/v_spacing.dart';
import '../tokens/v_typography.dart';
import 'v_list_row.dart';

class VStockRow extends StatelessWidget {
  const VStockRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.quantity,
    this.badge,
    this.badgeSemanticsLabel,
    this.onTap,
    this.selected = false,
  });

  final String title;
  final String? subtitle;
  final String quantity;
  final Widget? badge;
  final String? badgeSemanticsLabel;
  final VoidCallback? onTap;
  final bool selected;

  String? _resolveBadgeLabel() {
    if (badgeSemanticsLabel != null && badgeSemanticsLabel!.isNotEmpty) {
      return badgeSemanticsLabel;
    }
    final b = badge;
    if (b is VBadge) {
      return b.semanticLabel ?? b.label;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final badgeText = _resolveBadgeLabel();
    final semanticLabel = badgeText != null && badgeText.isNotEmpty
        ? '$title, $quantity, $badgeText'
        : '$title, $quantity';

    return VListRow(
      title: title,
      subtitle: subtitle,
      asCard: true,
      minHeight: 64,
      selected: selected,
      type: VListRowType.navigation,
      onTap: onTap,
      semanticLabel: semanticLabel,
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            quantity,
            maxLines: 1,
            softWrap: false,
            style: TextStyle(
              fontFamily: VTypography.monoFontFamily,
              fontSize: 16,
              height: 22 / 16,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (badge != null) ...[
            const SizedBox(height: VSpacing.space1),
            badge!,
          ],
        ],
      ),
    );
  }
}

