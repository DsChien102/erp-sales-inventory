import 'package:flutter/material.dart';
// contract: na tone/emphasis/state
import '../foundation/v_context_extensions.dart';
import '../tokens/v_borders.dart';
import '../tokens/v_opacity.dart';
import '../foundation/v_inspector_scope.dart';

class VBottomNavigationItem {
  final Widget icon;
  final String label;
  final bool enabled;

  const VBottomNavigationItem({
    required this.icon,
    required this.label,
    this.enabled = true,
  });
}

class VBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final List<VBottomNavigationItem> items;
  final ValueChanged<int> onTap;

  const VBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return vInspectorHide(
      Container(
        decoration: BoxDecoration(
          color: dynamicColors.surface,
          border: Border(
            top: VBorders.side(dynamicColors.borderDefault),
          ),
        ),
        padding: EdgeInsets.only(
          top: 10,
          bottom: bottomInset > 0 ? (bottomInset * 0.4 + 6) : 12,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final isSelected = index == currentIndex;
            final item = items[index];
            final isEnabled = item.enabled;
            final color = isSelected
                ? dynamicColors.primary
                : dynamicColors.textSecondary;

            return Expanded(
              child: vDisabledOpacity(
                enabled: isEnabled,
                child: InkWell(
                  onTap: isEnabled ? () => onTap(index) : null,
                  highlightColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: 50,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconTheme(
                          data: IconThemeData(color: color, size: 29),
                          child: item.icon,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
