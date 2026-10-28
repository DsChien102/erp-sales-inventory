import 'package:flutter/material.dart';

import '../foundation/v_component_contracts.dart';
import '../foundation/v_component_scope.dart';
import '../foundation/v_context_extensions.dart';
import '../foundation/v_inspector_scope.dart';
import '../foundations/icons/v_icons.dart';
import '../patterns/v_gap.dart';
import '../primitives/v_icon_box.dart';
import '../primitives/v_text.dart';
import '../theme/v_color_scheme.dart';
import '../tokens/v_borders.dart';
import '../tokens/v_opacity.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_shadows.dart';
import '../tokens/v_spacing.dart';

const double _kCardInset = VSpacing.md;

/// Structural marker: [VCardHeader] / [VCardContent] / [VCardFooter] / [VCardIcon].
class _VCardAncestry extends InheritedWidget {
  const _VCardAncestry({required super.child});

  @override
  bool updateShouldNotify(covariant _VCardAncestry oldWidget) => false;
}

/// Structural marker: [VCardTitle] / [VCardAction].
class _VCardHeaderAncestry extends InheritedWidget {
  const _VCardHeaderAncestry({required super.child});

  @override
  bool updateShouldNotify(covariant _VCardHeaderAncestry oldWidget) => false;
}

void _requireCard(BuildContext context, {required String widgetName}) {
  requireAncestor<_VCardAncestry>(
    context,
    widgetName: widgetName,
    ancestorName: 'VCard',
  );
}

void _requireCardHeader(BuildContext context, {required String widgetName}) {
  requireAncestor<_VCardHeaderAncestry>(
    context,
    widgetName: widgetName,
    ancestorName: 'VCardHeader',
  );
}

