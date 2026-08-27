import 'package:flutter/material.dart';

import '../foundation/v_component_contracts.dart';
import '../foundation/v_component_scope.dart';
import '../foundation/v_context_extensions.dart';
import '../foundation/v_inspector_scope.dart';
import '../foundations/icons/v_icons.dart';
import '../patterns/v_gap.dart';
import '../primitives/v_icon_box.dart';
import '../primitives/v_text.dart';
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

/// Structural marker: [VEmptyMedia] / [VEmptyTitle] / [VEmptyDescription].
class _VEmptyHeaderAncestry extends InheritedWidget {
  const _VEmptyHeaderAncestry({required super.child});

  @override
  bool updateShouldNotify(covariant _VEmptyHeaderAncestry oldWidget) => false;
}

void _requireEmptyHeader(BuildContext context, {required String widgetName}) {
  requireAncestor<_VEmptyHeaderAncestry>(
    context,
    widgetName: widgetName,
    ancestorName: 'VEmptyHeader',
  );
}

/// Empty-state shell (shadcn Empty).
///
/// Prefer composition:
/// ```dart
/// VEmptyState(
///   bordered: true,
///   tone: VComponentTone.warning,
///   child: Column(
///     mainAxisSize: MainAxisSize.min,
///     children: [
///       VEmptyHeader(
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
/// [VEmptyHeader] (runtime [FlutterError] otherwise). [tone] cascades to
/// descendants via [VComponentScope]; [VEmptyHeader] / children may override.
///
/// Flat `title` / `icon*` / `actionLabel` args are deprecated — prefer [child].
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
    this.tone,
    @Deprecated(
      'Use child with VEmptyHeader / VEmptyMedia / VEmptyTitle instead',
    )
    this.iconEmoji,
    @Deprecated(
      'Use child with VEmptyHeader / VEmptyMedia / VEmptyTitle instead',
    )
    this.icon,
    @Deprecated(
      'Use child with VEmptyHeader / VEmptyMedia / VEmptyTitle instead',
    )
    this.iconData,
    @Deprecated(
      'Use child with VEmptyHeader / VEmptyMedia / VEmptyTitle instead',
    )
    this.title,
    @Deprecated(
      'Use child with VEmptyHeader / VEmptyDescription instead',
    )
    this.description,
    @Deprecated(
      'Use child with VEmptyContent + VButton instead',
    )
    this.actionLabel,
    @Deprecated(
      'Use child with VEmptyContent + VButton instead',
    )
    this.actionLeadingIcon,
    @Deprecated(
      'Use child with VEmptyContent + VButton instead',
    )
    this.onActionPressed,
    @Deprecated(
      'Pass emphasis on VButton inside VEmptyContent instead',
    )
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

  /// Cascades to descendants via [VComponentScope] (header / media / title /
  /// buttons, …). Header or child may override locally.
  final VComponentTone? tone;

  // ── Legacy flat API (deprecated — prefer [child] composition) ───────────

  @Deprecated(
    'Use child with VEmptyHeader / VEmptyMedia / VEmptyTitle instead',
  )
  final String? iconEmoji;

  @Deprecated(
    'Use child with VEmptyHeader / VEmptyMedia / VEmptyTitle instead',
  )
  final VIcons? icon;

  @Deprecated(
    'Use child with VEmptyHeader / VEmptyMedia / VEmptyTitle instead',
  )
  final IconData? iconData;

  @Deprecated(
    'Use child with VEmptyHeader / VEmptyMedia / VEmptyTitle instead',
  )
  final String? title;

  @Deprecated(
    'Use child with VEmptyHeader / VEmptyDescription instead',
  )
  final String? description;

  @Deprecated(
    'Use child with VEmptyContent + VButton instead',
  )
  final String? actionLabel;

  @Deprecated(
    'Use child with VEmptyContent + VButton instead',
  )
  final Widget? actionLeadingIcon;

  @Deprecated(
    'Use child with VEmptyContent + VButton instead',
  )
  final VoidCallback? onActionPressed;

  @Deprecated(
    'Pass emphasis on VButton inside VEmptyContent instead',
  )
  final VComponentEmphasis emphasis;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final resolvedRadius = borderRadius ?? VRadius.card;
    final resolvedPadding = padding ?? const EdgeInsets.all(VSpacing.lg);

    final Color? bg = backgroundColor ?? (filled ? colors.surfaceAlt : null);
    final Border? resolvedBorder = border ?? (bordered ? VBorders.all(colors.borderDefault) : null);

    final hasDecoration = bg != null || resolvedBorder != null;

    // ignore: deprecated_member_use_from_same_package
    final content = child ?? _legacyContent();

    final body = Padding(
      padding: resolvedPadding,
      child: Align(
        alignment: Alignment.center,
        child: vInspectorShow(content),
      ),
    );

    final shell = hasDecoration
        ? DecoratedBox(
            key: const ValueKey<String>('v_empty_state_shell'),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(resolvedRadius),
              border: resolvedBorder,
            ),
            child: body,
          )
        : body;

    return vInspectorHide(
      VComponentScope(
        tone: tone,
        child: Semantics(
          // ignore: deprecated_member_use_from_same_package
          label: semanticLabel ?? title,
          child: shell,
        ),
      ),
    );
  }

  Widget _legacyContent() {
    // ignore: deprecated_member_use_from_same_package
    final legacyEmphasis = emphasis;
    // ignore: deprecated_member_use_from_same_package
    final legacyTitle = title!;
    // ignore: deprecated_member_use_from_same_package
    final legacyDescription = description;
    // ignore: deprecated_member_use_from_same_package
    final legacyActionLabel = actionLabel;
    // ignore: deprecated_member_use_from_same_package
    final legacyOnAction = onActionPressed;
    // ignore: deprecated_member_use_from_same_package
    final legacyActionLeading = actionLeadingIcon;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        VEmptyHeader(
          children: [
            VEmptyMedia(
              // ignore: deprecated_member_use_from_same_package
              icon: icon,
              // ignore: deprecated_member_use_from_same_package
              iconData: iconData,
              // ignore: deprecated_member_use_from_same_package
              emoji: iconEmoji,
            ),
            VEmptyTitle(legacyTitle),
            if (legacyDescription != null) VEmptyDescription(legacyDescription),
          ],
        ),
        if (legacyActionLabel != null && legacyOnAction != null) ...[
          const VGap.xl(),
          VEmptyContent(
            child: VButton(
              label: legacyActionLabel,
              onPressed: legacyOnAction,
              leadingIcon: legacyActionLeading,
              size: VButtonSize.medium,
              emphasis: legacyEmphasis,
            ),
          ),
        ],
      ],
    );
  }
}

