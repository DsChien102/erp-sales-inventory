import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../foundation/v_context_extensions.dart';
import '../foundation/v_inspector_scope.dart';
import '../foundations/icons/v_icons.dart';
import '../primitives/v_icon.dart';
import '../tokens/v_borders.dart';
import '../tokens/v_opacity.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_spacing.dart';
import '../tokens/v_typography.dart';

/// Single item of a [VSideNavigation].
///
/// An item without [children] is an icon tab. An item with [children] is drawn
/// at the bottom of the rail and opens a floating menu listing the children.
class VSideNavigationItem {
  const VSideNavigationItem({
    this.icon,
    required this.label,
    this.description,
    this.menuTitle,
    this.enabled = true,
    this.children = const [],
  });

  final Widget? icon;
  final String label;

  /// Secondary line shown under [label] when this item is a menu entry.
  final String? description;

  /// Title of the floating menu opened by an item with [children].
  /// Defaults to [label].
  final String? menuTitle;
  final bool enabled;
  final List<VSideNavigationItem> children;
}

/// Desktop icon rail (84 wide) anchored to the left.
///
/// Layout: [header] → tabs of items without children → spacer → items with
/// children (open a floating menu) → [footer].
///
/// - Surface `context.vColors.surface`, right hairline `borderDefault`
/// - Active tab: `surfaceBrand` + `textBrand` / `primary` icon
/// - Disabled: `vDisabledOpacity`
/// - Semantics: button, selected, enabled; Enter / Space activate
/// - Floating menu closes on Escape, outside tap, selection or unmount.
class VSideNavigation extends StatelessWidget {
  const VSideNavigation({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelect,
    this.header,
    this.footer,
    this.width = 84,
  });

  final List<VSideNavigationItem> items;
  final (int, int?) selected; // (mục chính, mục con hoặc null)
  final void Function(int item, int? child) onSelect;
  final Widget? header;
  final Widget? footer;
  final double width;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final tabs = [
      for (var i = 0; i < items.length; i++)
        if (items[i].children.isEmpty) i,
    ];
    final parents = [
      for (var i = 0; i < items.length; i++)
        if (items[i].children.isNotEmpty) i,
    ];

    Widget tab(int i) => _RailTab(
      icon: items[i].icon,
      label: items[i].label,
      selected: selected.$1 == i,
      enabled: items[i].enabled,
      onTap: () => onSelect(i, null),
    );

    return vInspectorHide(
      Container(
        width: width,
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(right: VBorders.side(colors.borderDefault)),
        ),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                vertical: VSpacing.space4,
                horizontal: VSpacing.space2,
              ),
              sliver: SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ?header,
                    for (final i in tabs) ...[
                      tab(i),
                      const SizedBox(height: VSpacing.space1),
                    ],
                    const Spacer(),
                    for (final i in parents) ...[
                      _ParentTab(
                        item: items[i],
                        selected: selected.$1 == i,
                        selectedChild: selected.$1 == i ? selected.$2 : null,
                        onSelectChild: (c) => onSelect(i, c),
                      ),
                      const SizedBox(height: VSpacing.space1),
                    ],
                    ?footer,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rail tab (icon above label) that is not part of the item list, e.g. a
/// "sign out" action placed in [VSideNavigation.footer].
class VSideNavigationAction extends StatelessWidget {
  const VSideNavigationAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final VIcons icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return _RailTab(
      icon: VIcon(icon: icon),
      label: label,
      selected: false,
      enabled: true,
      destructive: destructive,
      onTap: onTap,
    );
  }
}

Widget _styledIcon(Widget? icon, {required double size, required Color color}) {
  if (icon == null) return const SizedBox.shrink();
  if (icon is VIcon) {
    return VIcon(
      icon: icon.icon,
      // ignore: deprecated_member_use_from_same_package
      iconData: icon.iconData,
      assetPath: icon.assetPath,
      weight: icon.weight,
      size: size,
      color: color,
    );
  }
  return IconTheme(
    data: IconThemeData(color: color, size: size),
    child: icon,
  );
}

