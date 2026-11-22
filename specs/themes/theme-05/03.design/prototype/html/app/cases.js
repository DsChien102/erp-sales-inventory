// Danh sách ca dùng chung: main.js, viewer.js, tools/capture.mjs.
// Mỗi màn thuộc một nhóm (đợt): compose (đợt 1); checkout, orders, returns làm ở đợt 2–4.
// Mỗi state: [mã, nhãn ngắn, điều cần nhìn]. Mỗi ca vẽ ở cả hai khổ (iPhone 390, Web 1280).
export const GROUPS = [
  { id: 'compose', title: 'Lập đơn (đợt 1)' },
  { id: 'checkout', title: 'Thanh toán & kết quả (đợt 2)' },
  { id: 'orders', title: 'Tra cứu đơn (đợt 3)' },
  { id: 'returns', title: 'Đổi / trả (đợt 4)' },
];

export const SCREENS = [
  {
    id: 'drafts', group: 'compose', code: 'SG-01', title: 'Đơn nháp', route: '/sales/drafts', states: [
      ['loaded', 'Đơn của tôi', 'Route ngoài khung (ShellRoute riêng của Sales): không thanh bên / thanh dưới. App bar "Đơn nháp" + nút ← 48. Ô tìm "Tìm theo khách hàng, SĐT, ghi chú", tab gạch chân "Đơn của tôi" | "Tất cả đơn nháp" (tab trong lề 16). Thẻ viền **borderDefault** (nhạt hơn thẻ khác viền borderStrong): tên khách H4, SĐT bodySmall; ghi chú bodySmall chữ đen 1 dòng; "3 mặt hàng · 437.000đ" w600 | mốc giờ w400 ("10:24" / "Hôm qua" / "18/11" — không năm). Khách không SĐT → "Không có số điện thoại". Badge vàng nhỏ "Cần kiểm tra" chỉ hiện ở nháp cần kiểm tra. **Không có nút xoá** trên thẻ (phải vuốt trái). FAB xanh "+" — web bị đẩy vào trong 280 theo cột 720.'],
      ['all', 'Tất cả đơn nháp', 'Tab 2: dòng SĐT thêm " · Tạo bởi: Phạm Thu Hà". Người tạo có tên dạng SĐT ("0909123456") bị ẩn → nháp Khách lẻ cuối không biết ai tạo.'],
      ['search', 'Đang tìm', '"hùng" → nút × trong ô; không có dòng số kết quả.'],
      ['loading', 'Đang tải', '8 khung thẻ (vạch 160 / 72, 90 + 72, 120, 120 / 40) viền borderDefault; ô tìm và tab vẫn hiện.'],
      ['empty', 'Chưa có nháp', 'Hộp trắng viền nhạt cao theo nội dung (không giữa màn): icon (i), "Chưa có đơn nháp", "Các đơn được lưu nháp sẽ xuất hiện tại đây.", nút chữ "Tải lại" **luôn mờ** (onRetry không được truyền). FAB vẫn là lối tạo đơn duy nhất.'],
      ['no-result', 'Tìm không ra', '"Không tìm thấy đơn nháp" + "Không có đơn nháp phù hợp với \'xyz\'." (ngoặc đơn thẳng) + "Xóa tìm kiếm" xanh.'],
      ['error', 'Lỗi tải', 'Icon × đỏ trên nền đỏ nhạt, tiêu đề đỏ "Không thể tải đơn nháp", mô tả "Không thể tải danh sách đơn nháp" (lặp ý tiêu đề), "Thử lại" chữ đỏ. Ô tìm + tab vẫn hiện.'],
      ['blocked', 'Không có quyền', 'Khoá giữa vùng tab (không hộp viền): "Không thể mở đơn nháp" + "Anh/chị không có quyền truy cập khu vực bán hàng." (xưng "Anh/chị", các màn khác "Bạn"). FAB "+" vẫn hiện.'],
      ['swipe', 'Vuốt để xoá', 'Thẻ đầu trượt trái 100: khe 8 + nút đỏ "Xóa" cao bằng thẻ. Đây là lối xoá duy nhất; web không có cử chỉ vuốt bằng chuột rõ ràng.'],
      ['more', 'Đang tải thêm', 'Cuộn tới cuối: vòng xoay Material 36 dưới thẻ cuối (iOS là vòng Cupertino).'],
      ['more-error', 'Lỗi tải thêm', 'TextButton icon ↻ 16 + "Không thể tải thêm đơn nháp · Thử lại" chữ 13 xanh, không phải VButton.'],
      ['toast-deleted', 'Vừa xoá', 'Toast xanh "Đơn nháp của Trần Thị Mai đã được xóa." (tiêu đề "Đã xóa đơn nháp" không hiện).'],
      ['toast-delete-failed', 'Xoá lỗi', 'Toast đỏ "Đơn nháp đã thay đổi. Vui lòng tải lại danh sách." — danh sách tự tải lại.'],
    ],
  },
  {
    id: 'draft-sheet', group: 'compose', code: 'SG-01', title: 'Xóa đơn nháp?', route: '/sales/drafts', states: [
      ['discard', 'Xác nhận xoá', 'showVBottomSheet không tiêu đề (web: sheet đáy 640). "Xóa đơn nháp?" H3 đỏ; câu xám; "Xóa" **nút viền đỏ** cao 52 (không nền đỏ) ở trên, "Quay lại" viền xám dưới — việc nguy hiểm đứng đầu, hai nút cùng kiểu.'],
    ],
  },
  {
    id: 'compose', group: 'compose', code: 'SG-02', title: 'Soạn đơn', route: '/sales/compose', states: [
      ['new', 'Đơn mới', 'App bar "Tạo đơn hàng" (kể cả khi mở lại nháp), leading là ô 40 ‹ (không phải nút ← 48), bên phải "Đơn nháp (3)" chữ xanh. Hàng khách: "Khách lẻ" / "Không bắt buộc thông tin" + "Chọn KH" | "Tạo KH". Ô tìm + nút quét (ô 44 viền nhạt bo 12). Vùng giữa: hộp viền "Chưa có sản phẩm trong đơn" kéo hết chỗ. Thẻ "Ghi chú đơn hàng" / "Chưa có ghi chú" ghim dưới. Thanh dưới: "Khách phải trả 0đ", "Lưu nháp" (viền xanh) | "Thanh toán" cùng mờ. Web: cột 720.'],
      ['count-loading', 'Đang đếm nháp', 'Nút "Đơn nháp (N)" thành khung xám 100 × 36.'],
      ['filled', 'Có hàng', 'Khách "Nguyễn Văn Hùng" / SĐT + "Đổi KH" | "Tạo KH". Một thẻ chứa 3 dòng, gạch giữa: ảnh 40 xám, tên w600 1 dòng, dưới là "125.000đ/Hộp" và ô số lượng − [2] + (ô chạm 34, ô số 30 × 20) cùng hàng. Dòng pate có **dải chéo xanh "%" ở góc** (giá 16.000 < niêm yết 18.000) nhưng không ghi giá niêm yết hay số giảm. "Chỉ còn 2 Chai" vàng 11 px. Thẻ "Tóm tắt thanh toán": nhãn "Tổng tiền hàng (3 sản phẩm)" bằng **chữ mono** (3 = số dòng, không phải 9 món), "Giảm giá -12.000đ" đỏ, "Thành tiền" nền xanh nhạt. Thanh dưới lặp số "Khách phải trả 441.000đ" = Thành tiền.'],
      ['walk-in', 'Khách lẻ có hàng', 'Một dòng, "Chọn KH" (khách lẻ) thay "Đổi KH". Nút chính sáng.'],
      ['stock', 'Cảnh báo tồn', '"Hết hàng" và "Chỉ còn 1 Chai" chữ đỏ, "Chỉ còn 2 Chai" vàng; dòng có cảnh báo cao hơn (76 vs 70). Hết hàng vẫn để số lượng 1 và không chặn ở màn này.'],
      ['many', 'Nhiều dòng', '6 dòng: danh sách + thẻ tóm tắt cuộn trong vùng giữa; thẻ ghi chú và thanh dưới đứng yên → iPhone còn ~3 dòng nhìn thấy.'],
      ['org-refreshing', 'Đổi khách · làm mới giá', 'Khách tổ chức không MST: banner vàng "Khách tổ chức chưa có mã số thuế" + câu vàng bodySmall "Đã đổi khách — đang làm mới giá" (không phải banner). Thanh dưới: số tiền thành khung 96 × 18, "Thanh toán" vòng xoay, "Lưu nháp" mờ. Khách không SĐT → "Chưa có số điện thoại".'],
      ['swipe', 'Vuốt dòng', 'Dòng 2 trượt trái 116: ô "Chiết khấu" (nền xanh nhạt, icon nhãn) | "Xóa" (nền đỏ nhạt, icon thùng rác) — **chỉ icon, không chữ**. Đây là lối vào duy nhất của SG-05 (điều chỉnh giá); chạm tên / giá mở SG-03 đổi đơn vị.'],
      ['note-filled', 'Có ghi chú', 'Thẻ ghi chú thu gọn hiện nội dung "Giao trước 16:00, gọi trước khi tới" ở dòng mô tả.'],
      ['note-open', 'Mở ghi chú', 'Chạm đầu thẻ: chevron xoay, mô tả ẩn, gạch + ô 3 dòng có bộ đếm "34/500". Thẻ bung ngay trên thanh dưới, chiếm chỗ danh sách.'],
      ['search-results', 'Gợi ý sản phẩm', 'Focus ô tìm (rỗng) là mở gợi ý mặc định: menu nổi viền borderStrong bo 12 bóng e1, **rộng cả hàng** (lấn dưới nút quét), tối đa 4 thẻ cao ~108, cuộn trong 350. Thẻ: ảnh 48, tên w700, "Amoxinject · Hộp", "125.000đ" … "Hộp" · **"42"** (tồn chỉ là con số, không nhãn); đơn vị cơ sở lặp 2 lần. Sản phẩm nhiều đơn vị chỉ hiện giá đơn vị cơ sở.'],
      ['search-loading', 'Đang tìm', 'Lần tìm đầu: chỉ vòng 18 trong ô thay nút ×, chưa mở menu.'],
      ['search-empty', 'Không có sản phẩm', 'Menu: kính lúp, "Không tìm thấy sản phẩm", "Thử tên, SKU hoặc barcode khác." (đệm dọc 40).'],
      ['search-error', 'Lỗi tìm', 'Menu: icon cảnh báo đỏ, "Không thể tìm sản phẩm", mô tả là **chuỗi thô của exception** ("SalesExternalOperationException: …"), "↻ Thử lại" chữ xanh (không theo tone đỏ).'],
      ['loading', 'Đang mở nháp', 'Nút ← 48 thường (không phải ô 40 như lúc soạn), vòng Material giữa màn, không thanh dưới.'],
      ['toast-saved', 'Đã lưu nháp', 'Toast xanh "Đã lưu đơn nháp." nổi trên thanh dưới; màn chuyển ngay sang **đơn mới trống** (lưu nháp không ở lại đơn vừa lưu).'],
      ['toast-stock', 'Vượt tồn', 'Toast vàng "Số lượng vượt quá tồn khả dụng" — không nói tồn còn bao nhiêu.'],
      ['toast-blocked', 'Chưa thể thanh toán', 'Toast vàng chỉ hiện lý do "Sản phẩm đã ngừng bán. Vui lòng quay lại đơn." (tiêu đề "Chưa thể thanh toán" không hiện); không chỉ dòng nào.'],
      ['toast-scan', 'Nút quét', 'Bấm nút quét chỉ ra toast xanh dương "Nhập barcode vào ô tìm kiếm rồi nhấn tìm." — không mở camera.'],
      ['toast-price', 'Đã áp giá', 'Sau SG-05 có "Lưu làm giá riêng": toast "Đã lưu và áp dụng giá riêng".'],
      ['toast-draft-gone', 'Nháp không còn', 'Lưu nháp khi nháp đã bị xoá nơi khác: toast vàng "Đơn nháp này đã bị xoá hoặc thay đổi ở nơi khác. Đã chuyển sang đơn mới." và màn thành đơn trống — hàng đang soạn mất.'],
    ],
  },
  {
    id: 'compose-sheet', group: 'compose', code: 'SG-02', title: 'Sheet của soạn đơn', route: '/sales/compose', states: [
      ['leave', 'Rời màn khi chưa lưu', 'Bấm ‹ khi có hàng chưa lưu: "Đơn có thay đổi chưa lưu" H4 + 3 thẻ (icon 22, tiêu đề w600, phụ, ›): "Tiếp tục soạn đơn", "Lưu nháp và đóng", "Bỏ thay đổi và đóng" (thẻ nền đỏ nhạt chữ đỏ). Không có nút đóng / huỷ riêng. Web: sheet đáy 640.'],
      ['qty-keypad', 'Nhập số lượng', 'Chạm ô số: bàn phím số tự vẽ (không phải VBottomSheet): tay kéo **48 × 4 màu nhạt** (sheet khác 36 × 4), "Nhập số lượng" H3 w600, "Đơn vị: Lon", ô số chữ 28 giữa, lưới 3 × 4 phím 52 (phím trái dưới trống), "Hủy" | "Lưu" cao 52. Không ghi tồn tối đa.'],
    ],
  },
  {
    id: 'unit', group: 'compose', code: 'SG-03', title: 'Chọn đơn vị bán', route: '/sales/compose', states: [
      ['default', 'Mặc định', 'Sheet cao cố định **1/3 màn** (iPhone 281, web 267) dù có 3 đơn vị → chỉ thấy ~1,5 thẻ, phải cuộn. "Chọn đơn vị bán" H4; **không ghi tên sản phẩm**. Thẻ chọn nền xanh nhạt viền xanh, ô icon 36 nền xanh đậm hơn; "18.000đ · Tồn 120" (tồn theo đơn vị đó). Radio bên phải. "Hủy" | "Xác nhận" (2 bước, chạm thẻ chưa chọn ngay).'],
      ['other', 'Chọn đơn vị khác', '"Lốc 6 lon" được chọn: thẻ đầu về trắng viền borderStrong.'],
    ],
  },
  {
    id: 'customer', group: 'compose', code: 'SG-04', title: 'Chọn khách hàng', route: '/sales/compose', states: [
      ['loaded', 'Danh sách', 'Sheet cao 72% màn. "Chọn khách hàng" H4; ô tìm "Tìm tên, SĐT hoặc mã KH"; thẻ "Khách lẻ / Không phát sinh công nợ" đang chọn (nền xanh nhạt) **đứng riêng, không cuộn**. "6 khách hàng". Thẻ: icon người 22 không nền, tên w700, "SĐT · Khách hàng · MST …" (vai trò "Khách hàng" lặp ở gần mọi thẻ; NCC thuần không SĐT → "—"). Khách ngừng hoạt động: cả thẻ mờ chữ xám "· Không hoạt động". Chạm thẻ là chọn + đóng ngay (radio chỉ để nhìn). "Tạo nhanh khách hàng" viền ở đáy.'],
      ['selected', 'Đơn đang có khách', 'Đơn đang là "Nguyễn Văn Hùng": thẻ đó xanh, "Khách lẻ" về trắng.'],
      ['search', 'Đang tìm', '"an" → "2 kết quả · “an”" (ngoặc kép cong).'],
      ['loading', 'Đang tải', 'Vạch 120 × 20 + 5 khối 72.'],
      ['empty', 'Chưa có khách', 'Icon nhóm người, "Chưa có khách hàng", "Tiếp tục với Khách lẻ hoặc tạo nhanh." (nút tạo chỉ ở đáy).'],
      ['no-result', 'Không tìm thấy', '"Không tìm thấy khách hàng" + "Không có kết quả cho “xyz”."'],
      ['error', 'Lỗi', 'Icon cảnh báo đỏ, "Không thể tải khách hàng" (khi tìm: "Không thể tìm kiếm") + "Kiểm tra kết nối và thử lại." — **không có nút Thử lại**.'],
    ],
  },
  {
    id: 'quick-create', group: 'compose', code: 'SG-04', title: 'Tạo nhanh khách hàng', route: '/sales/compose', states: [
      ['empty', 'Mới mở', 'Sheet riêng (showModalBottomSheet + VBottomSheet), không đóng bằng chạm ngoài. Hàng tiêu đề tự vẽ H3 w700 + ×; câu dẫn chữ đen bodySmall; gạch trong lề 16. "Loại khách hàng *" (radio Cá nhân / Tổ chức), "Tên khách hàng *", "Số điện thoại *" (SĐT bắt buộc — khác TH-03 cho phép trống), "Mã số thuế" + "Không bắt buộc", "Địa chỉ" 3 dòng + "Không bắt buộc". Khe giữa ô 8 (form khác 16). Nút "Tạo & chọn khách hàng" luôn sáng. Web: sheet đáy 640.'],
      ['org', 'Tổ chức', 'Chọn "Tổ chức": gợi ý tên đổi "Ví dụ: Công ty Minh Phát"; các ô giữ nguyên (MST vẫn không bắt buộc với tổ chức).'],
      ['invalid', 'Thiếu thông tin', 'Bấm tạo khi trống: viền + chữ đỏ, "Vui lòng nhập tên khách hàng", "Vui lòng nhập số điện thoại".'],
      ['submitting', 'Đang tạo', 'Nút có vòng xoay, mờ.'],
      ['error', 'Lỗi tạo', 'Banner đỏ "Không thể tạo khách hàng" + "Không thể kết nối để tạo khách hàng. Vui lòng thử lại." chèn ngay trên nút (ngoài vùng cuộn).'],
      ['discard', 'Bỏ thay đổi?', 'Đóng khi đã nhập: sheet thứ hai tay kéo **đỏ**, "Bỏ thay đổi chưa lưu?" H4 đỏ; "Bỏ thay đổi" viền đỏ trên, "Tiếp tục nhập" dưới.'],
      ['duplicate', 'Trùng SĐT', '"Có thể khách hàng đã tồn tại" + banner vàng "Trùng số điện thoại" / "0912345678 trùng với Nguyễn Văn Hùng."; "Chọn khách hàng này" (xanh) | "Vẫn tạo mới" (viền). Không có khe dưới nút cuối.'],
    ],
  },
  {
    id: 'price', group: 'compose', code: 'SG-05', title: 'Điều chỉnh giá', route: '/sales/compose', states: [
      ['default', 'Đơn giá', 'Mở từ ô "Chiết khấu" khi vuốt dòng. "Điều chỉnh giá" H3 w700; thẻ sản phẩm: "Giá riêng áp dụng: 16.000đ/Lon" (**luôn ghi "giá riêng"** kể cả khi chỉ là giá niêm yết) + "Giá niêm yết: 18.000đ/Lon"; **không hiện giá sàn** (TH-05 FR-02 có). "Cách điều chỉnh" + segmented 44 "Đơn giá | Giảm tiền | Giảm %". Ô "16,000" **dấu phẩy** (thẻ trên dấu chấm) + "đ", chạm mở bàn phím số. "Áp dụng cho 1 Lon". Ô tích "Lưu làm giá riêng" + câu mô tả. Không xem trước giá sau giảm.'],
      ['amount', 'Giảm tiền', '"3,000" đ → giá 15.000 (trừ trên giá niêm yết 18.000, không trên giá đang áp 16.000) — sheet không cho biết.'],
      ['percent', 'Giảm %', '"10" % → 16.200đ; hậu tố "%".'],
      ['below', 'Dưới giá sàn', 'Banner vàng "Dưới giá sàn" + "Giá sàn hiện tại: 15.000đ/Lon" chỉ hiện sau khi nhập dưới sàn; ô tích dính sát banner (không khe).'],
      ['save-private', 'Lưu làm giá riêng', 'Ô tích xanh đã chọn.'],
      ['walk-in', 'Khách lẻ', 'Ô tích mờ + thêm dòng "Chọn khách hàng để lưu giá riêng." dưới câu mô tả (hai câu xám liền nhau).'],
      ['keypad', 'Bàn phím tiền', '"Nhập số tiền", "Đơn vị: VND", "16,000" + "đ" xám, phím trái dưới "000".'],
      ['keypad-percent', 'Bàn phím %', '"Nhập phần trăm", "Đơn vị: %", phím trái dưới "." (cho số lẻ, nhưng giá trị bị làm tròn về số nguyên).'],
      ['confirm-below', 'Xác nhận dưới sàn', 'Sheet thứ hai (tone warning nhưng tay kéo vẫn xám): "Xác nhận giá dưới sàn?" + "Giá này cần quyền ghi đè và sẽ được lưu kèm cảnh báo." + "Xác nhận áp dụng" (xanh) | "Quay lại".'],
      ['confirm-overwrite', 'Ghi đè giá riêng', '"Ghi đè giá riêng hiện có?" + "Giá riêng đang áp dụng sẽ được cập nhật ngay." + "Ghi đè và áp dụng".'],
    ],
  },
];

/** { màn: [mã ca, …] } cho tools/capture.mjs và test. */
export const CASES = Object.fromEntries(SCREENS.map((s) => [s.id, s.states.map(([id]) => id)]));
