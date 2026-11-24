// Danh sách ca dùng chung: main.js, viewer.js, tools/capture.mjs.
// Mỗi state: [mã, nhãn ngắn, điều cần nhìn]. Mỗi ca vẽ ở cả hai khổ (iPhone 390, Web 1280).
export const SCREENS = [
  {
    id: 'home', code: 'APP-01', title: 'Trang chủ', states: [
      ['owner', 'Chủ cửa hàng', 'Giao diện "Bảng giá chợ": doanh thu số rất lớn + cột 7 ngày (biểu đồ duy nhất); ba hộp Đơn hôm nay (12 ▲3 | Chưa xuất hoá đơn 2, dòng cách trả), Tiền đã thu hôm nay (tiền mặt / chuyển khoản, gồm cả khách trả nợ), Công nợ phải thu (số khoản quá hạn). Không nút thao tác, không banner. Dữ liệu mẫu.'],
      ['staff', 'Nhân viên', 'Như chủ cửa hàng (chưa có quy tắc ẩn số liệu theo vai trò). Web: menu "Quản lý" mất "Người dùng & vai trò".'],
      ['long-name', 'Tên tổ chức dài', 'Tên cắt "…" một dòng, mũi tên xuống vẫn ở chỗ cũ.'],
      ['loading-name', 'Đang tải tên', 'Phiên chưa có tên: đầu trang ghi "Đang tải…".'],
      ['ask-open', 'Mở Hỏi Mosaic Retail', 'Nút nổi góc dưới phải (không còn ở đầu trang) mở khung chat: web là cửa sổ lớn (≤ 1120, cách đỉnh 64, dải đầu xanh, nội dung cột 720) neo trên nút, nút thành ✕; iPhone là màn toàn phần, ẩn thanh dưới. Lời chào + 4 câu gợi ý + ô hỏi nguyên văn /ask; ⤢ mở màn /ask đầy đủ. Esc / ✕ đóng.'],
      ['evening', 'Buổi tối', 'Lời chào theo giờ máy: 5–11 "Chào buổi sáng", 12–17 "Chào buổi chiều", còn lại "Chào buổi tối".'],
    ],
  },
];

export const CASES = Object.fromEntries(SCREENS.map((s) => [s.id, s.states.map(([id]) => id)]));
