// Danh sách ca dùng chung: main.js, viewer.js, tools/capture.mjs.
// Mỗi state: [mã, nhãn ngắn, điều cần nhìn]. Mỗi ca vẽ ở cả hai khổ (iPhone 390, Web 1280).
export const SCREENS = [
  {
    id: 'home', code: 'APP-01', title: 'Trang chủ', states: [
      ['owner-banner', 'Chủ, chưa có hồ sơ pháp lý', 'Ca mặc định của chủ cửa hàng mới: banner xanh "Bổ sung hồ sơ pháp lý…" + "Bổ sung" + nút đóng. Số liệu ghi cứng như Flutter (8.420.000 ₫, ba ô "-", hai dòng việc chữ mẫu).'],
      ['owner', 'Chủ, không còn banner', 'Đã có hồ sơ pháp lý hoặc đã bấm đóng banner: "Hỏi Mosaic Retail" lên ngay dưới đầu trang.'],
      ['staff', 'Nhân viên', 'Không phải chủ: không có banner. Web: thanh bên mất "Người dùng & vai trò".'],
      ['scrolled', 'Cuộn tới cuối', 'iPhone: phần dưới cùng (hai dòng "Việc cần xử lý") phía trên thanh dưới. Đầu trang xanh đứng yên, chỉ thân trang cuộn.'],
      ['loading-name', 'Đang tải tên', 'Phiên chưa có tên: đầu trang ghi "Đang tải…".'],
      ['long-name', 'Tên tổ chức dài', 'Tên cắt "…" một dòng, mũi tên xuống và chuông vẫn ở chỗ cũ.'],
      ['evening', 'Buổi tối', 'Lời chào theo giờ máy: 5–11 "Chào buổi sáng", 12–17 "Chào buổi chiều", còn lại "Chào buổi tối".'],
    ],
  },
];

export const CASES = Object.fromEntries(SCREENS.map((s) => [s.id, s.states.map(([id]) => id)]));
