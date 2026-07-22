import 'package:vet45_design_system/design_system.dart';
import '../models/admin_overview_ui_model.dart';

/// Dữ liệu mẫu cho màn hình Tổng quan quản trị (PA-D-01).
abstract final class AdminOverviewMockData {
  static const AdminOverviewMetricsUiModel metrics = AdminOverviewMetricsUiModel(
    platformUsersCount: 24,
    platformUsersChange: '+2 trong 7 ngày',
    managedOrganizationsCount: 18,
    managedOrganizationsSubtext: '1 đang thiết lập',
    privilegedOperationsCount: 126,
    privilegedOperationsSubtext: 'Trong 24 giờ',
    blockedOperationsCount: 7,
    blockedOperationsSubtext: 'Cần rà soát',
  );

  static final List<AdminActivityItemUiModel> recentActivities = [
    AdminActivityItemUiModel(
      id: 'act-001',
      title: 'Đã tạm ngừng tổ chức',
      actorName: 'Tùng Nguyễn',
      timestamp: DateTime(2026, 7, 13, 7, 30),
      icon: VIcons.edit,
    ),
    AdminActivityItemUiModel(
      id: 'act-002',
      title: 'Từ chối thao tác không đủ quyền',
      actorName: 'Nguyễn Minh',
      timestamp: DateTime(2026, 7, 13, 7, 18),
      icon: VIcons.info,
    ),
  ];
}
