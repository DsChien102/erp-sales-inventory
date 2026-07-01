import 'package:flutter/material.dart';

enum DashboardTab {
  home(enabled: true),
  orders(enabled: false),
  products(enabled: false),
  partners(enabled: true),
  more(enabled: true);

  const DashboardTab({required this.enabled});

  final bool enabled;

  static DashboardTab fromIndex(int index) {
    return DashboardTab.values.firstWhere(
      (t) => t.index == index,
      orElse: () => DashboardTab.home,
    );
  }
}

enum MenuType {
  orders,
  products,
  partners,
  debt,
  drafts,
  invoices,
  reports,
  settings,
}

class MenuItem {
  const MenuItem({
    required this.icon,
    required this.label,
    required this.type,
  });

  final IconData icon;
  final String label;
  final MenuType type;
}
