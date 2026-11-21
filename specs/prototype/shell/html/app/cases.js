// Danh sách ca dùng chung: main.js, viewer.js, tools/capture.mjs.
// Mỗi state: [mã, nhãn ngắn, điều cần nhìn]. Mỗi ca vẽ ở cả hai khổ (iPhone 390, Web 1280).
export const SCREENS = [
  {
    id: 'tab', code: 'Tab', title: 'Trang gốc 5 tab', states: [
      ['home', 'Trang chủ', 'iPhone: thanh dưới, "Trang chủ" xanh đậm. Web: thanh bên 240, "Trang chủ" nền brand, nội dung rộng 1040 (< 1120 nên không bị giới hạn).'],
      ['orders', 'Đơn hàng', 'Tab Đơn hàng được chọn.'],
      ['products', 'Sản phẩm', 'Tab Sản phẩm được chọn.'],
      ['partners', 'Đối tác', 'Tab Đối tác được chọn.'],
      ['more', 'Thêm', 'iPhone: danh sách Thêm (10 mục, 3 mục tắt mờ). Web: "Thêm" nền brand, 6 mục con luôn mở, không mục con nào chọn.'],
    ],
  },
  {
    id: 'sub', code: 'Mục con', title: 'Mục con của Thêm', states: [
      ['warehouse', 'Kho (trong khung)', 'Route /warehouse nằm trong nhánh "Thêm": web có thanh bên, "Thêm" nền brand 50%, "Kho" nền brand. iPhone: vẫn có thanh dưới (ErpTabScaffold luôn vẽ thanh dưới trong nhánh).'],
      ['receivables', 'Công nợ (ngoài khung)', 'PHÁT HIỆN: /more/receivables khai báo ngoài ShellRoute(StoreShell) → web mở toàn màn, không thanh bên; iPhone không thanh dưới.'],
      ['pricing', 'Giá riêng (ngoài khung)', 'Như Công nợ: /pricing ngoài khung.'],
      ['users', 'Người dùng & vai trò (ngoài khung)', 'Như Công nợ.'],
      ['account', 'Tài khoản của tôi (ngoài khung)', 'Như Công nợ.'],
      ['settings', 'Thiết lập (ngoài khung)', 'Như Công nợ.'],
    ],
  },
  {
    id: 'session', code: 'Phiên', title: 'Phiên làm việc và khổ màn', states: [
      ['staff', 'Nhân viên (không phải chủ)', 'Web: thanh bên còn 5 mục con, mất "Người dùng & vai trò". iPhone giống Trang chủ.'],
      ['blocked', 'Tổ chức bị chặn', 'Tab khác "Thêm" thay bằng thẻ "Chưa có tổ chức được cấp quyền" + "Kiểm tra lại". Web: tên "Chưa chọn tổ chức"; Công nợ, Kho, Giá riêng, Người dùng & vai trò, Thiết lập mờ; "Tài khoản của tôi" còn bấm được.'],
      ['narrow', 'Web cửa sổ 900', 'Khung web hẹp 900 (< 1024): không thanh bên, chuyển thanh dưới 5 tab, đệm đáy 12 (không có vùng home indicator).'],
      ['long-org', 'Tên tổ chức dài', 'Web: tên cắt "…" một dòng, icon đổi vẫn sát phải.'],
    ],
  },
  {
    id: 'gate', code: 'Chờ', title: 'Chờ cặp cửa hàng–kho', states: [
      ['loading', 'Đang tải', 'StoreShell chờ DefaultPairGateCubit: vòng tải giữa màn, không thanh bên / thanh dưới (cả web).'],
      ['error', 'Lỗi kho mặc định', '"Không thiết lập được kho mặc định" + "Thử lại" / "Chọn tổ chức khác"; web: thẻ rộng hết 1280 − 32.'],
    ],
  },
  {
    id: 'app04', code: 'APP-04', title: 'Chọn tổ chức', states: [
      ['list', 'Danh sách', 'iPhone: sheet dưới có tay kéo. Web: hộp thoại 480 giữa màn, nút Đóng góc phải. Tổ chức hiện tại nền xanh, icon cửa hàng, radio bật, không bấm được.'],
      ['search-empty', 'Tìm không thấy', 'Gõ "xyz": "Không tìm thấy tổ chức" + "Xóa bộ lọc".'],
      ['load-error', 'Lỗi tải danh sách', '"Không thể tải danh sách" (đỏ) + "Thử lại".'],
      ['confirm', 'Xác nhận chuyển', 'Sheet thứ hai "Chuyển sang Đại lý Vật tư Nông nghiệp Minh Tâm?" + "Quay lại" / "Chuyển tổ chức".'],
      ['switching', 'Đang chuyển', 'Hộp chờ "Đang chuyển tổ chức" + mô tả.'],
      ['success', 'Đã chuyển', 'Toast "Thành công · Đã chuyển sang …"; tên tổ chức trên thanh bên đổi.'],
    ],
  },
];

export const CASES = Object.fromEntries(SCREENS.map((s) => [s.id, s.states.map(([id]) => id)]));
