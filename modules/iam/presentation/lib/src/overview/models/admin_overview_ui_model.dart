import 'package:vet45_design_system/design_system.dart';

/// Model dữ liệu thống kê tổng quan quản trị.
class AdminOverviewMetricsUiModel {
  final int platformUsersCount;
  final String platformUsersChange;
  final int managedOrganizationsCount;
  final String managedOrganizationsSubtext;
  final int privilegedOperationsCount;
  final String privilegedOperationsSubtext;
  final int blockedOperationsCount;
  final String blockedOperationsSubtext;

  const AdminOverviewMetricsUiModel({
    required this.platformUsersCount,
    required this.platformUsersChange,
    required this.managedOrganizationsCount,
    required this.managedOrganizationsSubtext,
    required this.privilegedOperationsCount,
    required this.privilegedOperationsSubtext,
    required this.blockedOperationsCount,
    required this.blockedOperationsSubtext,
  });
}

/// Model dữ liệu hoạt động đặc quyền gần đây.
class AdminActivityItemUiModel {
  final String id;
  final String title;
  final String actorName;
  final DateTime timestamp;
  final VIcons icon;

  const AdminActivityItemUiModel({
    required this.id,
    required this.title,
    required this.actorName,
    required this.timestamp,
    required this.icon,
  });
}
