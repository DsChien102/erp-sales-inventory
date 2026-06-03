import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

enum ErpTab {
  home(
    label: 'Trang chủ',
    icon: Icons.home_outlined,
    routePath: '/dashboard/home',
    enabled: true,
  ),
  orders(
    label: 'Đơn hàng',
    icon: Icons.receipt_long_outlined,
    routePath: '/orders',
    enabled: false,
  ),
  products(
    label: 'Sản phẩm',
    icon: Icons.inventory_2_outlined,
    routePath: '/catalogue/products',
    enabled: false,
  ),
  partners(
    label: 'KH&NCC',
    icon: Icons.people_outline_rounded,
    routePath: '/partner',
    enabled: false,
  ),
  more(
    label: 'Thêm',
    icon: Icons.more_horiz_rounded,
    routePath: '/dashboard/more',
    enabled: true,
  );

  const ErpTab({
    required this.label,
    required this.icon,
    required this.routePath,
    required this.enabled,
  });

  final String label;
  final IconData icon;
  final String routePath;
  final bool enabled;

  static ErpTab fromPath(String path) {
    for (final tab in ErpTab.values.reversed) {
      if (path.startsWith(tab.routePath)) {
        return tab;
      }
    }
    return ErpTab.home;
  }
}

class ErpBottomNavigation extends StatelessWidget {
  const ErpBottomNavigation({
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
      index = ErpTab.fromPath(location).index;
    }

    return VBottomNavigationBar(
      currentIndex: index,
      onTap: (index) {
        final targetTab = ErpTab.values[index];
        if (!targetTab.enabled) return;

        if (onItemSelected != null) {
          onItemSelected!(index);
          return;
        }
        final currentTab = ErpTab.fromPath(location);
        if (targetTab == currentTab) return;
        context.go(targetTab.routePath);
      },
      items: ErpTab.values.map((tab) => VBottomNavigationItem(
        icon: Icon(tab.icon),
        label: tab.label,
        enabled: tab.enabled,
      )).toList(),
    );
  }
}
