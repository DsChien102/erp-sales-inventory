import 'package:flutter/material.dart';
// contract: na tone/emphasis/state
import '../foundation/v_context_extensions.dart';
import '../patterns/v_gap.dart';
import '../tokens/v_borders.dart';
import '../tokens/v_opacity.dart';
import '../tokens/v_spacing.dart';
import '../tokens/v_typography.dart';
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
        // Keep the tab labels clear of the home indicator / gesture bar.
        padding: EdgeInsets.only(
          top: VSpacing.space1,
          bottom: bottomInset > 0 ? bottomInset : VSpacing.space3,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final isSelected = index == currentIndex;
            final item = items[index];
            final isEnabled = item.enabled;
            final color = isSelected ? dynamicColors.primary : dynamicColors.textSecondary;

            return Expanded(
              child: MergeSemantics(
                child: Semantics(
                  selected: isSelected,
                  button: true,
                  child: vDisabledOpacity(
                    enabled: isEnabled,
                    child: InkWell(
                      onTap: isEnabled ? () => onTap(index) : null,
                      highlightColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: 48,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconTheme(
                              data: IconThemeData(color: color, size: 24),
                              child: item.icon,
                            ),
                            const VGap(VSpacing.space1),
                            MediaQuery.withClampedTextScaling(
                              maxScaleFactor: 1.3,
                              child: Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: VTypography.labelSmall.copyWith(
                                  color: color,
                                  // Selection reads by weight too, not by color alone.
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
            );
          }),
        ),
      ),
    );
  }
}