/// Surface shell for grouped content.
///
/// Prefer composition:
/// ```dart
/// VCard(
///   padding: EdgeInsets.zero,
///   tone: VComponentTone.warning,
///   child: Column(
///     children: [
///       VCardHeader(
///         title: VCardTitle('Title', description: 'Subtitle'),
///         action: VCardAction(child: Text('Edit')),
///       ),
///       VCardContent(child: VCardIcon(iconData: Icons.store)),
///       VCardFooter(child: Text('Save')),
///     ],
///   ),
/// )
/// ```
///
/// [VCardHeader] / [VCardContent] / [VCardFooter] / [VCardIcon] must live under
/// [VCard]; [VCardTitle] / [VCardAction] must live under [VCardHeader]
/// (runtime [FlutterError] otherwise). Tone flows via [VComponentScope];
/// each child may override with its own [tone].
///
/// When composing with sections, set [padding] to [EdgeInsets.zero] so each
/// section owns its inset (shadcn-style).
///
/// - [tone] resolves background tint + border color (and inherits to children).
/// - [emphasis] resolves elevation shadow (`subtle` none, `medium` e1, `strong` e2).
/// - [enabled] soft-inherits via [VComponentScope]; when false, border is
///   [VColorScheme.borderDefault], [onTap] is ignored, and children inherit
///   `enabled: false`.
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

  /// Soft-inherit via [VComponentScope.resolveEnabled]. Null = no local opinion.
  final bool? enabled;

  final Color? backgroundColor;
  final Border? border;
  final double? borderRadius;

  const VCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    @Deprecated('Use emphasis: VComponentEmphasis.medium instead') this.elevated = false,
    this.tone,
    this.emphasis = VComponentEmphasis.subtle,
    this.enabled,
    this.backgroundColor,
    this.border,
    this.borderRadius,
  });

  (Color background, Color borderColor) _toneColors(VColorScheme colors) {
    return switch (tone) {
      VComponentTone.primary => (colors.surfaceBrand, colors.borderBrand),
      VComponentTone.success => (colors.successBg, colors.success),
      VComponentTone.warning => (colors.warningBg, colors.warning),
      VComponentTone.danger => (colors.dangerBg, colors.danger),
      VComponentTone.info => (colors.infoBg, colors.info),
      VComponentTone.neutral || null => (colors.surface, colors.borderStrong),
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
    final isEnabled = VComponentScope.resolveEnabled(context, local: enabled);
    final (toneBg, toneBorder) = _toneColors(dynamicColors);
    final resolvedRadius = borderRadius ?? VRadius.card;

    return vInspectorHide(
      _VCardAncestry(
        child: VComponentScope(
          tone: tone,
          enabled: isEnabled ? enabled : false,
          child: vDisabledOpacity(
            enabled: isEnabled,
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor ?? toneBg,
                borderRadius: BorderRadius.circular(resolvedRadius),
                border: border ?? VBorders.all(toneBorder),
                boxShadow: _resolveShadow(),
              ),
              child: Material(
                color: Colors.transparent,
                child: Semantics(
                  button: onTap != null,
                  enabled: isEnabled,
                  child: InkWell(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: isEnabled ? onTap : null,
                    borderRadius: BorderRadius.circular(resolvedRadius),
                    child: Padding(
                      padding: padding ?? const EdgeInsets.all(_kCardInset),
                      child: vInspectorShow(child),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Header row: optional title block and trailing action.
///
/// Must be a descendant of [VCard]. Set [tone] once; [VCardTitle] inherits it
/// unless it passes its own [VCardTitle.tone]. Falls back to [VCard.tone].
class VCardHeader extends StatelessWidget {
  const VCardHeader({
    super.key,
    this.title,
    this.action,
    this.padding,
    this.tone,
  });

  final Widget? title;
  final Widget? action;
  final EdgeInsetsGeometry? padding;

  /// Overrides [VCard.tone] for header descendants when set.
  final VComponentTone? tone;

  @override
  Widget build(BuildContext context) {
    _requireCard(context, widgetName: 'VCardHeader');
    final resolvedTone = VComponentScope.resolveTone(context, local: tone);

    return vInspectorHide(
      _VCardHeaderAncestry(
        child: VComponentScope(
          tone: resolvedTone,
          child: Padding(
            padding:
                padding ??
                const EdgeInsets.fromLTRB(
                  _kCardInset,
                  _kCardInset,
                  _kCardInset,
                  VSpacing.sm,
                ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) Expanded(child: vInspectorShow(title!)),
                if (action != null) ...[
                  const VGap.horizontalSm(),
                  vInspectorShow(action!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Decorative icon for card composition, wrapping [VIconBox].
///
/// Must be a descendant of [VCard]. Inherits [VCard.tone] unless [tone] is set.
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

  /// Overrides ambient [VComponentScope.tone] when set.
  final VComponentTone? tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    _requireCard(context, widgetName: 'VCardIcon');
    final resolvedTone = VComponentScope.resolveTone(context, local: tone);

    return vInspectorHide(
      VIconBox(
        icon: icon,
        iconData: iconData,
        tone: resolvedTone,
        size: size,
        iconSize: size * 0.5,
      ),
    );
  }
}

/// Card title with optional description (shadcn CardTitle + CardDescription).
///
/// Must be a descendant of [VCardHeader]. Inherits header tone unless [tone] is set.
class VCardTitle extends StatelessWidget {
  const VCardTitle(
    this.title, {
    super.key,
    this.description,
    this.tone,
  });

  final String title;
  final String? description;

  /// Overrides ambient [VComponentScope.tone] when set.
  final VComponentTone? tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    _requireCardHeader(context, widgetName: 'VCardTitle');

    return vInspectorHide(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          VText(
            title,
            variant: VTextVariant.headingH4,
            tone: tone,
          ),
          if (description != null && description!.isNotEmpty) ...[
            const VGap.xs(),
            VText(
              description!,
              variant: VTextVariant.bodySmall,
              color: colors.textSecondary,
            ),
          ],
        ],
      ),
    );
  }
}

/// Trailing action slot for [VCardHeader] (shadcn CardAction).
///
/// Must be a descendant of [VCardHeader].
class VCardAction extends StatelessWidget {
  const VCardAction({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    _requireCardHeader(context, widgetName: 'VCardAction');
    return vInspectorHide(
      Align(
        alignment: Alignment.centerRight,
        child: vInspectorShow(child),
      ),
    );
  }
}

/// Main body area (shadcn CardContent).
///
/// Must be a descendant of [VCard].
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
    _requireCard(context, widgetName: 'VCardContent');
    return vInspectorHide(
      Padding(
        padding: EdgeInsets.fromLTRB(
          _kCardInset,
          denseTop ? 0 : _kCardInset,
          _kCardInset,
          _kCardInset,
        ),
        child: vInspectorShow(child),
      ),
    );
  }
}

/// Footer / CTA row (shadcn CardFooter).
///
/// Must be a descendant of [VCard].
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
    _requireCard(context, widgetName: 'VCardFooter');
    return vInspectorHide(
      Padding(
        padding: const EdgeInsets.fromLTRB(
          _kCardInset,
          VSpacing.sm,
          _kCardInset,
          _kCardInset,
        ),
        child: Row(
          mainAxisAlignment: alignment,
          children: [vInspectorShow(child)],
        ),
      ),
    );
  }
}
