import 'package:flutter/material.dart';

import '../foundation/v_component_contracts.dart';
import '../foundation/v_component_scope.dart';
import '../foundation/v_context_extensions.dart';
import '../foundation/v_inspector_scope.dart';
import '../foundations/icons/v_icons.dart';
import '../patterns/v_gap.dart';
import '../primitives/v_icon.dart';
import '../theme/v_color_scheme.dart';
import '../tokens/v_opacity.dart';
import '../tokens/v_spacing.dart';
import '../tokens/v_typography.dart';

enum VTabsOrientation { horizontal, vertical }

enum VTabsListVariant { line, plain }

/// Shared tab state for [VTabsList], [VTabsTrigger], and [VTabsContent].
class _VTabsScope extends InheritedWidget {
  const _VTabsScope({
    required this.selectedIndex,
    required this.onTabSelected,
    required this.orientation,
    required this.tone,
    required this.emphasis,
    required this.disabledIndices,
    required this.semanticLabel,
    required super.child,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final VTabsOrientation orientation;
  final VComponentTone tone;
  final VComponentEmphasis emphasis;
  final Set<int>? disabledIndices;
  final String? semanticLabel;

  static _VTabsScope of(BuildContext context) {
    return requireAncestor<_VTabsScope>(
      context,
      widgetName: 'VTabs descendant',
      ancestorName: 'VTabs',
    );
  }

  bool isDisabled(int index) => disabledIndices?.contains(index) ?? false;

  @override
  bool updateShouldNotify(covariant _VTabsScope oldWidget) {
    return selectedIndex != oldWidget.selectedIndex ||
        orientation != oldWidget.orientation ||
        tone != oldWidget.tone ||
        emphasis != oldWidget.emphasis ||
        disabledIndices != oldWidget.disabledIndices ||
        semanticLabel != oldWidget.semanticLabel;
  }
}

/// Index assigned by [VTabsList] to each [VTabsTrigger].
class _VTabIndexScope extends InheritedWidget {
  const _VTabIndexScope({required this.index, required super.child});

  final int index;

  static int of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_VTabIndexScope>();
    if (scope == null) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('VTabsTrigger must be used within a VTabsList.'),
        ErrorDescription(
          'Place VTabsTrigger inside VTabsList so each tab receives an index.',
        ),
      ]);
    }
    return scope.index;
  }

  @override
  bool updateShouldNotify(covariant _VTabIndexScope oldWidget) {
    return index != oldWidget.index;
  }
}

/// Variant styling for [VTabsList]; read by [VTabsTrigger].
class _VTabsListVariantScope extends InheritedWidget {
  const _VTabsListVariantScope({
    required this.variant,
    required super.child,
  });

  final VTabsListVariant variant;

  static VTabsListVariant of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_VTabsListVariantScope>();
    return scope?.variant ?? VTabsListVariant.line;
  }

  @override
  bool updateShouldNotify(covariant _VTabsListVariantScope oldWidget) {
    return variant != oldWidget.variant;
  }
}

/// Layout hints for [VTabsTrigger] — equal flex when not scrollable.
class _VTabsListLayoutScope extends InheritedWidget {
  const _VTabsListLayoutScope({
    required this.fillsCrossAxis,
    required super.child,
  });

  /// When true, each trigger expands to the full cross-axis extent of the list.
  final bool fillsCrossAxis;

  static bool fillsCrossAxisOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_VTabsListLayoutScope>()?.fillsCrossAxis ??
        false;
  }

  @override
  bool updateShouldNotify(covariant _VTabsListLayoutScope oldWidget) {
    return fillsCrossAxis != oldWidget.fillsCrossAxis;
  }
}

void _requireTabs(BuildContext context, {required String widgetName}) {
  requireAncestor<_VTabsScope>(
    context,
    widgetName: widgetName,
    ancestorName: 'VTabs',
  );
}

Color _activeColorForTone(VColorScheme colors, VComponentTone tone) {
  return switch (tone) {
    VComponentTone.warning => colors.warning,
    VComponentTone.danger => colors.danger,
    VComponentTone.success => colors.success,
    VComponentTone.info => colors.info,
    _ => colors.primary,
  };
}

int? _nextEnabledIndex({
  required int from,
  required int count,
  required Set<int>? disabledIndices,
  required bool forward,
}) {
  if (count <= 0) return null;
  if (forward) {
    for (var i = from + 1; i < count; i++) {
      if (!(disabledIndices?.contains(i) ?? false)) return i;
    }
  } else {
    for (var i = from - 1; i >= 0; i--) {
      if (!(disabledIndices?.contains(i) ?? false)) return i;
    }
  }
  return null;
}

