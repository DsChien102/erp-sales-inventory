import 'package:flutter/material.dart';

import '../foundation/v_component_contracts.dart';
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
///
/// Prefer [status]. [tone] is accepted as a convenience alias used by feature
/// modules (`VComponentTone.danger` → [VBannerStatus.error], etc.).
/// [message] is an alias for [description].
class VBanner extends StatelessWidget {
  const VBanner({
    super.key,
    required this.title,
    this.status,
    this.tone,
    this.description,
    this.message,
    this.icon,
    this.trailing,
    this.footer,
    this.semanticLabel,
  }) : assert(
         status != null || tone != null,
         'Provide either status or tone',
       );

  final String title;

  /// Preferred status token.
  final VBannerStatus? status;

  /// Convenience alias for [status] via [VComponentTone].
  final VComponentTone? tone;

  /// Body copy under the title.
  final String? description;

  /// Alias for [description] (Theme 4 call-sites).
  final String? message;

  /// Optional icon override; defaults to status icon.
  final VIcons? icon;

  /// Optional trailing widget aligned with the title row.
  final Widget? trailing;

  /// Optional footer below the description (e.g. CTA / link).
  final Widget? footer;

  final String? semanticLabel;

  VBannerStatus get _resolvedStatus {
    if (status != null) return status!;
    return switch (tone!) {
      VComponentTone.info || VComponentTone.primary || VComponentTone.neutral =>
        VBannerStatus.info,
      VComponentTone.success => VBannerStatus.success,
      VComponentTone.warning => VBannerStatus.warning,
      VComponentTone.danger => VBannerStatus.error,
    };
  }

  String? get _resolvedDescription {
    final fromDescription = description?.trim();
    if (fromDescription != null && fromDescription.isNotEmpty) {
      return fromDescription;
    }
    final fromMessage = message?.trim();
    if (fromMessage != null && fromMessage.isNotEmpty) {
      return fromMessage;
    }
    return null;
  }

  VIcons get _defaultIcon => switch (_resolvedStatus) {
    VBannerStatus.info => VIcons.info,
    VBannerStatus.success => VIcons.success,
    VBannerStatus.warning => VIcons.warning,
    VBannerStatus.error => VIcons.close,
  };

  (Color background, Color accent) _colors(VColorScheme colors) {
    return switch (_resolvedStatus) {
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
    final body = _resolvedDescription;

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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: VText(
                            title,
                            variant: VTextVariant.bodyDefault,
                            color: accent,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (trailing != null) ...[
                          const VGap.horizontalSm(),
                          trailing!,
                        ],
                      ],
                    ),
                    if (body != null) ...[
                      const VGap.xs(),
                      VText(
                        body,
                        variant: VTextVariant.bodySmall,
                        color: colors.textPrimary,
                      ),
                    ],
                    if (footer != null) ...[
                      const VGap.sm(),
                      footer!,
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
