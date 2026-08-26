import 'package:flutter/material.dart';

import '../foundation/v_component_contracts.dart';
import '../foundation/v_context_extensions.dart';
import '../foundation/v_inspector_scope.dart';
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

Color? _cardToneForeground(VColorScheme colors, VComponentTone? tone) {
  if (tone == null) return null;
  return switch (tone) {
    VComponentTone.primary => colors.primary,
    VComponentTone.success => colors.success,
    VComponentTone.warning => colors.warning,
    VComponentTone.danger => colors.danger,
    VComponentTone.info => colors.info,
    VComponentTone.neutral => colors.textPrimary,
  };
}

/// Resolves [_VCardScope]. Throws if used outside [VCard].
_VCardScope _resolveCardScope(
  BuildContext context, {
  required String widgetName,
}) {
  final scope = _VCardScope.maybeOf(context);
  if (scope == null) {
    throw FlutterError.fromParts(<DiagnosticsNode>[
      ErrorSummary('$widgetName must be used within a VCard.'),
      ErrorDescription(
        'Place $widgetName inside VCard so it can inherit tone '
        '(and keep card composition consistent).',
      ),
    ]);
  }
  return scope;
}

/// Resolves [_VCardHeaderScope]. Throws if used outside [VCardHeader].
_VCardHeaderScope _resolveCardHeaderScope(
  BuildContext context, {
  required String widgetName,
}) {
  final scope = _VCardHeaderScope.maybeOf(context);
  if (scope == null) {
    throw FlutterError.fromParts(<DiagnosticsNode>[
      ErrorSummary('$widgetName must be used within a VCardHeader.'),
      ErrorDescription(
        'Place $widgetName inside VCardHeader so it can inherit tone '
        '(and keep card composition consistent).',
      ),
    ]);
  }
  return scope;
}

/// Provides [tone] to [VCardHeader] / [VCardContent] / [VCardFooter] / [VCardIcon].
class _VCardScope extends InheritedWidget {
  const _VCardScope({
    required this.tone,
    required super.child,
  });

  final VComponentTone? tone;

  static _VCardScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_VCardScope>();
  }

  @override
  bool updateShouldNotify(covariant _VCardScope oldWidget) {
    return tone != oldWidget.tone;
  }
}

/// Provides [tone] to [VCardTitle] / [VCardAction].
class _VCardHeaderScope extends InheritedWidget {
  const _VCardHeaderScope({
    required this.tone,
    required super.child,
  });

  final VComponentTone? tone;

  static _VCardHeaderScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_VCardHeaderScope>();
  }

  @override
  bool updateShouldNotify(covariant _VCardHeaderScope oldWidget) {
    return tone != oldWidget.tone;
  }
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
/// (runtime [FlutterError] otherwise). Tone flows from card → header → title/icon;
/// each child may override with its own [tone].
///
/// When composing with sections, set [padding] to [EdgeInsets.zero] so each
/// section owns its inset (shadcn-style).
///
/// - [tone] resolves background tint + border color (and inherits to children).
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
    @Deprecated('Use emphasis: VComponentEmphasis.medium instead') this.elevated = false,
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

    return vInspectorHide(
      _VCardScope(
        tone: tone,
        child: Container(
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
                child: vInspectorShow(child),
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
    final cardScope = _resolveCardScope(context, widgetName: 'VCardHeader');
    final resolvedTone = tone ?? cardScope.tone;

    return vInspectorHide(
      _VCardHeaderScope(
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

  /// Overrides [VCard.tone] when set.
  final VComponentTone? tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scope = _resolveCardScope(context, widgetName: 'VCardIcon');
    final resolvedTone = tone ?? scope.tone;

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

  /// Overrides [VCardHeader.tone] when set.
  final VComponentTone? tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final scope = _resolveCardHeaderScope(context, widgetName: 'VCardTitle');
    final resolvedTone = tone ?? scope.tone;

    return vInspectorHide(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          VText(
            title,
            variant: VTextVariant.headingH4,
            color: _cardToneForeground(colors, resolvedTone),
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
    _resolveCardHeaderScope(context, widgetName: 'VCardAction');
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
    _resolveCardScope(context, widgetName: 'VCardContent');
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
    _resolveCardScope(context, widgetName: 'VCardFooter');
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