/// Root scope for tab navigation. Compose with [VTabsList] + [VTabsContent].
///
/// ```dart
/// VTabs(
///   selectedIndex: index,
///   onTabSelected: (i) => setState(() => index = i),
///   child: Column(
///     children: [
///       VTabsList(
///         children: [
///           VTabsTrigger(label: 'Overview'),
///           VTabsTrigger(label: 'Items'),
///         ],
///       ),
///       VTabsContent(
///         children: [
///           OverviewPage(),
///           ItemsPage(),
///         ],
///       ),
///     ],
///   ),
/// )
/// ```
class VTabs extends StatelessWidget {
  const VTabs({
    super.key,
    @Deprecated('Use VTabsList + VTabsTrigger inside child instead.') this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    this.child,
    this.orientation = VTabsOrientation.horizontal,
    @Deprecated('Use VTabsList(isScrollable:) inside child instead.') this.isScrollable = false,
    this.tone = VComponentTone.primary,
    this.emphasis = VComponentEmphasis.medium,
    this.disabledIndices,
    this.semanticLabel,
  }) : assert(
         tabs == null || child == null,
         'Provide either deprecated tabs or child composition, not both.',
       );

  @Deprecated('Use VTabsList + VTabsTrigger inside child instead.')
  final List<String>? tabs;

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final Widget? child;
  final VTabsOrientation orientation;

  @Deprecated('Use VTabsList(isScrollable:) inside child instead.')
  final bool isScrollable;

  final VComponentTone tone;
  final VComponentEmphasis emphasis;
  final Set<int>? disabledIndices;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final resolvedChild =
        child ??
        VTabsList(
          isScrollable: isScrollable,
          children: [
            for (final label in tabs!) VTabsTrigger(label: label),
          ],
        );

    return _VTabsScope(
      selectedIndex: selectedIndex,
      onTabSelected: onTabSelected,
      orientation: orientation,
      tone: tone,
      emphasis: emphasis,
      disabledIndices: disabledIndices,
      semanticLabel: semanticLabel,
      child: resolvedChild,
    );
  }
}

/// Tab bar chrome. Must be used inside [VTabs].
class VTabsList extends StatelessWidget {
  const VTabsList({
    super.key,
    required this.children,
    this.variant = VTabsListVariant.line,
    this.isScrollable = false,
  });

  final List<Widget> children;
  final VTabsListVariant variant;
  final bool isScrollable;

  void _handleSwipeEnd(
    BuildContext context,
    DragEndDetails details, {
    required bool horizontal,
  }) {
    if (isScrollable) return;

    final scope = _VTabsScope.of(context);
    final velocity = horizontal ? details.primaryVelocity ?? 0 : details.primaryVelocity ?? 0;
    if (velocity == 0) return;

    final forward = velocity < 0;
    final next = _nextEnabledIndex(
      from: scope.selectedIndex,
      count: children.length,
      disabledIndices: scope.disabledIndices,
      forward: forward,
    );
    if (next != null) {
      scope.onTabSelected(next);
    }
  }

  @override
  Widget build(BuildContext context) {
    _requireTabs(context, widgetName: 'VTabsList');

    final scope = _VTabsScope.of(context);
    final colors = context.vColors;
    final isHorizontal = scope.orientation == VTabsOrientation.horizontal;

    final indexedChildren = List<Widget>.generate(
      children.length,
      (index) => _VTabIndexScope(
        index: index,
        child: children[index],
      ),
    );

    Widget rowOrColumn = isHorizontal
        ? Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: isScrollable
                ? indexedChildren
                : indexedChildren.map((child) => Expanded(child: child)).toList(),
          )
        : IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: indexedChildren,
            ),
          );

    if (isScrollable && isHorizontal) {
      rowOrColumn = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: rowOrColumn,
      );
    }

    final borderSide = isHorizontal
        ? Border(
            bottom: BorderSide(color: colors.borderDefault, width: 1),
          )
        : Border(
            right: BorderSide(color: colors.borderDefault, width: 1),
          );

    Widget content = Container(
      decoration: BoxDecoration(border: borderSide),
      child: rowOrColumn,
    );

    if (!isScrollable) {
      content = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: isHorizontal
            ? (details) => _handleSwipeEnd(context, details, horizontal: true)
            : null,
        onVerticalDragEnd: !isHorizontal
            ? (details) => _handleSwipeEnd(context, details, horizontal: false)
            : null,
        child: content,
      );
    }

    return vInspectorHide(
      Semantics(
        label: scope.semanticLabel ?? 'Tabs',
        explicitChildNodes: true,
        child: _VTabsListLayoutScope(
          fillsCrossAxis: !isScrollable,
          child: _VTabsListVariantScope(
            variant: variant,
            child: content,
          ),
        ),
      ),
    );
  }
}

/// Single tab trigger. Must be used inside [VTabsList].
class VTabsTrigger extends StatelessWidget {
  const VTabsTrigger({
    super.key,
    required this.label,
    this.icon,
    this.trailing,
    this.enabled = true,
  });

  final String label;
  final VIcons? icon;
  final Widget? trailing;

  /// Local disable; also disabled when index is in [VTabs.disabledIndices].
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final index = _VTabIndexScope.of(context);
    final scope = _VTabsScope.of(context);
    final variant = _VTabsListVariantScope.of(context);
    final colors = context.vColors;
    final isSelected = index == scope.selectedIndex;
    final isDisabled = !enabled || scope.isDisabled(index);
    final activeColor = _activeColorForTone(colors, scope.tone);
    final indicatorWidth = scope.emphasis == VComponentEmphasis.strong ? 3.0 : 2.0;
    final isHorizontal = scope.orientation == VTabsOrientation.horizontal;

