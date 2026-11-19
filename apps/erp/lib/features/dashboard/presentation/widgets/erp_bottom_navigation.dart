import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

enum ErpTab {
  home(
    label: 'Trang chủ',
    icon: Icons.home_outlined,
    routePath: '/',
    enabled: true,
  ),
  orders(
    label: 'Đơn hàng',
    icon: Icons.receipt_long_outlined,
    routePath: '/orders',
    enabled: true,
  ),
  products(
    label: 'Sản phẩm',
    icon: Icons.inventory_2_outlined,
    routePath: '/products/items',
    enabled: true,
  ),
  partners(
    label: 'Đối tác',
    icon: Icons.people_outline_rounded,
    routePath: '/partner',
    enabled: true,
  ),
  more(
    label: 'Thêm',
    icon: Icons.more_horiz_rounded,
    routePath: '/more',
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

  static ErpTab fromLocation(String location) {
    if (location == '/') return ErpTab.home;
    if (location.startsWith('/orders') || location.startsWith('/sales')) {
      return ErpTab.orders;
    }
    if (location.startsWith('/products')) {
      return ErpTab.products;
    }
    if (location.startsWith('/partner')) {
      return ErpTab.partners;
    }
    if (location.startsWith('/more') ||
        location.startsWith('/inventory') ||
        location.startsWith('/warehouse') ||
        location.startsWith('/pricing')) {
      return ErpTab.more;
    }
    return ErpTab.home;
  }
}

class ErpBottomNavigation extends StatelessWidget {
  const ErpBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return VBottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: ErpTab.values
          .map(
            (tab) => VBottomNavigationItem(
              icon: Icon(tab.icon),
              label: tab.label,
              enabled: tab.enabled,
            ),
          )
          .toList(),
    );
  }
}
