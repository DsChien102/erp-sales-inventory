// Dữ liệu mẫu đợt 2 (quản trị). Người xem: Nguyễn Thị Lan — Chủ sở hữu duy nhất của "Thú y An Phát".
// Chuỗi hiển thị dựng lại đúng như mapper Dart: member_ui_mapper.dart, invitation_ui_mapper.dart, iam_role_label_mapper.dart,
// organization_profile_ui_mapper.dart, tenant_audit_ui_mapper.dart.

export const ORG = {
  name: 'Thú y An Phát', phone: '0912 345 678', email: 'lan@anphat.vn', address: 'Số 12 Nguyễn Trãi',
  province: 'Thành phố Hồ Chí Minh', commune: 'Phường Bàn Cờ',
};
export const LEGAL = {
  entityType: 'Doanh nghiệp', legalName: 'Công ty TNHH Thú y An Phát', taxCode: '0312345678',
  registeredAddress: 'Số 12 Nguyễn Trãi, Phường Bàn Cờ, TP. Hồ Chí Minh',
};
/** mapper: legalNoticeTitle / legalNoticeMessage (chỉ dùng khi chưa có hồ sơ pháp lý). */
export const LEGAL_NOTICE = { title: 'Chưa có hồ sơ pháp lý', message: 'Có thể bổ sung sau. Một số tính năng pháp lý chưa sử dụng được.' };

/** IamRoleLabelMapper.description (TH-01 3.4). */
export const ROLE_DESC = {
  'Chủ cửa hàng': 'Quản lý toàn bộ cửa hàng (gán mặc định cho Owner khi tạo tổ chức; gán được cho thành viên khác, BR-36)',
  'Nhân viên bán hàng': 'Bán hàng và chăm sóc khách hàng',
  'Kế toán': 'Công nợ, hóa đơn và báo cáo',
  'Thủ kho': 'Nhập xuất, tồn kho và kiểm kê',
};

// identityText: chủ → "Chủ sở hữu", còn lại → "Chỉ đọc" (member_ui_mapper.dart).
export const MEMBERS = [
  { id: 'm1', name: 'Nguyễn Thị Lan', email: 'lan@anphat.vn', role: 'Chủ cửa hàng', status: 'active', isOwner: true, soleOwner: true, joined: '02/09/2026', lastActive: '22/11/2026 08:41' },
  { id: 'm2', name: 'Trần Văn Minh', email: 'minh@anphat.vn', role: 'Nhân viên bán hàng', status: 'active', joined: '15/10/2026', lastActive: '21/11/2026 17:05' },
  { id: 'm3', name: 'Lê Thu Hà', email: 'ha@anphat.vn', role: 'Kế toán', status: 'suspended', joined: '20/10/2026', suspendedAt: '18/11/2026 09:12' },
];
/** Thành viên đã loại: không còn trong danh sách, chỉ mở được chi tiết. */
export const REMOVED = { id: 'm4', name: 'Phạm Quốc Bảo', email: 'bao@anphat.vn', role: 'Thủ kho', status: 'removed', joined: '01/10/2026', removedAt: '10/11/2026 14:30' };
export const memberById = (id) => [...MEMBERS, REMOVED].find((m) => m.id === id);

/** statusDetail = "<vai trò> · <hạn> · <gửi>" (invitation_ui_mapper.dart); status theo thứ tự: kết thúc > gửi lỗi > sắp hết hạn (≤ 2 ngày) > đang chờ. */
export const INVITATIONS = [
  { id: 'i1', email: 'tuan@anphat.vn', role: 'Nhân viên bán hàng', expiry: 'Hết hạn sau 6 ngày', delivery: 'sent', wire: 'pending', status: 'pending' },
  { id: 'i2', email: 'nga.kt@gmail.com', role: 'Kế toán', expiry: 'Hết hạn trong 1 ngày', delivery: 'sent', wire: 'pending', status: 'expiring' },
  { id: 'i3', email: 'khoa@anphat.vn', role: 'Thủ kho', expiry: 'Hết hạn sau 5 ngày', delivery: 'failed', wire: 'pending', status: 'failed' },
  { id: 'i4', email: 'vy@anphat.vn', role: 'Nhân viên bán hàng', expiry: 'Đã hết hạn', delivery: 'sent', wire: 'expired', status: 'expired' },
];
const DELIVERY = { failed: 'Chưa gửi được email', queued: 'Đang xếp hàng gửi', sent: 'Đã gửi email' };
export const statusDetail = (i) => `${i.role} · ${i.expiry} · ${DELIVERY[i.delivery] || i.delivery}`;
export const invitationById = (id) => INVITATIONS.find((i) => i.id === id);