    final foreground = isSelected ? activeColor : colors.textSecondary;

    Border? indicatorBorder;
    if (variant == VTabsListVariant.line) {
      indicatorBorder = isHorizontal
          ? Border(
              bottom: BorderSide(
                color: isSelected ? activeColor : Colors.transparent,
                width: indicatorWidth,
              ),
            )
          : Border(
              right: BorderSide(
                color: isSelected ? activeColor : Colors.transparent,
                width: indicatorWidth,
              ),
            );
    }

    final fillsCrossAxis = _VTabsListLayoutScope.fillsCrossAxisOf(context);

    final labelWidget = Text(
      label,
      style: VTypography.bodyDefault.copyWith(
        fontWeight: FontWeight.w600,
        color: foreground,
      ),
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
    );

    return Semantics(
      button: true,
      selected: isSelected,
      enabled: !isDisabled,
      label: label,
      child: vDisabledOpacity(
        enabled: !isDisabled,
        child: InkWell(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: isDisabled ? null : () => scope.onTabSelected(index),
          child: Container(
            width: fillsCrossAxis ? double.infinity : null,
            padding: const EdgeInsets.symmetric(
              horizontal: VSpacing.space4,
              vertical: VSpacing.space3,
            ),
            decoration: BoxDecoration(border: indicatorBorder),
            child: Row(
              mainAxisSize: fillsCrossAxis ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  VIcon(
                    icon: icon,
                    weight: VIconWeight.medium,
                    size: 16,
                    color: foreground,
                  ),
                  const VGap.sm(axis: Axis.horizontal),
                ],
                if (fillsCrossAxis)
                  Flexible(
                    fit: FlexFit.loose,
                    child: labelWidget,
                  )
                else
                  labelWidget,
                if (trailing != null) ...[
                  const VGap.sm(axis: Axis.horizontal),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Swipeable tab body. Must be used inside [VTabs] within a [Column] or [Row].
class VTabsContent extends StatefulWidget {
  const VTabsContent({
    super.key,
    required this.children,
    this.swipeEnabled = true,
    this.expand = true,
    this.physics,
  });

  final List<Widget> children;
  final bool swipeEnabled;
  final bool expand;

  /// Overrides [swipeEnabled] when set.
  final ScrollPhysics? physics;

  @override
  State<VTabsContent> createState() => _VTabsContentState();
}

class _VTabsContentState extends State<VTabsContent> {
  PageController? _controller;
  int? _lastReportedIndex;
  bool _syncingFromScope = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = _VTabsScope.of(context);
    _controller ??= PageController(initialPage: scope.selectedIndex);
    _lastReportedIndex ??= scope.selectedIndex;
    _syncFromScope(scope);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _syncFromScope(_VTabsScope scope) {
    final controller = _controller;
    if (controller == null || !controller.hasClients) return;

    final target = scope.selectedIndex;
    if (target == _lastReportedIndex) return;

    final current = controller.page?.round() ?? controller.initialPage;
    if (current == target) {
      _lastReportedIndex = target;
      return;
    }

    _syncingFromScope = true;
    controller
        .animateToPage(
          target,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        )
        .whenComplete(() {
          if (mounted) {
            _syncingFromScope = false;
            _lastReportedIndex = target;
          }
        });
  }

  void _onPageChanged(int index) {
    if (_syncingFromScope) return;

    final scope = _VTabsScope.of(context);
    if (scope.isDisabled(index)) {
      final controller = _controller!;
      final from = _lastReportedIndex ?? scope.selectedIndex;
      final forward = index > from;
      final fallback = _nextEnabledIndex(
        from: from,
        count: widget.children.length,
        disabledIndices: scope.disabledIndices,
        forward: forward,
      );

      if (fallback != null && fallback != index) {
        _syncingFromScope = true;
        controller
            .animateToPage(
              fallback,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            )
            .whenComplete(() {
              if (mounted) {
                _syncingFromScope = false;
                _lastReportedIndex = fallback;
                scope.onTabSelected(fallback);
              }
            });
        return;
      }

      _syncingFromScope = true;
      controller
          .animateToPage(
            from,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          )
          .whenComplete(() {
            if (mounted) _syncingFromScope = false;
          });
      return;
    }

    _lastReportedIndex = index;
    scope.onTabSelected(index);
  }

  ScrollPhysics _resolvePhysics() {
    if (widget.physics != null) return widget.physics!;
    if (!widget.swipeEnabled) return const NeverScrollableScrollPhysics();
    return const PageScrollPhysics();
  }

  @override
  Widget build(BuildContext context) {
    _requireTabs(context, widgetName: 'VTabsContent');

    final pageView = PageView(
      controller: _controller,
      scrollDirection: Axis.horizontal,
      physics: _resolvePhysics(),
      onPageChanged: _onPageChanged,
      children: widget.children,
    );

    if (widget.expand) {
      return Expanded(child: pageView);
    }
    return pageView;
  }
}
