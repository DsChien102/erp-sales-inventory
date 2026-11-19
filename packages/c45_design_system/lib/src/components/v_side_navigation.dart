import 'package:flutter/material.dart';

import '../foundation/v_context_extensions.dart';
import '../foundation/v_inspector_scope.dart';
import '../tokens/v_borders.dart';
import '../tokens/v_opacity.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_spacing.dart';
import '../tokens/v_typography.dart';

/// Single item within a [VSideNavigation], optionally containing one level
/// of permanently expanded [children].
class VSideNavigationItem {
  const VSideNavigationItem({
    this.icon,
    required this.label,
    this.enabled = true,
    this.children = const [],
  });

  final Widget? icon;
  final String label;
  final bool enabled;
  final List<VSideNavigationItem> children; // một cấp, luôn mở
}

/// Desktop / wide-viewport primary navigation rail anchored to the left.
///
/// Follows the design tokens and contracts of [VBottomNavigationBar]:
/// - Surface color: `context.vColors.surface`
/// - Right divider: `context.vColors.borderDefault` hairline
/// - Active states: `context.vColors.surfaceBrand` + `textBrand` / `primary`
/// - Disabled states: `vDisabledOpacity`
/// - Semantics: button, selected, accessible text label
/// - Keyboard navigation: Tab focus ring, Enter / Space activation
/// - Touch target: ≥ [VSpacing.minTouchTarget] (44pt)
class VSideNavigation extends StatelessWidget {
  const VSideNavigation({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelect,
    this.header,
    this.footer,
    this.width = 240,
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

    return vInspectorHide(
      Container(
        width: width,
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(
            right: VBorders.side(colors.borderDefault),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ?header,
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: VSpacing.space3,
                  vertical: VSpacing.space2,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      if (i > 0) const SizedBox(height: VSpacing.space1),
                      _buildMainItem(context, i),
                      if (items[i].children.isNotEmpty) ...[
                        const SizedBox(height: VSpacing.space1),
                        for (var c = 0; c < items[i].children.length; c++) ...[
                          if (c > 0) const SizedBox(height: VSpacing.space1),
                          _buildChildItem(context, i, c),
                        ],
                      ],
                    ],
                  ],
                ),
              ),
            ),
            if (footer != null)
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: VBorders.side(colors.borderDefault),
                  ),
                ),
                padding: const EdgeInsets.all(VSpacing.space3),
                child: footer!,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainItem(BuildContext context, int itemIndex) {
    final item = items[itemIndex];
    final isSelected = selected.$1 == itemIndex;
    final isExact = isSelected && selected.$2 == null;

    return _SideNavItemView(
      label: item.label,
      icon: item.icon,
      isSelected: isSelected,
      isExactSelected: isExact,
      isEnabled: item.enabled,
      isSubItem: false,
      onTap: () => onSelect(itemIndex, null),
    );
  }

  Widget _buildChildItem(BuildContext context, int itemIndex, int childIndex) {
    final childItem = items[itemIndex].children[childIndex];
    final isSelected = selected.$1 == itemIndex && selected.$2 == childIndex;

    return _SideNavItemView(
      label: childItem.label,
      icon: childItem.icon,
      isSelected: isSelected,
      isExactSelected: isSelected,
      isEnabled: childItem.enabled,
      isSubItem: true,
      onTap: () => onSelect(itemIndex, childIndex),
    );
  }
}

class _SideNavItemView extends StatefulWidget {
  const _SideNavItemView({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.isExactSelected,
    required this.isEnabled,
    required this.isSubItem,
    required this.onTap,
  });

  final String label;
  final Widget? icon;
  final bool isSelected;
  final bool isExactSelected;
  final bool isEnabled;
  final bool isSubItem;
  final VoidCallback onTap;

  @override
  State<_SideNavItemView> createState() => _SideNavItemViewState();
}

class _SideNavItemViewState extends State<_SideNavItemView> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final isSelected = widget.isSelected;
    final isExact = widget.isExactSelected;
    final isEnabled = widget.isEnabled;
    final hasIcon = widget.icon != null;

    final Color bgColor;
    if (isExact) {
      bgColor = colors.surfaceBrand;
    } else if (isSelected && !widget.isSubItem) {
      bgColor = colors.surfaceBrand.withValues(alpha: 0.5);
    } else {
      bgColor = Colors.transparent;
    }

    final fgColor = isSelected ? colors.textBrand : colors.textSecondary;
    final iconColor = isSelected ? colors.primary : colors.textSecondary;
    final borderRadius = BorderRadius.circular(VRadius.r8);

    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: isSelected,
        enabled: isEnabled,
        child: vDisabledOpacity(
          enabled: isEnabled,
          child: Container(
            constraints: const BoxConstraints(
              minHeight: VSpacing.minTouchTarget,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: borderRadius,
              border: _isFocused
                  ? Border.all(color: colors.primary, width: VBorders.thick)
                  : Border.all(color: Colors.transparent, width: VBorders.thick),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: borderRadius,
                focusColor: colors.primary.withValues(alpha: 0.12),
                hoverColor: colors.surfaceHover,
                highlightColor: Colors.transparent,
                splashColor: Colors.transparent,
                onFocusChange: (focused) {
                  setState(() => _isFocused = focused);
                },
                onTap: isEnabled ? widget.onTap : null,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: widget.isSubItem && !hasIcon
                        ? (VSpacing.space3 + 32)
                        : VSpacing.space3,
                    right: VSpacing.space3,
                    top: VSpacing.space1,
                    bottom: VSpacing.space1,
                  ),
                  child: Row(
                    children: [
                      if (hasIcon) ...[
                        IconTheme(
                          data: IconThemeData(
                            color: iconColor,
                            size: 20,
                          ),
                          child: widget.icon!,
                        ),
                        const SizedBox(width: VSpacing.space3),
                      ],
                      Expanded(
                        child: MediaQuery.withClampedTextScaling(
                          maxScaleFactor: 1.3,
                          child: Text(
                            widget.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: (widget.isSubItem
                                    ? VTypography.bodyDefault
                                    : VTypography.labelDefault)
                                .copyWith(
                              color: fgColor,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : (widget.isSubItem
                                      ? FontWeight.w500
                                      : FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                    ],
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