export const MEMBER_BADGE = { active: ['Hoạt động', 'success'], suspended: ['Tạm ngừng', 'danger'], removed: ['Đã loại', 'danger'] };
export const INVITATION_BADGE = {
  failed: ['Lỗi gửi', 'danger'], pending: ['Đang chờ', 'warning'], expiring: ['Sắp hết hạn', 'danger'], accepted: ['Đã chấp nhận', 'success'],
  declined: ['Đã từ chối', 'neutral'], revoked: ['Đã thu hồi', 'neutral'], expired: ['Hết hạn', 'neutral'],
};

/** RolesCubit._catalog: thứ tự theo danh sách vai trò gán được; isCurrent = có người giữ (cả thành viên tạm ngừng). */
export const ROLES = ['Chủ cửa hàng', 'Nhân viên bán hàng', 'Kế toán', 'Thủ kho'].map((title, i) => ({
  id: ['store_owner', 'staff', 'accountant', 'warehouse'][i], title, description: ROLE_DESC[title],
  members: MEMBERS.filter((m) => m.role === title).map((m) => m.name),
}));

/** Lịch sử quản trị (TenantAuditUiMapper.fromSummary): dòng 3 = "<targetSubjectLabel = 'Loại đối tượng'>: <tên đối tượng>". */
export const AUDIT = [
  { id: 'a1', icon: 'users', title: 'Thay đổi vai trò thành viên', code: 'iam.membership.role_changed', actor: 'Nguyễn Thị Lan', actorRole: 'Chủ cửa hàng', at: '22/11/2026 10:21', subject: 'Trần Văn Minh', subjectType: 'Thành viên', subjectId: '5f1c2a9e…7b3d', changes: [['Vai trò', 'Thủ kho', 'Nhân viên bán hàng']] },
  { id: 'a2', icon: 'mail', title: 'Tạo lời mời thành viên', code: 'iam.invitation.created', actor: 'Nguyễn Thị Lan', actorRole: 'Chủ cửa hàng', at: '21/11/2026 15:02', subject: 'tuan@anphat.vn', subjectType: 'Lời mời' },
  { id: 'a3', icon: 'alert', title: 'Tạm ngừng thành viên', code: 'iam.membership.deactivated', actor: 'Nguyễn Thị Lan', actorRole: 'Chủ cửa hàng', at: '18/11/2026 09:12', subject: 'Lê Thu Hà', subjectType: 'Thành viên', legacy: true },
  { id: 'a4', icon: 'building', title: 'Cập nhật hồ sơ tổ chức', code: 'iam.tenant.profile_updated', actor: 'Nguyễn Thị Lan', actorRole: 'Chủ cửa hàng', at: '16/11/2026 11:40', subject: 'Thú y An Phát', subjectType: 'Tổ chức' },
  { id: 'a5', icon: 'checkCircle', title: 'Chấp nhận lời mời tham gia', code: 'iam.invitation.accepted', actor: 'Trần Văn Minh', actorRole: 'Nhân viên bán hàng', at: '15/10/2026 08:03', subject: 'Trần Văn Minh', subjectType: 'Thành viên' },
  { id: 'a6', icon: 'close', title: 'Thu hồi lời mời thành viên', code: 'iam.invitation.revoked', actor: 'Không còn thông tin người thực hiện', actorRole: '—', at: '12/10/2026 16:47', subject: 'vy.old@gmail.com', subjectType: 'Lời mời', actorUnavailable: true },
];
export const AUDIT_TOTAL = 24;
export const TRACE_ID = 'req_7f3a9c21e0b4…c8d19f02'; // formatTraceId: > 24 ký tự → 12 đầu + … + 8 cuối
