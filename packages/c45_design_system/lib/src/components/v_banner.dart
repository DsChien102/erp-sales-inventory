import 'package:flutter/material.dart';

import '../foundation/v_component_contracts.dart';
import '../foundation/v_component_scope.dart';
import '../foundation/v_context_extensions.dart';
import '../foundation/v_inspector_scope.dart';
import '../foundations/icons/v_icons.dart';
import '../patterns/v_gap.dart';
import '../primitives/v_icon.dart';
import '../primitives/v_text.dart';
import '../theme/v_color_scheme.dart';
import '../tokens/v_borders.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_spacing.dart';

/// Semantic status for inline [VBanner] notifications.
enum VBannerStatus { info, success, warning, error }

/// Inline status banner with status icon, title, and optional description.
///
/// Use for persistent in-page feedback (not transient toasts).
///
/// Prefer [status]. [tone] is accepted as a convenience alias used by feature
/// modules (`VComponentTone.danger` → [VBannerStatus.error], etc.).
///
/// Icon is fixed from [status] / [tone] (no manual override). Description and
/// footer indent to align with the title after the icon column.
class VBanner extends StatelessWidget {
  /// Circular icon chrome size (matches [_VBannerIcon]).
  static const double iconSize = 20;

  /// Horizontal gap between icon and title ([VGap.horizontalSm]).
  static const double iconTitleGap = VSpacing.space3;

  /// Left inset for description / footer so they line up with the title.
  static const double contentIndent = iconSize + iconTitleGap;

  const VBanner({
    super.key,
    required this.title,
    this.status,
    this.tone,
    this.description,
    @Deprecated('Use description instead') this.message,
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

  /// Deprecated alias for [description].
  @Deprecated('Use description instead')
  final String? message;

  /// Optional trailing widget aligned with the title row.
  final Widget? trailing;

  /// Optional footer below the description (e.g. CTA / link).
  final Widget? footer;

  final String? semanticLabel;

  VBannerStatus get _resolvedStatus {
    if (status != null) return status!;
    return switch (tone!) {
      VComponentTone.info || VComponentTone.primary || VComponentTone.neutral => VBannerStatus.info,
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
    // ignore: deprecated_member_use_from_same_package
    final fromMessage = message?.trim();
    if (fromMessage != null && fromMessage.isNotEmpty) {
      return fromMessage;
    }
    return null;
  }

  VIcons get _statusIcon => switch (_resolvedStatus) {
    VBannerStatus.info => VIcons.info,
    VBannerStatus.success => VIcons.success,
    VBannerStatus.warning => VIcons.warning,
    VBannerStatus.error => VIcons.error,
  };

  (Color background, Color accent) _colors(VColorScheme colors) {
    return switch (_resolvedStatus) {
      VBannerStatus.info => (colors.infoBg, colors.info),
      VBannerStatus.success => (colors.successBg, colors.success),
      VBannerStatus.warning => (colors.warningBg, colors.warning),
      VBannerStatus.error => (colors.dangerBg, colors.danger),
    };
  }

  VComponentTone get _scopeTone {
    if (tone != null) return tone!;
    return switch (_resolvedStatus) {
      VBannerStatus.info => VComponentTone.info,
      VBannerStatus.success => VComponentTone.success,
      VBannerStatus.warning => VComponentTone.warning,
      VBannerStatus.error => VComponentTone.danger,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final (background, accent) = _colors(colors);
    final body = _resolvedDescription;

    return vInspectorHide(
      VComponentScope(
        tone: _scopeTone,
        child: Semantics(
          label: semanticLabel ?? title,
          container: true,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(VRadius.r12),
              border: VBorders.all(accent),
            ),
            child: Padding(
              padding: const EdgeInsets.all(VSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      VIcon(
                        icon: _statusIcon,
                        size: iconSize,
                        color: accent,
                      ),
                      const SizedBox(width: iconTitleGap),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: VText(
                                title,
                                variant: VTextVariant.labelDefault,
                                color: accent,
                              ),
                            ),
                            if (trailing != null) ...[
                              const VGap.horizontalSm(),
                              vInspectorShow(trailing!),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (body != null) ...[
                    const VGap(VSpacing.space1),
                    Padding(
                      padding: const EdgeInsets.only(left: contentIndent),
                      child: VText(
                        body,
                        variant: VTextVariant.bodySmall,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                  if (footer != null) ...[
                    const VGap(VSpacing.space1),
                    Padding(
                      padding: const EdgeInsets.only(left: contentIndent),
                      child: vInspectorShow(footer!),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
