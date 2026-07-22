import 'package:vet45_design_system/design_system.dart';
import '../models/audit_log_ui_model.dart';

/// Dữ liệu mẫu cho Nhật ký thao tác nền tảng (PA-D-02 & PA-D-03).
abstract final class AuditLogMockData {
  static final List<AuditLogItemUiModel> sampleLogs = [
    // Item 1: Đã tạm ngừng tổ chức (PA-D-02 & PA-D-03)
    AuditLogItemUiModel(
      id: '#AUD-000982',
      title: 'Đã tạm ngừng tổ chức',
      actionCode: 'platform.tenant.suspend',
      status: AuditLogStatus.success,
      statusLabel: 'Thành công',
      actorName: 'Tùng Nguyễn',
      actorRole: 'Nhân viên vận hành nền tảng',
      targetOrg: 'VietVet Trading',
      targetOrgCode: 'TEN-000095',
      timestamp: DateTime(2026, 7, 13, 7, 30),
      sourceApp: 'Ứng dụng quản trị nền tảng',
      correlationId: 'COR-7F29A1',
      beforeState: 'Đang hoạt động',
      afterState: 'Đã tạm ngừng',
      icon: VIcons.edit,
    ),

    // Item 2: Từ chối thao tác không đủ quyền
    AuditLogItemUiModel(
      id: '#AUD-000981',
      title: 'Từ chối thao tác không đủ quyền',
      actionCode: 'platform.access.denied',
      status: AuditLogStatus.blocked,
      statusLabel: 'Bị chặn',
      actorName: 'Nguyễn Minh',
      actorRole: 'Quản trị viên tổ chức',
      targetOrg: 'Mậu Hiên',
      targetOrgCode: 'TEN-000142',
      timestamp: DateTime(2026, 7, 13, 7, 18),
      sourceApp: 'Ứng dụng quản trị nền tảng',
      correlationId: 'COR-7F29A0',
      beforeState: 'Yêu cầu xóa dữ liệu',
      afterState: 'Yêu cầu bị từ chối',
      icon: VIcons.info,
    ),

    // Item 3: Khởi tạo tổ chức chưa hoàn tất
    AuditLogItemUiModel(
      id: '#AUD-000980',
      title: 'Khởi tạo tổ chức chưa hoàn tất',
      actionCode: 'platform.tenant.onboard',
      status: AuditLogStatus.error,
      statusLabel: 'Lỗi',
      actorName: 'Quản trị hệ thống',
      actorRole: 'Hệ thống tự động',
      targetOrg: 'VET45 Hà Nội',
      targetOrgCode: 'TEN-000152',
      timestamp: DateTime(2026, 7, 13, 6, 52),
      sourceApp: 'Ứng dụng quản trị nền tảng',
      correlationId: 'COR-7F299F',
      beforeState: 'Khởi tạo cơ sở dữ liệu',
      afterState: 'Lỗi kết nối RPC',
      icon: VIcons.info,
    ),

    // Item 4: Làm mới chính sách quyền
    AuditLogItemUiModel(
      id: '#AUD-000979',
      title: 'Làm mới chính sách quyền',
      actionCode: 'platform.policy.refresh',
      status: AuditLogStatus.success,
      statusLabel: 'Thành công',
      actorName: 'Tiến trình hệ thống',
      actorRole: 'Hệ thống tự động',
      targetOrg: 'Nền tảng VET45',
      targetOrgCode: 'SYS-000001',
      timestamp: DateTime(2026, 7, 13, 6, 30),
      sourceApp: 'Dịch vụ nền tảng',
      correlationId: 'COR-7F299E',
      beforeState: 'Phiên bản v11',
      afterState: 'Phiên bản v12',
      icon: VIcons.info,
    ),
  ];
}
