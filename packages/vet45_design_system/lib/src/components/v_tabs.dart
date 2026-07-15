import 'package:flutter/material.dart';
import '../tokens/v_spacing.dart';
import '../tokens/v_typography.dart';
import '../foundation/v_context_extensions.dart';
import '../foundation/v_component_contracts.dart';

class VTabs extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final bool isScrollable;
  final VComponentTone tone;
  final VComponentEmphasis emphasis;
  final String? semanticLabel;

  const VTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    this.isScrollable = false,
    this.tone = VComponentTone.primary,
    this.emphasis = VComponentEmphasis.medium,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    final Color activeColor = switch (tone) {
      VComponentTone.warning => Colors.orange,
      VComponentTone.danger => Colors.red,
      _ => dynamicColors.primary,
    };

    final indicatorWidth = emphasis == VComponentEmphasis.strong ? 3.0 : 2.0;

    Widget buildTab(int index, String label) {
      final isSelected = index == selectedIndex;
      return Semantics(
        button: true,
        selected: isSelected,
        label: label,
        child: InkWell(
          onTap: () => onTabSelected(index),
          child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: VSpacing.space4,
            vertical: VSpacing.space3,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? activeColor : Colors.transparent,
                width: indicatorWidth,
              ),
            ),
          ),
          child: Text(
            label,
            style: VTypography.bodyDefault.copyWith(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? activeColor : dynamicColors.textSecondary,
            ),
          ),
        ),
        ),
      );
    }

    final children = List<Widget>.generate(
      tabs.length,
      (index) => isScrollable
          ? buildTab(index, tabs[index])
          : Expanded(child: Center(child: buildTab(index, tabs[index]))),
    );

    Widget content = Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: children,
    );

    if (isScrollable) {
      content = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: content,
      );
    }

    return Semantics(
      label: semanticLabel ?? 'Tabs',
      explicitChildNodes: true,
      child: Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: dynamicColors.borderDefault,
            width: 1,
          ),
        ),
      ),
      child: content,
    ),
    );
  }
}
