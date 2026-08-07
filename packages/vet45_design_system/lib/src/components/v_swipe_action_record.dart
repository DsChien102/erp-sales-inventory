import 'package:flutter/material.dart';

import '../foundation/v_component_contracts.dart';
import '../foundation/v_context_extensions.dart';
import '../patterns/v_gap.dart';
import '../primitives/v_badge.dart';
import '../primitives/v_text.dart';
import '../theme/v_color_scheme.dart';
import '../tokens/v_borders.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_spacing.dart';
import 'v_swipe_reveal.dart';

/// Swipe-left record card that reveals a destructive action.
///
/// Gesture-only pattern — the consumer attaches confirmation on [onAction].
class VSwipeActionRecord extends StatelessWidget {
  const VSwipeActionRecord({
    super.key,
    required this.title,
    this.supportingText1,
    this.supportingText2,
    this.summary,
    this.timestamp,
    this.badgeLabel,
    this.actionLabel = 'Xóa',
    this.onAction,
    this.onTap,
    this.enabled = true,
    this.tone = VComponentTone.danger,
    this.emphasis = VComponentEmphasis.medium,
    this.state,
    this.semanticLabel,
    this.actionWidth = 76,
  });

  final String title;
  final String? supportingText1;
  final String? supportingText2;
  final String? summary;
  final String? timestamp;
  final String? badgeLabel;
  final String actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onTap;
  final bool enabled;
  final VComponentTone tone;
  final VComponentEmphasis emphasis;
  final VComponentState? state;
  final String? semanticLabel;
  final double actionWidth;

  static const double _cardHeight = 118;

  VComponentState get _resolvedState =>
      state ?? (enabled ? VComponentState.enabled : VComponentState.disabled);

  bool get _isEnabled => _resolvedState == VComponentState.enabled;

  bool get _hasBadge =>
      badgeLabel != null && badgeLabel!.trim().isNotEmpty;

  Color _actionBg(VColorScheme colors) => switch (tone) {
        VComponentTone.warning => colors.warning,
        VComponentTone.success => colors.success,
        VComponentTone.primary => colors.primary,
        _ => colors.danger,
      };

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final borderWidth = VBorders.widthFor(emphasis);

    return Semantics(
      label: semanticLabel ?? title,
      button: onTap != null,
      enabled: _isEnabled,
      child: VSwipeReveal(
        height: _cardHeight,
        enabled: _isEnabled,
        actionExtent: actionWidth,
        clipBorderRadius: BorderRadius.circular(VRadius.card),
        onTap: onTap,
        actionsBuilder: (context, close) => Material(
          color: _actionBg(colors),
          child: InkWell(
            onTap: _isEnabled && onAction != null
                ? () {
                    onAction!();
                    close();
                  }
                : null,
            child: SizedBox(
              width: actionWidth,
              height: double.infinity,
              child: Center(
                child: VText(
                  actionLabel,
                  variant: VTextVariant.bodyDefault,
                  textAlign: TextAlign.center,
                  color: colors.surface,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    height: 20 / 14,
                  ),
                ),
              ),
            ),
          ),
        ),
        child: Material(
          color: colors.surface,
          borderRadius: const BorderRadius.horizontal(
            left: Radius.circular(VRadius.card),
          ),
          child: Container(
            width: double.infinity,
            height: _cardHeight,
            padding: const EdgeInsets.fromLTRB(
              VSpacing.space3,
              VSpacing.space3,
              VSpacing.space3,
              14,
            ),
            decoration: BoxDecoration(
              border: VBorders.all(
                colors.borderDefault,
                width: borderWidth,
              ),
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(VRadius.card),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: VText(
                        title,
                        variant: VTextVariant.bodyDefault,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          height: 22 / 15,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    if (_hasBadge) ...[
                      const VGap.horizontalXs(),
                      // Small badge keeps title-row ≤ 22px (default badge overflows 118px card).
                      VBadge(
                        label: badgeLabel!,
                        status: VBadgeStatus.warning,
                        isSmall: true,
                      ),
                    ],
                  ],
                ),
                if (supportingText1 != null) ...[
                  const VGap.xs(),
                  VText(
                    supportingText1!,
                    variant: VTextVariant.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    color: colors.textSecondary,
                  ),
                ],
                if (supportingText2 != null)
                  VText(
                    supportingText2!,
                    variant: VTextVariant.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    color: colors.textSecondary,
                  ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: VText(
                        summary ?? '',
                        variant: VTextVariant.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        color: colors.textSecondary,
                      ),
                    ),
                    if (timestamp != null)
                      VText(
                        timestamp!,
                        variant: VTextVariant.caption,
                        color: colors.textSecondary,
                        style: const TextStyle(fontWeight: FontWeight.w400),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
