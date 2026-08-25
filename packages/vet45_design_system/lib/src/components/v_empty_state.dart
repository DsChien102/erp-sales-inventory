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
import '../tokens/v_spacing.dart';
import 'v_button.dart';

/// How [VEmptyMedia] presents its content.
enum VEmptyMediaVariant {
  /// Wraps icon / child in a muted icon box (shadcn `variant="icon"`).
  icon,

  /// Renders [VEmptyMedia.child] as-is (avatar, illustration, …).
  plain,
}

Color? _emptyToneForeground(VColorScheme colors, VComponentTone? tone) {
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

/// Resolves scope from local override, then [_VEmptyHeaderScope] scope.
///
/// Throws if used outside [VEmptyHeader].
_VEmptyHeaderScope _resolveEmptyHeaderScope(
  BuildContext context, {
  required String widgetName,
}) {
  final scope = _VEmptyHeaderScope.maybeOf(context);
  if (scope == null) {
    throw FlutterError.fromParts(<DiagnosticsNode>[
      ErrorSummary('$widgetName must be used within a VEmptyHeader.'),
      ErrorDescription(
        'Place $widgetName inside VEmptyHeader so it can inherit tone '
        '(and keep empty-state composition consistent).',
      ),
    ]);
  }
  return scope;
}

/// Empty-state shell (shadcn Empty).
///
/// Prefer composition:
/// ```dart
/// VEmptyState(
///   bordered: true,
///   child: Column(
///     mainAxisSize: MainAxisSize.min,
///     children: [
///       VEmptyHeader(
///         tone: VComponentTone.warning,
///         children: [
///           VEmptyMedia(iconData: Icons.inbox_outlined),
///           const VEmptyTitle('No data'),
///           const VEmptyDescription('Nothing here yet.'),
///         ],
///       ),
///       VEmptyContent(child: VButton(label: 'Add', onPressed: () {})),
///     ],
///   ),
/// )
/// ```
///
/// [VEmptyMedia] / [VEmptyTitle] / [VEmptyDescription] must live under
/// [VEmptyHeader] (runtime [FlutterError] otherwise). Tone flows from the
/// header; each child may override with its own [tone].
///
/// Flat `title` / `icon*` / `actionLabel` args remain for existing call sites.
class VEmptyState extends StatelessWidget {
  /// Composition shell. When [child] is null, builds from legacy flat fields.
  const VEmptyState({
    super.key,
    this.child,
    this.bordered = false,
    this.filled = false,
    this.backgroundColor,
    this.border,
    this.borderRadius,
    this.padding,
    this.semanticLabel,
    this.iconEmoji,
    this.icon,
    this.iconData,
    this.title,
    this.description,
    this.actionLabel,
    this.actionLeadingIcon,
    this.onActionPressed,
    this.tone,
    this.emphasis = VComponentEmphasis.medium,
  }) : assert(
         child != null ||
             (title != null && (iconEmoji != null || icon != null || iconData != null)),
         'Provide child (composition) or title + icon/iconData/iconEmoji (legacy)',
       );

  /// Preferred: [VEmptyHeader] + [VEmptyContent] tree.
  final Widget? child;

  /// When true, draws a default outline border (opt-in; shadcn outline).
  final bool bordered;

  /// When true, fills with a muted surface background (opt-in).
  final bool filled;

  final Color? backgroundColor;
  final Border? border;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final String? semanticLabel;

  // ── Legacy flat API (kept for ERP call sites / tests) ───────────────────

  final String? iconEmoji;
  final VIcons? icon;
  final IconData? iconData;
  final String? title;
  final String? description;
  final String? actionLabel;
  final Widget? actionLeadingIcon;
  final VoidCallback? onActionPressed;
  final VComponentTone? tone;
  final VComponentEmphasis emphasis;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final resolvedRadius = borderRadius ?? VRadius.card;
    final resolvedPadding = padding ?? const EdgeInsets.all(VSpacing.lg);

    final Color? bg = backgroundColor ?? (filled ? colors.surfaceAlt : null);
    final Border? resolvedBorder = border ?? (bordered ? VBorders.all(colors.borderDefault) : null);

    final hasDecoration = bg != null || resolvedBorder != null;

    final content = child ?? _legacyContent();

    final body = Padding(
      padding: resolvedPadding,
      child: Align(
        alignment: Alignment.center,
        child: vInspectorShow(content),
      ),
    );

    return vInspectorHide(
      Semantics(
        label: semanticLabel ?? title,
        child: hasDecoration
            ? DecoratedBox(
                key: const ValueKey<String>('v_empty_state_shell'),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(resolvedRadius),
                  border: resolvedBorder,
                ),
                child: body,
              )
            : body,
      ),
    );
  }

  Widget _legacyContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        VEmptyHeader(
          tone: tone,
          children: [
            VEmptyMedia(
              icon: icon,
              iconData: iconData,
              emoji: iconEmoji,
            ),
            VEmptyTitle(title!),
            if (description != null) VEmptyDescription(description!),
          ],
        ),
        if (actionLabel != null && onActionPressed != null) ...[
          const VGap.xl(),
          VEmptyContent(
            child: VButton(
              label: actionLabel!,
              onPressed: onActionPressed!,
              leadingIcon: actionLeadingIcon,
              size: VButtonSize.medium,
              emphasis: emphasis,
              tone: tone == VComponentTone.primary ? VComponentTone.primary : null,
            ),
          ),
        ],
      ],
    );
  }
}

