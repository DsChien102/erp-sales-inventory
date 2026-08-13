import 'package:flutter/material.dart';

import '../foundation/v_component_contracts.dart';
import '../foundation/v_context_extensions.dart';
import '../foundations/icons/v_icons.dart';
import '../patterns/v_gap.dart';
import '../primitives/v_icon_box.dart';
import '../primitives/v_text.dart';
import '../theme/v_color_scheme.dart';
import '../tokens/v_borders.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_shadows.dart';
import '../tokens/v_spacing.dart';

const double _kCardInset = VSpacing.md;

/// Surface shell for grouped content.
///
/// When composing with [VCardHeader] / [VCardContent] / [VCardFooter], set
/// [padding] to [EdgeInsets.zero] so each section owns its inset (shadcn-style).
///
/// - [tone] resolves background tint + border color.
/// - [emphasis] resolves elevation shadow (`subtle` none, `medium` e1, `strong` e2).
/// - [elevated] is a legacy alias: when `true`, shadow is at least [VShadows.e1].
class VCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  /// Legacy alias for medium elevation. Prefer [emphasis] instead.
  @Deprecated('Use emphasis: VComponentEmphasis.medium instead')
  final bool elevated;

  final VComponentTone? tone;
  final VComponentEmphasis emphasis;
  final Color? backgroundColor;
  final Border? border;
  final double? borderRadius;

  const VCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    @Deprecated('Use emphasis: VComponentEmphasis.medium instead')
    this.elevated = false,
    this.tone,
    this.emphasis = VComponentEmphasis.subtle,
    this.backgroundColor,
    this.border,
    this.borderRadius,
  });

  (Color background, Color borderColor) _toneColors(VColorScheme colors) {
    return switch (tone) {
      VComponentTone.primary => (colors.surfaceBrand, colors.primary),
      VComponentTone.success => (colors.successBg, colors.success),
      VComponentTone.warning => (colors.warningBg, colors.warning),
      VComponentTone.danger => (colors.dangerBg, colors.danger),
      VComponentTone.info => (colors.infoBg, colors.info),
      VComponentTone.neutral || null => (colors.surface, colors.borderDefault),
    };
  }

  List<BoxShadow>? _resolveShadow() {
    final fromEmphasis = switch (emphasis) {
      VComponentEmphasis.subtle => null,
      VComponentEmphasis.medium => VShadows.e1,
      VComponentEmphasis.strong => VShadows.e2,
    };
    // ignore: deprecated_member_use_from_same_package
    if (elevated && fromEmphasis == null) {
      return VShadows.e1;
    }
    return fromEmphasis;
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final (toneBg, toneBorder) = _toneColors(dynamicColors);
    final resolvedRadius = borderRadius ?? VRadius.card;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? toneBg,
        borderRadius: BorderRadius.circular(resolvedRadius),
        border: border ?? VBorders.all(toneBorder),
        boxShadow: _resolveShadow(),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: onTap,
          borderRadius: BorderRadius.circular(resolvedRadius),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(_kCardInset),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Header row: optional title block and trailing action.
class VCardHeader extends StatelessWidget {
  const VCardHeader({
    super.key,
    this.title,
    this.action,
  });

  final Widget? title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _kCardInset,
        _kCardInset,
        _kCardInset,
        VSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) Expanded(child: title!),
          if (action != null) ...[
            const VGap.horizontalSm(),
            action!,
          ],
        ],
      ),
    );
  }
}

/// Decorative icon for card composition, wrapping [VIconBox].
class VCardIcon extends StatelessWidget {
  const VCardIcon({
    super.key,
    this.icon,
    this.iconData,
    this.tone,
    this.size = 40,
  });

  final VIcons? icon;
  final IconData? iconData;
  final VComponentTone? tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    return VIconBox(
      icon: icon,
      iconData: iconData,
      tone: tone,
      size: size,
      iconSize: size * 0.5,
    );
  }
}

/// Card title with optional description (shadcn CardTitle + CardDescription).
class VCardTitle extends StatelessWidget {
  const VCardTitle(
    this.title, {
    super.key,
    this.description,
  });

  final String title;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        VText(title, variant: VTextVariant.headingH4),
        if (description != null && description!.isNotEmpty) ...[
          const VGap.xs(),
          VText(
            description!,
            variant: VTextVariant.bodySmall,
            color: colors.textSecondary,
          ),
        ],
      ],
    );
  }
}

/// Trailing action slot for [VCardHeader] (shadcn CardAction).
class VCardAction extends StatelessWidget {
  const VCardAction({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: child,
    );
  }
}

/// Main body area (shadcn CardContent).
class VCardContent extends StatelessWidget {
  const VCardContent({
    super.key,
    required this.child,
    this.denseTop = true,
  });

  final Widget child;

  /// When true (default), top padding is 0 for tighter spacing after [VCardHeader].
  final bool denseTop;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        _kCardInset,
        denseTop ? 0 : _kCardInset,
        _kCardInset,
        _kCardInset,
      ),
      child: child,
    );
  }
}

/// Footer / CTA row (shadcn CardFooter).
class VCardFooter extends StatelessWidget {
  const VCardFooter({
    super.key,
    required this.child,
    this.alignment = MainAxisAlignment.end,
  });

  final Widget child;
  final MainAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _kCardInset,
        VSpacing.sm,
        _kCardInset,
        _kCardInset,
      ),
      child: Row(
        mainAxisAlignment: alignment,
        children: [child],
      ),
    );
  }
}