/// Shared pressable surface: background, hover, focus ring, semantics,
/// disabled opacity.
class _NavButton extends StatefulWidget {
  const _NavButton({
    required this.selected,
    required this.enabled,
    required this.onTap,
    required this.minHeight,
    required this.padding,
    required this.builder,
    this.focusNode,
  });

  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  final double minHeight;
  final EdgeInsetsGeometry padding;
  final FocusNode? focusNode;
  final Widget Function(BuildContext context, bool hovered) builder;

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  bool _focused = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final radius = BorderRadius.circular(VRadius.r8);

    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: widget.selected,
        enabled: widget.enabled,
        child: vDisabledOpacity(
          enabled: widget.enabled,
          child: Container(
            constraints: BoxConstraints(minHeight: widget.minHeight),
            decoration: BoxDecoration(
              color: widget.selected ? colors.surfaceBrand : Colors.transparent,
              borderRadius: radius,
            ),
            // Luôn có foregroundDecoration: đổi null ↔ giá trị làm đổi cấu trúc
            // cây và mất focus.
            foregroundDecoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: _focused ? colors.primary : Colors.transparent,
                width: VBorders.thick,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                focusNode: widget.focusNode,
                borderRadius: radius,
                focusColor: colors.primary.withValues(alpha: 0.12),
                hoverColor: widget.selected ? Colors.transparent : colors.surfaceHoverStrong,
                highlightColor: Colors.transparent,
                splashColor: Colors.transparent,
                onFocusChange: (v) => setState(() => _focused = v),
                onHover: (v) => setState(() => _hovered = v),
                onTap: widget.enabled ? widget.onTap : null,
                child: Padding(
                  padding: widget.padding,
                  child: widget.builder(
                    context,
                    _hovered && widget.enabled && !widget.selected,
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

class _RailTab extends StatelessWidget {
  const _RailTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
    this.destructive = false,
    this.focusNode,
  });

  final Widget? icon;
  final String label;
  final bool selected;
  final bool enabled;
  final bool destructive;
  final VoidCallback onTap;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return _NavButton(
      selected: selected,
      enabled: enabled,
      onTap: onTap,
      focusNode: focusNode,
      minHeight: 60,
      padding: const EdgeInsets.symmetric(
        vertical: VSpacing.space2,
        horizontal: 2,
      ),
      builder: (context, hovered) {
        final Color fg;
        final Color iconColor;
        if (destructive) {
          fg = iconColor = colors.danger;
        } else if (selected) {
          fg = colors.textBrand;
          iconColor = colors.primary;
        } else if (hovered) {
          fg = iconColor = colors.textPrimary;
        } else {
          fg = iconColor = colors.textSecondary;
        }
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            _styledIcon(icon, size: 22, color: iconColor),
            const SizedBox(height: VSpacing.space1),
            MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.3,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: VTypography.labelSmall.copyWith(
                  height: 14 / 11,
                  color: fg,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Tab of an item with children: toggles the floating menu.
class _ParentTab extends StatefulWidget {
  const _ParentTab({
    required this.item,
    required this.selected,
    required this.selectedChild,
    required this.onSelectChild,
  });

  final VSideNavigationItem item;
  final bool selected;
  final int? selectedChild;
  final void Function(int child) onSelectChild;

  @override
  State<_ParentTab> createState() => _ParentTabState();
}

class _ParentTabState extends State<_ParentTab> {
  final _controller = OverlayPortalController();
  final _link = LayerLink();
  final _focusNode = FocusNode(debugLabel: 'VSideNavigation parent tab');
  final _tapGroup = Object();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _close({bool restoreFocus = false}) {
    if (!_controller.isShowing) return;
    _controller.hide();
    if (restoreFocus) _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return OverlayPortal(
      controller: _controller,
      overlayChildBuilder: (context) => Align(
        alignment: Alignment.topLeft,
        child: CompositedTransformFollower(
          link: _link,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomRight,
          followerAnchor: Alignment.bottomLeft,
          child: TapRegion(
            groupId: _tapGroup,
            onTapOutside: (_) => _close(),
            child: FocusScope(
              autofocus: true,
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.escape) {
                  _close(restoreFocus: true);
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: _ManageMenu(
                title: item.menuTitle ?? item.label,
                children: item.children,
                selectedChild: widget.selectedChild,
                onSelect: (c) {
                  _close();
                  widget.onSelectChild(c);
                },
              ),
            ),
          ),
        ),
      ),
      child: CompositedTransformTarget(
        link: _link,
        child: TapRegion(
          groupId: _tapGroup,
          child: _RailTab(
            icon: item.icon,
            label: item.label,
            selected: widget.selected,
            enabled: item.enabled,
            focusNode: _focusNode,
            onTap: () => _controller.toggle(),
          ),
        ),
      ),
    );
  }
}

class _ManageMenu extends StatelessWidget {
  const _ManageMenu({
    required this.title,
    required this.children,
    required this.selectedChild,
    required this.onSelect,
  });

  final String title;
  final List<VSideNavigationItem> children;
  final int? selectedChild;
  final void Function(int child) onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final maxHeight = MediaQuery.sizeOf(context).height - 2 * VSpacing.space4;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 320, maxHeight: maxHeight),
      child: SizedBox(
        width: 320,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(VRadius.r12),
            border: VBorders.all(colors.borderDefault),
            boxShadow: const [
              BoxShadow(
                color: Color(0x140E1116),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
              BoxShadow(
                color: Color(0x1F0E1116),
                blurRadius: 40,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(VSpacing.space2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      VSpacing.space3,
                      VSpacing.space2,
                      VSpacing.space3,
                      VSpacing.space1,
                    ),
                    child: Text(
                      title,
                      style: VTypography.caption.copyWith(
                        height: 16 / 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  for (var c = 0; c < children.length; c++)
                    _MenuItem(
                      item: children[c],
                      selected: selectedChild == c,
                      onTap: () => onSelect(c),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final VSideNavigationItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return _NavButton(
      selected: selected,
      enabled: item.enabled,
      onTap: onTap,
      minHeight: VSpacing.minTouchTarget,
      padding: const EdgeInsets.symmetric(
        vertical: VSpacing.space1,
        horizontal: VSpacing.space3,
      ),
      builder: (context, hovered) {
        return Row(
          children: [
            if (item.icon != null) ...[
              _styledIcon(
                item.icon,
                size: 18,
                color: selected ? colors.primary : colors.textSecondary,
              ),
              const SizedBox(width: VSpacing.space3),
            ],
            Expanded(
              child: MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.3,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: VTypography.labelDefault.copyWith(
                        color: selected ? colors.textBrand : colors.textPrimary,
                      ),
                    ),
                    if (item.description != null)
                      Text(
                        item.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: VTypography.caption.copyWith(
                          height: 16 / 12,
                          fontWeight: FontWeight.w500,
                          color: colors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
