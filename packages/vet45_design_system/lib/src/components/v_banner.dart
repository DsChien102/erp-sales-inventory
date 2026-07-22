import 'package:flutter/material.dart';

import '../foundation/v_context_extensions.dart';
import '../foundations/icons/v_icons.dart';
import '../patterns/v_gap.dart';
import '../primitives/v_icon.dart';
import '../primitives/v_text.dart';
import '../theme/v_color_scheme.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_spacing.dart';

/// Semantic status for inline [VBanner] notifications.
enum VBannerStatus { info, success, warning, error }

/// Inline status banner with icon, title, and optional description.
///
/// Use for persistent in-page feedback (not transient toasts).
class VBanner extends StatelessWidget {
  const VBanner({
    super.key,
    required this.title,
    required this.status,
    this.description,
    this.icon,
    this.semanticLabel,
  });

  final String title;
  final String? description;
  final VBannerStatus status;

  /// Optional icon override; defaults to status icon.
  final VIcons? icon;

  final String? semanticLabel;

  VIcons get _defaultIcon => switch (status) {
    VBannerStatus.info => VIcons.info,
    VBannerStatus.success => VIcons.success,
    VBannerStatus.warning => VIcons.warning,
    VBannerStatus.error => VIcons.close,
  };

  (Color background, Color accent) _colors(VColorScheme colors) {
    return switch (status) {
      VBannerStatus.info => (colors.infoBg, colors.info),
      VBannerStatus.success => (colors.successBg, colors.success),
      VBannerStatus.warning => (colors.warningBg, colors.warning),
      VBannerStatus.error => (colors.dangerBg, colors.danger),
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final (background, accent) = _colors(colors);
    final resolvedIcon = icon ?? _defaultIcon;

    return Semantics(
      label: semanticLabel ?? title,
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(VRadius.r12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(VSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _VBannerIcon(
                icon: resolvedIcon,
                accent: accent,
              ),
              const VGap.horizontalSm(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    VText(
                      title,
                      variant: VTextVariant.bodyDefault,
                      color: accent,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (description != null && description!.trim().isNotEmpty) ...[
                      const VGap.xs(),
                      VText(
                        description!,
                        variant: VTextVariant.bodySmall,
                        color: colors.textPrimary,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VBannerIcon extends StatelessWidget {
  const _VBannerIcon({
    required this.icon,
    required this.accent,
  });

  final VIcons icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: SizedBox(
        width: 28,
        height: 28,
        child: Center(
          child: VIcon(
            icon: icon,
            size: 16,
            color: accent,
          ),
        ),
      ),
    );
  }
}
