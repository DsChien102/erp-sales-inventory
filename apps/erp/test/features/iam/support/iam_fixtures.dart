import 'package:erp/features/iam/presentation/roles/models/role_ui_model.dart';
import 'package:erp/features/iam/presentation/shared/idempotency_key_factory.dart';
import 'package:erp/features/iam/presentation/users/models/user_ui_model.dart';

/// Dữ liệu mẫu cho test widget / cubit của TH-01 (người dùng, vai trò, khoá idempotency).

abstract final class FakeUsersData {
  static const List<MemberUiModel> sampleMembers = [
    MemberUiModel(
      id: 'm1',
      name: 'Nguyễn Văn Minh',
      email: 'minh@minhphat.vn',
      role: 'Nhân viên bán hàng',
      status: MemberStatus.active,
    ),
    MemberUiModel(
      id: 'm2',
      name: 'Phạm Ngọc Mai',
      email: 'mai@minhphat.vn',
      role: 'Thủ kho',
      status: MemberStatus.active,
    ),
    MemberUiModel(
      id: 'm3',
      name: 'Trần Thị Hoa',
      email: 'hoa@minhphat.vn',
      role: 'Kế toán',
      status: MemberStatus.suspended,
    ),
  ];

  static const List<InvitationUiModel> sampleInvitations = [
    InvitationUiModel(
      id: 'i1',
      email: 'ketoan@minhphat.vn',
      role: 'Kế toán',
      statusDetail: 'Kế toán · Đã tạo · Chưa gửi được email',
      status: InvitationStatus.failed,
    ),
    InvitationUiModel(
      id: 'i2',
      email: 'banhang@minhphat.vn',
      role: 'Nhân viên bán hàng',
      statusDetail: 'Nhân viên bán hàng · Hết hạn sau 7 ngày',
      status: InvitationStatus.pending,
    ),
    InvitationUiModel(
      id: 'i3',
      email: 'kho@minhphat.vn',
      role: 'Thủ kho',
      statusDetail: 'Thủ kho · Hết hạn trong 1 ngày',
      status: InvitationStatus.expiring,
    ),
  ];
}

/// Dữ liệu mẫu vai trò hệ thống cho test widget.
abstract final class FakeRolesData {
  static const List<RoleUiModel> sampleRoles = [
    RoleUiModel(
      id: 'store_owner',
      title: 'Chủ cửa hàng',
      description: 'Quản lý toàn bộ cửa hàng',
      isCurrent: true,
      memberNames: ['Nguyễn Văn An'],
    ),
    RoleUiModel(
      id: 'staff',
      title: 'Nhân viên bán hàng',
      description: 'Bán hàng và chăm sóc khách hàng',
    ),
    RoleUiModel(
      id: 'accountant',
      title: 'Kế toán',
      description: 'Công nợ, hóa đơn và báo cáo',
    ),
    RoleUiModel(
      id: 'warehouse',
      title: 'Thủ kho',
      description: 'Nhập xuất, tồn kho và kiểm kê',
    ),
  ];
}

/// Deterministic [IdempotencyKeyFactory] for tests.
final class FakeIdempotencyKeyFactory implements IdempotencyKeyFactory {
  FakeIdempotencyKeyFactory([this.value = 'test-idempotency-key']);

  final String value;
  int calls = 0;

  @override
  String next(String intent) {
    calls += 1;
    return '$intent-$value';
  }
}
