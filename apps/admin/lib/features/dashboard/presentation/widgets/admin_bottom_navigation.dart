import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../models/admin_tab.dart';

class AdminBottomNavigation extends StatelessWidget {
  const AdminBottomNavigation({
    super.key,
    this.selectedIndex = 0,
    this.onItemSelected,
  });

  final int selectedIndex;
  final ValueChanged<int>? onItemSelected;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    final int index;
    if (location == '/' || onItemSelected != null) {
      index = selectedIndex;
    } else {
      index = AdminTab.fromPath(location).index;
    }

    final colors = context.vColors;

    return VBottomNavigationBar(
      currentIndex: index,
      onTap: (index) {
        final targetTab = AdminTab.values[index];
        if (!targetTab.enabled) return;

        if (onItemSelected != null) {
          onItemSelected!(index);
          return;
        }
        final currentTab = AdminTab.fromPath(location);
        if (targetTab == currentTab) return;
        context.go(targetTab.routePath);
      },
      items: AdminTab.values
          .map(
            (tab) {
              final isSelected = tab.index == index;
              final isEnabled = tab.enabled;
              final color = !isEnabled
                  ? colors.textMuted
                  : isSelected
                  ? colors.primary
                  : colors.textSecondary;

              return VBottomNavigationItem(
                icon: VIcon(
                  icon: tab.icon,
                  color: color,
                ),
                label: tab.label,
                enabled: tab.enabled,
              );
            },
          )
          .toList(),
    );
  }
}
