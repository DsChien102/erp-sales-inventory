import 'package:vet45_design_system/design_system.dart';

enum AdminTab {
  home(
    label: 'Tổng quan',
    icon: VIcons.home,
    routePath: '/dashboard/home',
    enabled: true,
  ),
  users(
    label: 'Người dùng',
    icon: VIcons.people,
    routePath: '/dashboard/users',
    enabled: true,
  ),
  organizations(
    label: 'Tổ chức',
    icon: VIcons.apartment,
    routePath: '/dashboard/organizations',
    enabled: true,
  ),
  audit(
    label: 'Nhật ký',
    icon: VIcons.listView,
    routePath: '/dashboard/audit',
    enabled: true,
  ),
  more(
    label: 'Thêm',
    icon: VIcons.moreHoriz,
    routePath: '/dashboard/more',
    enabled: true,
  );

  const AdminTab({
    required this.label,
    required this.icon,
    required this.routePath,
    required this.enabled,
  });

  final String label;
  final VIcons icon;
  final String routePath;
  final bool enabled;

  static AdminTab fromPath(String path) {
    for (final tab in AdminTab.values.reversed) {
      if (path.startsWith(tab.routePath)) {
        return tab;
      }
    }
    return AdminTab.home;
  }
}
