// Danh sách ca dùng chung: main.js, viewer.js, tools/capture.mjs.
// Mỗi state: [mã, nhãn ngắn, điều cần nhìn].
export const SCREENS = [
  {
    id: 'cn01', code: 'CN-01', title: 'Công nợ phải thu', states: [
      ['loading', 'Đang tải', 'Skeleton hero, ô tìm và 6 dòng.'],
      ['all', 'Có dữ liệu', 'Ví dụ 2.3: hero "Quá hạn 12.000.000 ₫ · 1 khách · lâu nhất 8 ngày"; tổng 26.500.000 ₫; Anh Tuấn (Quá hạn 8 ngày) → Trại Hưng Phát (Đến hạn hôm nay) → Chị Lan (Hẹn 25/11).'],
      ['overdue', 'Lọc Quá hạn', 'Chỉ Anh Tuấn, dòng "Quá hạn 8 ngày · 12.000.000" (AC-01 US-01.2).'],
      ['search-empty', 'Tìm không thấy', '"Không tìm thấy khách phù hợp." + nút "Xoá tìm kiếm".'],
      ['empty', 'Không ai nợ', '"Không có khách nào đang nợ" / "Đơn bán nợ sẽ hiện ở đây.", không nút.'],
      ['error', 'Lỗi tải', '"Không tải được công nợ" + "Thử lại".'],
      ['loading-more', 'Tải thêm', 'Spinner cuối danh sách.'],
      ['long', 'Ca biên', 'Tên rất dài cắt "…", tiền ≥ 1 tỷ không xuống hàng, SĐT thiếu, badge "Ngừng hoạt động".'],
      ['many', 'Nhiều khách', '8 khách: xếp theo mức khẩn (quá hạn lâu nhất → đến hạn hôm nay → hẹn gần nhất → không hẹn); hero "Quá hạn 21.450.000 ₫ · 4 khách · lâu nhất 21 ngày"; tổng 53.250.000 ₫.'],
      ['no-overdue', 'Không có quá hạn', 'Hero thành "Không có khoản nào quá hạn" (nền xanh nhạt, không bấm).'],
    ],
  },
  {
    id: 'cn02', code: 'CN-02', title: 'Công nợ của khách', states: [
      ['full', 'Anh Tuấn, trước khi thu', 'Còn nợ 18.000.000 ₫, 3 đơn · 2 quá hạn; lịch sử: Thu 2.000.000.'],
      ['after-offset', 'Sau thu + cấn trừ', 'Còn nợ 7.500.000 ₫; DH-001 đã hết nợ; lịch sử có dòng cấn trừ 500.000 sang DH-002.'],
      ['block-error', 'Lịch sử lỗi riêng', 'Khối đơn vẫn có dữ liệu, khối lịch sử "Không tải được" + "Thử lại".'],
      ['paid-off', 'Đã trả hết', '"Không còn nợ", "Không còn đơn nào nợ", ẩn nút Thu tiền, vẫn có lịch sử.'],
      ['inactive', 'Khách ngừng hoạt động', 'Cô Hoa: badge "Ngừng hoạt động"; dòng "Thu … · đơn" và "Hoàn … · đơn".'],
      ['no-history', 'Chưa có lần thu', 'Chị Lan: "Chưa có lần thu nào".'],
    ],
  },
  {
    id: 'cn03', code: 'CN-03', title: 'Thu tiền theo khách', states: [
      ['empty', 'Mới mở', 'Chưa tick đơn nào, ô số trống, nút khoá, gợi ý "Chọn ít nhất một đơn để thu."'],
      ['valid', 'Tick cả 3 đơn, nhập 10.000.000', 'Kết quả ngay trong từng đơn: DH-001 "Trừ 4.000.000 → hết nợ", DH-002 "Trừ 6.000.000 → còn 2.000.000", DH-003 "Chưa nhận"; khách còn nợ 8.000.000 ₫ (tick cả 3 rồi sửa số = chia cũ trước).'],
      ['over', 'Vượt công nợ', '18.000.001: "Số tiền vượt quá tổng còn nợ của khách.", nút khoá.'],
      ['transfer', 'Chuyển khoản', 'Hiện ô "Mã giao dịch (Không bắt buộc)".'],
      ['confirm', 'Hỏi xác nhận', 'Sheet "Xác nhận thu tiền?" + danh sách Sẽ trừ vào.'],
      ['submitting', 'Đang ghi nhận', 'Nút "Đang ghi nhận...", khoá màn.'],
      ['submit-error', 'Lỗi gửi', '"Không ghi nhận được. Thử lại?" + "Thử lại".'],
      ['changed', 'Công nợ vừa đổi', 'Hộp "Công nợ của khách vừa thay đổi. Hãy tải lại rồi thử lại."'],
      ['leave-confirm', 'Rời màn khi đang nhập', 'Hộp "Bỏ khoản thu đang nhập?" (chữ nút là chữ tạm).'],
      ['all', 'Ô tick "Tất cả đơn" = trả hết', 'Tick tất cả → số tiền tự điền 18.000.000, cả 3 đơn "→ hết nợ" (AC-02). Không còn nút "Trả hết".'],
      ['one', 'Tick một đơn', 'Tick DH-002 → số tiền tự điền 8.000.000, DH-002 hết nợ, khách còn nợ 10.000.000 ₫ (AC-07).'],
      ['multi', 'Tick hai đơn, nhập 5.000.000', 'DH-001 + DH-003: DH-001 hết nợ (4.000.000), DH-003 còn 5.000.000; DH-002 "Không thu" (AC-08).'],
      ['one-over', 'Vượt đơn đã chọn', 'Tick DH-002, nhập 8.000.001: "Số tiền vượt quá tổng còn nợ của các đơn đã chọn.", nút khoá (AC-09).'],
      ['one-confirm', 'Hỏi xác nhận một đơn', 'Sheet "Xác nhận thu tiền?": "Thu 8.000.000 Tiền mặt từ Anh Tuấn · đơn DH-002" + Sẽ trừ vào.'],
      ['success', 'Thu xong', 'Về CN-02 (còn 8.000.000) + toast "Đã thu 10.000.000 ₫ từ Anh Tuấn".'],
    ],
  },
  {
    id: 'sg13', code: 'SG-13', title: 'Quyết toán đổi/trả — cấn trừ', states: [
      ['all-selected', 'Chọn hết', 'DH-002 "Trừ 500.000", DH-003 "Trừ 0" mờ; Hoàn cho khách 0 ₫, không có phương thức hoàn.'],
      ['one-unchecked', 'Bỏ DH-002', 'DH-003 nhận "Trừ 500.000"; hoàn vẫn 0.'],
      ['none-selected', 'Bỏ hết', 'Hoàn cho khách 500.000 ₫ + Phương thức hoàn.'],
      ['mixed', 'Giảm nợ + cấn trừ + hoàn', 'Đủ ba dòng đúng thứ tự: giảm nợ 400.000 → cấn trừ 2.000.000 → hoàn 600.000.'],
      ['source-has-debt', 'Đơn nguồn còn nợ', '"Giảm nợ đơn này 600.000 ₫", không có khối cấn trừ, không hoàn.'],
      ['no-other-debt', 'Không có đơn khác', 'Không có khối cấn trừ; hoàn như TH-05.'],
      ['confirm', 'Sheet xác nhận', '"Xác nhận đổi/trả?" có dòng "Cấn trừ 500.000 vào đơn DH-002".'],
      ['stale', 'Đơn nhận vừa đổi', '"Công nợ của khách vừa thay đổi. Hãy tải lại quyết toán." + "Tải lại".'],
    ],
  },
  {
    id: 'patches', code: 'Sửa màn cũ', title: 'Chỗ sửa ở màn có sẵn', states: [
      ['sg09', 'SG-09 chi tiết đơn', 'Dòng "Xem công nợ của khách ›" trong khối Thanh toán & công nợ.'],
      ['sg09b', 'SG-09b giao dịch', 'Dòng "Cấn trừ · sang DH-002" / "Cấn trừ · từ DH-001", dòng "Đã cấn trừ".'],
      ['sg09c', 'SG-09c lịch sử đơn', 'Hoạt động "Cấn trừ công nợ", "Ghi nhận thu nợ theo khách".'],
      ['sg14', 'SG-14 kết quả đổi/trả', '"Cấn trừ vào DH-002 500.000 ₫" + nút "Xem công nợ của khách".'],
      ['pt07', 'PT-07 hồ sơ khách', 'Khối Công nợ: "Còn nợ 18.000.000 ₫ · 3 đơn" + quá hạn, và biến thể "Không còn nợ".'],
      ['more-menu', 'Menu Thêm', 'Mục "Công nợ phải thu" ngay dưới "Khách hàng & NCC".'],
    ],
  },
];

export const CASES = Object.fromEntries(SCREENS.map((s) => [s.id, s.states.map(([id]) => id)]));