/// Provides [tone] to [VEmptyMedia] / [VEmptyTitle] / [VEmptyDescription].
class _VEmptyHeaderScope extends InheritedWidget {
  const _VEmptyHeaderScope({
    required this.tone,
    required super.child,
  });

  final VComponentTone? tone;

  static _VEmptyHeaderScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_VEmptyHeaderScope>();
  }

  @override
  bool updateShouldNotify(covariant _VEmptyHeaderScope oldWidget) {
    return tone != oldWidget.tone;
  }
}

/// Groups media, title, and description (shadcn EmptyHeader).
///
/// Set [tone] once; descendants inherit it unless they pass their own [tone].
class VEmptyHeader extends StatelessWidget {
  const VEmptyHeader({
    super.key,
    required this.children,
    this.tone,
  });

  final List<Widget> children;
  final VComponentTone? tone;

  @override
  Widget build(BuildContext context) {
    return vInspectorHide(
      _VEmptyHeaderScope(
        tone: tone,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) i == 1 ? const VGap.md() : const VGap.xs(),
                vInspectorShow(children[i]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Media slot: icon box, emoji, or arbitrary widget (shadcn EmptyMedia).
///
/// Must be a descendant of [VEmptyHeader].
class VEmptyMedia extends StatelessWidget {
  const VEmptyMedia({
    super.key,
    this.child,
    this.icon,
    this.iconData,
    this.emoji,
    this.variant = VEmptyMediaVariant.icon,
    this.tone,
    this.size = 64,
  }) : assert(
         child != null || icon != null || iconData != null || emoji != null,
         'Provide child, icon, iconData, or emoji',
       );

  final Widget? child;
  final VIcons? icon;
  final IconData? iconData;
  final String? emoji;
  final VEmptyMediaVariant variant;

  /// Overrides [VEmptyHeader.tone] when set.
  final VComponentTone? tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final scope = _resolveEmptyHeaderScope(
      context,
      widgetName: 'VEmptyMedia',
    );
    final resolvedTone = tone ?? scope.tone;

    if (emoji != null && child == null && icon == null && iconData == null) {
      return vInspectorHide(
        Text(emoji!, style: const TextStyle(fontSize: 48)),
      );
    }

    if (variant == VEmptyMediaVariant.plain) {
      if (child != null) return vInspectorShow(child!);
      return vInspectorHide(
        VIconBox(
          icon: icon,
          iconData: icon == null ? iconData : null,
          size: size,
          iconSize: size * 0.44,
          tone: resolvedTone,
        ),
      );
    }

    if (child != null) {
      return vInspectorHide(
        Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.surfaceAlt,
            borderRadius: BorderRadius.circular(VRadius.r16),
          ),
          child: vInspectorShow(child!),
        ),
      );
    }

    return vInspectorHide(
      VIconBox(
        icon: icon,
        iconData: icon == null ? iconData : null,
        size: size,
        iconSize: size * 0.44,
        tone: resolvedTone ?? VComponentTone.neutral,
        backgroundColor: resolvedTone == null ? colors.surfaceAlt : null,
        iconColor: resolvedTone == null ? colors.textSecondary : null,
        borderRadius: VRadius.r16,
      ),
    );
  }
}

/// Title line (shadcn EmptyTitle).
///
/// Must be a descendant of [VEmptyHeader].
class VEmptyTitle extends StatelessWidget {
  const VEmptyTitle(
    this.text, {
    super.key,
    this.tone,
  });

  final String text;

  /// Overrides [VEmptyHeader.tone] when set.
  final VComponentTone? tone;

  @override
  Widget build(BuildContext context) {
    final scope = _resolveEmptyHeaderScope(
      context,
      widgetName: 'VEmptyTitle',
    );
    final resolvedTone = tone ?? scope.tone;
    return vInspectorHide(
      VText(
        text,
        variant: VTextVariant.headingH3,
        color: _emptyToneForeground(context.vColors, resolvedTone),
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Description line (shadcn EmptyDescription).
///
/// Must be a descendant of [VEmptyHeader].
class VEmptyDescription extends StatelessWidget {
  const VEmptyDescription(
    this.text, {
    super.key,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    _resolveEmptyHeaderScope(
      context,
      widgetName: 'VEmptyDescription',
    );
    return vInspectorHide(
      VText(
        text,
        variant: VTextVariant.bodyDefault,
        color: colors.textSecondary,
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// CTA / extra content slot (shadcn EmptyContent).
class VEmptyContent extends StatelessWidget {
  const VEmptyContent({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return vInspectorHide(
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: vInspectorShow(child),
      ),
    );
  }
}
