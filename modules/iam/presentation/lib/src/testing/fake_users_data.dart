import '../users/models/user_ui_model.dart';

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
