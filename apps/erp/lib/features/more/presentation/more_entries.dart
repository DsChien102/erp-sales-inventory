import 'package:vet45_design_system/design_system.dart';

/// Single item in the "Thêm" (More) section, shared between the mobile
/// [MorePage] list and the desktop [ErpSideNavigation] sub-items.
class MoreEntry {
  const MoreEntry({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.route,
    this.enabled = true,
    this.ownerOnly = false,
    this.needsActiveTenant = false,
    this.isDestructive = false,
    this.matchPrefixes = const [],
  });

  final String id;
  final String title;
  final String subtitle;
  final VIcons icon;
  final String? route;
  final bool enabled;
  final bool ownerOnly;
  final bool needsActiveTenant;
  final bool isDestructive;
  final List<String> matchPrefixes;

  /// Whether this entry should appear given the user's role and tenant state.
  bool isVisible({required bool isOwner, required bool isBlocked}) {
    if (ownerOnly && !isOwner && !isBlocked) return false;
    return true;
  }

  /// Whether this entry can be interacted with (tapped).
  bool isInteractive({required bool isBlocked}) {
    if (!enabled || route == null) return false;
    if (needsActiveTenant && isBlocked) return false;
    return true;
  }
}

/// The canonical list of entries in the "Thêm" section.
const List<MoreEntry> kMoreEntries = [
  MoreEntry(
    id: 'customers',
    icon: VIcons.people,
    title: 'Khách hàng & NCC',
    subtitle: 'Quản lý khách hàng & nhà cung cấp',
    enabled: false,
  ),
  MoreEntry(
    id: 'purchase_orders',
    icon: VIcons.download,
    title: 'Đơn nhập',
    subtitle: 'Nhập kho từ nhà cung cấp',
    enabled: false,
  ),
  MoreEntry(
    id: 'inventory',
    icon: VIcons.warehouse,
    title: 'Kho',
    subtitle: 'Tồn kho, phiếu nhập, điều chỉnh',
    route: '/inventory',
    needsActiveTenant: true,
    matchPrefixes: ['/inventory', '/warehouse'],
  ),
  MoreEntry(
    id: 'reports',
    icon: VIcons.chart,
    title: 'Báo cáo',
    subtitle: 'Doanh thu, tồn kho, công nợ',
    enabled: false,
  ),
  MoreEntry(
    id: 'pricing',
    icon: VIcons.tag,
    title: 'Giá riêng',
    subtitle: 'Giá riêng theo khách hàng',
    route: '/pricing',
    needsActiveTenant: true,
    matchPrefixes: ['/pricing'],
  ),
  MoreEntry(
    id: 'users_and_roles',
    icon: VIcons.people,
    title: 'Người dùng & vai trò',
    subtitle: 'Quản lý thành viên và quyền truy cập',
    route: '/more/users-and-roles',
    ownerOnly: true,
    needsActiveTenant: true,
    matchPrefixes: [
      '/more/users-and-roles',
      '/more/organization-profile',
      '/more/users',
      '/more/roles',
      '/more/audit-logs',
    ],
  ),
  MoreEntry(
    id: 'my_account',
    icon: VIcons.person,
    title: 'Tài khoản của tôi',
    subtitle: 'Xem và chỉnh sửa thông tin cá nhân',
    route: '/more/my-account',
    matchPrefixes: ['/more/my-account'],
  ),
  MoreEntry(
    id: 'settings',
    icon: VIcons.settings,
    title: 'Thiết lập',
    subtitle: 'Cấu hình hệ thống & hóa đơn điện tử',
    route: '/more/settings',
    needsActiveTenant: true,
    matchPrefixes: [
      '/more/settings',
      '/more/einvoice',
      '/more/product-settings',
    ],
  ),
  MoreEntry(
    id: 'logout',
    icon: VIcons.logout,
    title: 'Đăng xuất',
    subtitle: 'Thoát khỏi tài khoản hiện tại',
    isDestructive: true,
  ),
];

/// The clickable sub-sections shown under "Thêm" in the side navigation bar.
final List<MoreEntry> kSideNavSubEntries = [
  for (final e in kMoreEntries)
    if (e.route != null && e.enabled) e,
];

/// Finds which [MoreEntry] is selected by checking the current URL [location]
/// against prefix match rules (first matching entry from top to bottom).
///
/// Returns `null` if [location] is `/more` exactly, or if no prefix matches.
MoreEntry? selectedMoreEntry(String location) {
  if (location == '/more') return null;
  for (final entry in kSideNavSubEntries) {
    for (final prefix in entry.matchPrefixes) {
      if (location == prefix || location.startsWith('$prefix/')) {
        return entry;
      }
    }
  }
  return null;
}
