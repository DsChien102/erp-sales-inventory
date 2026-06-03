import 'package:flutter/material.dart';
import '../../tokens/v_spacing.dart';
import '../../tokens/v_typography.dart';
import '../../utils/v_context_extensions.dart';

class VTabs extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final bool isScrollable;

  const VTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    this.isScrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    Widget buildTab(int index, String label) {
      final isSelected = index == selectedIndex;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTabSelected(index),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: VSpacing.space4,
            vertical: VSpacing.space3,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? dynamicColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            style: VTypography.bodyDefault.copyWith(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? dynamicColors.primary : dynamicColors.textSecondary,
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

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: dynamicColors.borderDefault,
            width: 1,
          ),
        ),
      ),
      child: content,
    );
  }
}
