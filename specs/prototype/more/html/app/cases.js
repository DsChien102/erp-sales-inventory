// Danh sách ca dùng chung: main.js, viewer.js, tools/capture.mjs.
// Mỗi state: [mã, nhãn ngắn, điều cần nhìn]. Mỗi ca vẽ ở cả hai khổ (iPhone 390, Web 1280).
export const SCREENS = [
  {
    id: 'more', code: 'APP-02', title: 'Thêm', states: [
      ['owner', 'Chủ cửa hàng', '10 thẻ theo kMoreEntries. "Khách hàng & NCC", "Đơn nhập", "Báo cáo" tắt (mờ 45%, không mũi tên). "Đăng xuất" đỏ, vẫn có mũi tên. Web: danh sách giãn hết vùng nội dung, thanh bên "Thêm" đang chọn.'],
      ['staff', 'Nhân viên', 'Không phải chủ: mất thẻ "Người dùng & vai trò" (ở cả danh sách lẫn thanh bên web).'],
      ['blocked', 'Tổ chức bị chặn', 'session.isBlocked: thẻ cần tổ chức hoạt động (Công nợ, Kho, Giá riêng, Người dùng & vai trò, Thiết lập) mờ và không bấm được; "Người dùng & vai trò" vẫn hiện dù không phải chủ. Còn bấm được: "Tài khoản của tôi", "Đăng xuất".'],
    ],
  },
  {
    id: 'settings', code: 'APP-02', title: 'Thiết lập', states: [
      ['default', 'Thiết lập', '/more/settings (SystemSettingsPage): 2 thẻ "Thiết lập hóa đơn điện tử", "Sản phẩm". Route ngoài khung: web mở toàn màn, không thanh bên; iPhone không thanh dưới. Web: thân giới hạn 720, canh giữa.'],
    ],
  },
  {
    id: 'users', code: 'APP-02', title: 'Người dùng & vai trò', states: [
      ['owner', 'Đủ quyền', '/more/users-and-roles: 4 thẻ "Hồ sơ tổ chức", "Người dùng", "Vai trò", "Lịch sử quản trị". Kiểu thẻ khác màn Thêm: icon trần 20 màu chữ, không hộp icon; đệm dọc 16, khe 8.'],
      ['partial', 'Chỉ xem hồ sơ tổ chức', 'Chỉ có quyền tenant.view → còn 1 thẻ "Hồ sơ tổ chức".'],
      ['empty', 'Không có quyền / lỗi', 'Cubit lỗi hoặc phiên không có quyền nào → danh sách rỗng: chỉ còn thanh tiêu đề, thân trắng, không có chữ báo lỗi hay nút thử lại.'],
    ],
  },
];

export const CASES = Object.fromEntries(SCREENS.map((s) => [s.id, s.states.map(([id]) => id)]));