/// Groups media, title, and description (shadcn EmptyHeader).
///
/// [tone] overrides ambient [VEmptyState.tone] for header descendants; falls
/// back to [VComponentScope] from the shell when null.
class VEmptyHeader extends StatelessWidget {
  const VEmptyHeader({
    super.key,
    required this.children,
    this.tone,
  });

  final List<Widget> children;

  /// Overrides [VEmptyState.tone] for header descendants when set.
  final VComponentTone? tone;

  @override
  Widget build(BuildContext context) {
    final resolvedTone = VComponentScope.resolveTone(context, local: tone);

    return vInspectorHide(
      _VEmptyHeaderAncestry(
        child: VComponentScope(
          tone: resolvedTone,
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

  /// Overrides ambient [VComponentScope.tone] when set.
  final VComponentTone? tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    _requireEmptyHeader(context, widgetName: 'VEmptyMedia');
    final resolvedTone = VComponentScope.resolveTone(context, local: tone);

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

  /// Overrides ambient [VComponentScope.tone] when set.
  final VComponentTone? tone;

  @override
  Widget build(BuildContext context) {
    _requireEmptyHeader(context, widgetName: 'VEmptyTitle');
    return vInspectorHide(
      VText(
        text,
        variant: VTextVariant.headingH3,
        tone: tone,
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
    _requireEmptyHeader(context, widgetName: 'VEmptyDescription');
    // NOTE: don't inherit tone from parent for description
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
