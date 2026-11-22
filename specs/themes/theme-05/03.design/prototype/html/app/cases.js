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
      ['toast-deleted', 'Vừa xoá', 'Toast nổi trên nút "+" (SnackBar đặt trên FAB). Toast xanh "Đơn nháp của Trần Thị Mai đã được xóa." (tiêu đề "Đã xóa đơn nháp" không hiện).'],
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
      ['empty', 'Mới mở', 'Sheet riêng (showModalBottomSheet + VBottomSheet), không đóng bằng chạm ngoài. Hàng tiêu đề tự vẽ H3 w700 + ×; câu dẫn chữ đen bodySmall; gạch trong lề 16. "Loại khách hàng *" (radio Cá nhân / Tổ chức), "Tên khách hàng *", "Số điện thoại *", "Mã số thuế" + "Không bắt buộc", "Địa chỉ" 3 dòng + "Không bắt buộc". Khe giữa ô 8 (form khác 16). Nút "Tạo & chọn khách hàng" luôn sáng. Web: sheet đáy 640.'],
      ['org', 'Tổ chức', 'Chọn "Tổ chức": gợi ý tên đổi "Ví dụ: Công ty Minh Phát"; các ô giữ nguyên — không có "Loại tổ chức" (TH-03 BR-05 bắt buộc), MST vẫn không bắt buộc.'],
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
  {
    id: 'checkout', group: 'checkout', code: 'SG-06', title: 'Thanh toán', route: '/sales/checkout', states: [
      ['cash', 'Tiền mặt', 'Route cấp gốc, ngoài khung. App bar "Thanh toán" + ←. Thân chỉ có **thẻ khách** (icon người 20, tên, SĐT) — **không có danh sách hàng, không có tổng đơn trong thân**; tổng chỉ ở thanh dưới. "Phương thức" + segmented "Tiền mặt | Chuyển khoản | Kết hợp". Thẻ nhập: "Số tiền mặt", ô "441.000" + "đ" (dấu chấm; ô giá SG-05 dấu phẩy), "Có thể nhập số tiền khác.", segmented "0% | 50% | 100%", "Tiền thừa 0đ" (luôn hiện). Thẻ "Công nợ phát sinh 0đ" **nền xanh** + "Không phát sinh công nợ.". Thanh dưới: "Khách phải trả" (chữ đen; SG-02 chữ xám) + "Tiếp tục". Web: cột 720.'],
      ['walk-in', 'Khách lẻ', 'Thẻ khách "Khách lẻ / Không bắt buộc thông tin". "Tự động bằng tổng đơn." (ô vẫn trông như ô nhập). Hàng % thành 3 nút: "0%", "50%" viền mờ, "100%" **nền xanh** — kiểu khác hẳn segmented của khách có hồ sơ.'],
      ['bank', 'Chuyển khoản', '"Số tiền chuyển khoản" + hàng % + "Mã giao dịch" (gợi ý "Nhập mã giao dịch") + "Không bắt buộc.". Không có số tài khoản / QR để khách chuyển.'],
      ['bank-code', 'CK có mã', 'Mã giao dịch "FT26326123456".'],
      ['mixed', 'Kết hợp (đơn < 2 triệu)', 'Đổi từ Tiền mặt sang Kết hợp: giữ số cũ → "Tiền mặt 441.000", "Chuyển khoản 0"; không có hàng %; "Mã giao dịch" ngay dưới ô chuyển khoản (không khe 8 như CK).'],
      ['mixed-big', 'Kết hợp (đơn ≥ 2 triệu)', 'Vào Kết hợp khi hai ô đang 0: tiền mặt tự điền **2.000.000** (mốc cứng), chuyển khoản phần còn lại 2.850.000.'],
      ['walk-in-bank', 'Khách lẻ · CK', '"Tự động bằng tổng đơn." dưới ô chuyển khoản; mã giao dịch vẫn nhập được.'],
      ['debt', 'Bán nợ · chưa có ngày', 'Chọn 50% → 220.500: "Công nợ phát sinh 220.500đ" **vẫn nền xanh, chữ xanh** (không cảnh báo); ô ngày "Ngày hẹn thanh toán *" / "Chọn ngày hẹn" + "Bắt buộc khi phát sinh công nợ."; "Tiếp tục" mờ mà không nói vì sao.'],
      ['debt-dated', 'Bán nợ · có ngày', 'Ngày "30/11/2026" → "Tiếp tục" sáng.'],
      ['debt-zero', 'Nợ toàn bộ', '0% → ô "0", công nợ = tổng đơn.'],
      ['change', 'Có tiền thừa', 'Nhập 500.000 → "Tiền thừa 59.000đ"; hàng % vẫn chọn "100%" (≥ 75%).'],
      ['prechecking', 'Đang kiểm tra', 'Mỗi lần đổi tiền / ngày: "Tiếp tục" thành vòng xoay, mờ.'],
      ['toast-blocked', 'Bị chặn', 'Toast đỏ chỉ hiện lý do "Sản phẩm đã ngừng bán. Vui lòng quay lại đơn." (tiêu đề "Chưa đủ điều kiện thanh toán" không hiện). Nhiều lý do thì nối bằng xuống dòng.'],
      ['toast-failure', 'Hoàn tất lỗi', 'Toast đỏ "Không thể hoàn tất đơn." — chạm vào toast mới kiểm lại (không có nút), tiêu đề "Chưa hoàn tất được đơn" không hiện.'],
      ['toast-conflict', 'Xung đột', 'Toast đỏ "Vui lòng tải lại đơn." — chạm toast quay về soạn đơn.'],
      ['invalid', 'Mở thẳng liên kết', 'Câu dài canh trái sát app bar (không icon, không khe trên) + "Quay lại tạo đơn" xanh đầy ngang. Không có thanh dưới.'],
    ],
  },
  {
    id: 'checkout-sheet', group: 'checkout', code: 'SG-06', title: 'Hoàn tất đơn? / bàn phím', route: '/sales/checkout', states: [
      ['finalize', 'Hoàn tất đơn?', 'Bấm "Tiếp tục": sheet không tiêu đề, "Hoàn tất đơn?" H4 + câu dài bodySmall; **không nhắc lại số tiền, phương thức hay công nợ** cần kiểm. "Hoàn tất đơn" xanh | "Quay lại". Nút chính trên màn ghi "Tiếp tục" nhưng thật ra là bước xác nhận cuối.'],
      ['finalize-debt', 'Hoàn tất · bán nợ', 'Đơn có công nợ 220.500 và hẹn 30/11: sheet y hệt ca trên.'],
      ['keypad', 'Bàn phím tiền mặt', '"Nhập số tiền mặt", "Đơn vị: VND", "441,000" (dấu phẩy, ô ngoài dấu chấm) + "đ", phím "000".'],
    ],
  },
  {
    id: 'result', group: 'checkout', code: 'SG-07', title: 'Kết quả bán hàng', route: '/sales/result/o1', states: [
      ['paid', 'Đã thanh toán đủ', 'Route cấp gốc, ngoài khung; app bar "Kết quả bán hàng" **không có ←**. Thẻ đầu: ✓ xanh 22, "Đã hoàn tất đơn", "Đơn DH-000130", "22/11/2026 · 10:32 · Tiền mặt", "Xem chi tiết đơn" chữ xanh. Thẻ khách ô người 40. "Tóm tắt thanh toán": "Tổng đơn" nền xanh; "Đã thanh toán" nền trắng (tone neutral, trông như dòng thường) — **không có danh sách hàng**. "Chứng từ & hóa đơn": "Phiếu bán hàng" + dòng HĐĐT "Chưa phát hành" (các trạng thái / sheet HĐĐT: prototype Theme 8 đợt 2). Thanh dưới "Về trang chủ" (viền xanh) | "Tạo đơn mới".'],
      ['debt', 'Bán nợ', '"Còn phải thu 220.500đ" chữ vàng nền trong; "Hẹn thanh toán 30/11/2026" (đệm khác các hàng trên). Dòng meta vẫn ghi "Tiền mặt" — không thấy là bán nợ.'],
      ['change', 'Có tiền thừa', '"Đã thanh toán 500.000đ" + "Tiền thừa 59.000đ" (cùng kiểu neutral).'],
      ['unpaid', 'Nợ toàn bộ', 'Meta "… · Chưa thanh toán"; "Đã thanh toán 0đ", "Còn phải thu 441.000đ".'],
      ['mixed', 'Kết hợp', 'Meta "Tiền mặt + chuyển khoản"; tóm tắt chỉ có tổng đã trả, không tách mặt / CK.'],
      ['walk-in', 'Khách lẻ', 'Thẻ khách "Khách lẻ" / "Không có số điện thoại" — thẻ không mang thông tin.'],
      ['syncing', 'Đang đồng bộ', 'Chưa có đơn: "Đơn 5b1f0c2e-8a4d-…" (**hiện UUID** thay số đơn), meta "Đang đồng bộ · Tiền mặt".'],
      ['partial', 'Đồng bộ một phần', 'Banner vàng chỉ có tiêu đề dài "Một số dữ liệu liên quan đang chờ đồng bộ. Đơn hàng vẫn đã hoàn tất." giữa thẻ khách và tóm tắt.'],
      ['receipt-generating', 'Đang tạo phiếu', 'Dòng phiếu: "Đang tạo phiếu bán hàng", không bấm được nhưng trông như bấm được (không mờ, vẫn ›).'],
      ['receipt-error', 'Lỗi tạo phiếu', 'Banner vàng **"Đơn văn đã hoàn tất…"** (lỗi chính tả "văn" → "hàng"); dòng phiếu đổi "Tạo lại phiếu bán hàng" / "Không thể tạo phiếu, hãy thử lại".'],
      ['hd-fallback', 'HĐĐT chưa tải được', 'Thiếu số đơn / phiên bản: thẻ dự phòng "Hóa đơn điện tử" / "Quản lý hóa đơn" + badge vàng "Chưa tải được" (kiểu SalesEntryRow: icon cách 12, tiêu đề w600 — khác dòng HĐĐT thật cách 16, w700).'],
      ['hd-buyer', 'HĐĐT chưa đủ thông tin', 'Khách tổ chức thiếu MST: dòng HĐĐT phụ đề vàng "Chưa đủ thông tin".'],
      ['loading', 'Đang tải', 'Vòng 40 + "Đang tải kết quả bán hàng..." giữa màn; thanh dưới vẫn có "Về trang chủ" | "Tạo đơn mới".'],
      ['failure', 'Lỗi tải', 'Khối đỏ (icon ×), "Không tải được chi tiết kết quả", "Đơn đã được tạo. Thử tải lại và không thanh toán lại.", "Thử tải lại" chữ xanh; thanh dưới nút thứ hai cũng thành **"Thử tải lại" nền đỏ** — 2 nút cùng việc.'],
      ['toast-pdf-error', 'In / chia sẻ lỗi', 'Toast đỏ hiện **chuỗi lỗi thô** ("Exception: …"); tiêu đề "Thao tác PDF thất bại" không hiện.'],
    ],
  },
  {
    id: 'result-sheet', group: 'checkout', code: 'SG-07', title: 'Sheet Phiếu bán hàng', route: '/sales/result/o1', states: [
      ['actions', 'Xem / in / chia sẻ', 'Sheet **có tiêu đề + gạch** "Phiếu bán hàng" (khác các sheet đợt 1 tự vẽ tiêu đề). 3 thẻ: "Xem phiếu", "In phiếu", "Chia sẻ phiếu" (icon 22, ›). Web: sheet đáy 640.'],
    ],
  },
  {
    id: 'receipt', group: 'checkout', code: 'SG-16', title: 'Xem trước phiếu bán hàng', route: '/sales/orders/o1/preview', states: [
      ['paid', 'Đã thanh toán', 'App bar "Phiếu bán hàng" + 2 icon in / chia sẻ (không chữ). PdfPreview: trang A5 có bóng trên nền xám. iPhone: trang 350 → chữ 10,5 pt còn ~8,8 px. Logo "V45" cố định (không phải tên / logo cửa hàng). Tên cửa hàng IN HOA. Dòng pate: giá gốc gạch + giá sau giảm. "Còn phải thu 0đ" và "Công nợ phát sinh từ đơn 0đ" — **cùng một số in hai lần**. Cuối "Cám ơn quý khách!" (chính tả "Cảm ơn").'],
      ['debt', 'Bán nợ', '"Tiền mặt 220.500đ", "Còn phải thu 220.500đ", "Hạn thu 30/11/2026", "Công nợ phát sinh từ đơn 220.500đ". Không có "Công nợ cũ" / tổng nợ của khách.'],
      ['walk-in', 'Khách lẻ', 'Không dòng khách, không khối công nợ.'],
      ['loading', 'Đang tạo PDF', 'Vòng 40 + "Đang tạo bản xem trước PDF..." bodySmall.'],
      ['invalid', 'Thiếu dữ liệu', 'Chỉ câu "Thiếu dữ liệu phiếu bán hàng hợp lệ để xem trước." giữa màn, không nút quay về (ngoài ←).'],
    ],
  },
  // ---------------------------------------------------------------- đợt 3: tra cứu đơn
  {
    id: 'orders', group: 'orders', code: 'SG-08', title: 'Đơn hàng', route: '/orders', states: [
      ['loaded', 'Có dữ liệu', 'Route TRONG StoreShell: web có thanh bên (mục "Đơn hàng" sáng), iPhone có thanh dưới. App bar "Đơn hàng" + phụ đề "128 đơn hàng" (caption 12), không ←. Ô tìm "Tìm đơn hàng, khách hàng, SĐT" + nút lọc 44 (icon tune, **viền borderDefault** nhạt hơn ô tìm borderInput). Chip nhanh "Tất cả" (chọn: tone success) / "Còn phải thu" / "Chưa phát hành HĐĐT" — **không kèm số đếm**. Thẻ: tên H4 w600, "SĐT · Mosaic Retail Demo", tổng mono w600, badge "Hoàn tất" / "Đã hủy"; hàng cuối "DH-000130" | "10:32" — **chỉ giờ, không ngày**; không nhãn thanh toán / HĐĐT. Khách lẻ ghi "Khách Lẻ" (L hoa). Web: chỗ đặt 1040 → cột 720, nhưng gutter nút nổi tính theo cửa sổ 1280 → **FAB "+" lọt vào trong cột**, đè lên thẻ.'],
      ['outstanding', 'Chip "Còn phải thu"', 'Chip "Còn phải thu" xanh; nút lọc nền xanh nhạt + badge "1" — **chip nhanh được đếm là 1 bộ lọc** dù sheet lọc không có mục này (Đặt lại cũng không gỡ được). Thẻ vẫn không cho biết đơn nào còn nợ bao nhiêu.'],
      ['filtered', 'Đang lọc', 'Áp "Hôm nay" + "Hoàn tất" → badge "2"; không có dòng tóm tắt bộ lọc đang áp, phải mở sheet mới biết.'],
      ['search', 'Đang tìm', '"mai" → nút × trong ô; phụ đề đổi "2 đơn hàng"; không có dòng số kết quả riêng.'],
      ['loading', 'Đang tải', 'Phụ đề "Đang tải…"; 4 khung thẻ (viền borderDefault): vạch đầu bị Expanded kéo gần hết bề ngang (khác hình thẻ thật). Ô tìm, chip vẫn hiện.'],
      ['empty', 'Chưa có đơn', 'Hộp viền nhạt cao theo nội dung: (i) "Chưa có đơn hàng", "Đơn hàng hoàn tất sẽ xuất hiện tại đây.", "Tạo đơn bán hàng" chữ xanh — trùng việc với FAB "+" ngay dưới.'],
      ['no-result', 'Không kết quả (tìm)', 'Kính lúp, "Không tìm thấy đơn hàng", "Không có đơn phù hợp với “xyz” / trong phạm vi hiện tại." (ngoặc kép cong, xuống dòng cứng), "Xóa tìm kiếm".'],
      ['no-result-filter', 'Không kết quả (lọc)', 'Chỉ lọc, không tìm: câu "Không có đơn phù hợp trong phạm vi hiện tại." nhưng nút **vẫn ghi "Xóa tìm kiếm"** (thật ra xoá bộ lọc).'],
      ['error', 'Lỗi tải', 'Hộp viền nhạt tone danger: icon ⓧ đỏ, "Không thể tải danh sách" đỏ, "Không thể tải danh sách đơn hàng." (lặp ý), "Thử lại" chữ đỏ. Phụ đề "0 đơn hàng" dù chưa biết số đơn.'],
      ['blocked', 'Không có quyền', 'Không phụ đề, không ô tìm, không FAB. Tone warning: ⚠ vàng, "Không có quyền xem đơn hàng" vàng, câu xưng "Tài khoản của bạn", "Quay lại" chữ vàng → về Trang chủ.'],
      ['load-more', 'Đang tải thêm', 'Cuộn cuối: VLoading 40 giữa, đệm dọc 8.'],
      ['load-more-error', 'Lỗi tải thêm', 'Thẻ đệm 12: "Không thể tải thêm đơn hàng. Vui lòng thử lại." đỏ + nút nhỏ xanh **"Thu lai"** (thiếu dấu).'],
    ],
  },
  {
    id: 'orders-filter', group: 'orders', code: 'SG-08', title: 'Sheet bộ lọc', route: '/orders', states: [
      ['default', 'Mặc định', 'showVBottomSheet mở ở navigator lồng của khung → sheet chỉ phủ vùng nội dung: iPhone nằm TRÊN thanh dưới, web 640 canh giữa vùng 1040 (thanh bên không bị phủ). **Không tiêu đề**, chỉ tay kéo. 5 nhóm (tiêu đề bold): Thời gian, Trạng thái đơn, Thanh toán, Sau bán, Hóa đơn điện tử; chip chọn **tone primary** (chip nhanh ngoài màn tone success). "Đặt lại" (viền) | "Áp dụng" — **sát mép dưới, không đệm đáy**.'],
      ['selected', 'Đã chọn', '"Hôm nay", "Hoàn tất", "Còn phải thu", "Có đổi/trả", "Chưa phát hành" chọn. "Thanh toán: Còn phải thu" trùng chip nhanh cùng tên ngoài màn. "Đặt lại" đóng sheet ngay (không chỉ bỏ chọn).'],
    ],
  },
  {
    id: 'detail', group: 'orders', code: 'SG-09', title: 'Chi tiết đơn hàng', route: '/sales/orders/o1', states: [
      ['paid', 'Đã thanh toán', 'Route cấp gốc, ngoài khung (web 1 cột 720, không danh sách–chi tiết). App bar "Chi tiết đơn hàng" + ←. Thẻ đầu: "#DH-000130" H3 mono **w400**, "22/11/2026 10:32" (không "·" như SG-07), badge "Hoàn tất"; tên bold, SĐT; "Tổng đơn" nền xanh. Thẻ "Thanh toán & công nợ": "Đã thanh toán 441.000đ" và "Còn phải thu 0đ" **đều chữ vàng w600** dù đã trả đủ. "Xem công nợ của khách ›" (viền nhạt) hiện vì đơn có khách — **kể cả khi đơn không còn nợ** (TH-05 FR-02: chỉ khi còn nợ). Thanh dưới "Thao tác ⌃" xanh 52.'],
      ['paid-end', 'Cuộn cuối', '"Sản phẩm": thẻ nhóm, hàng cao 64 — icon theo đơn vị: Hộp → hộp, **Lon → nhãn (khớp chuỗi "lo")**, Chai → nhãn; pate "6 Lon × ~~18.000đ~~ 16.000đ". "Chứng từ & hóa đơn": Phiếu bán hàng, HĐĐT "Chưa phát hành" (các trạng thái: prototype Theme 8 đợt 2), "Lịch sử — Thanh toán, chứng từ và nghiệp vụ sau bán" (TH-05 ghi "Xem thanh toán và các hoạt động của đơn").'],
      ['unpaid', 'Bán nợ toàn bộ', '"Đã thanh toán 0đ" / "Còn phải thu 441.000đ" — cùng màu vàng như đơn đã trả đủ, không phân biệt.'],
      ['walk-in', 'Khách lẻ', '"Khách lẻ" / "Không có số điện thoại"; không có dòng "Xem công nợ của khách".'],
      ['returned-after', 'Có đổi/trả · Sau đổi/trả', 'Có phiếu đổi/trả → VTabs "Đơn gốc" | "Sau đổi/trả" ghim trên đầu (ngoài vùng cuộn), **mặc định chọn "Sau đổi/trả"**. Tổng 346.000đ, 2 dòng còn giữ; "Đã thanh toán 346.000đ".'],
      ['returned-original', 'Có đổi/trả · Đơn gốc', 'Tab "Đơn gốc": 3 dòng, tổng 441.000đ, "Đã thanh toán 441.000đ".'],
      ['returned-end', 'Có đổi/trả · cuối', 'Thêm "Phiếu đổi/trả — 1 phiếu · Mới nhất 24/11/2026 09:15" — **cùng icon history với "Lịch sử"** ngay dưới.'],
      ['cancelled', 'Đã hủy', 'Badge "Đã hủy" đỏ; thẻ "Lý do hủy" (lý do w600, "Phạm Thu Hà · 21/11/2026 15:40"); thẻ thanh toán **mờ 0.4** (vẫn ›); không có thanh "Thao tác".'],
      ['cancelled-end', 'Đã hủy · cuối', 'Khối chứng từ chỉ còn "Lịch sử" (ẩn phiếu bán hàng và HĐĐT).'],
      ['cancelled-no-reason', 'Hủy không ghi lý do', 'Huỷ mà để trống ô lý do → **thẻ "Lý do hủy" biến mất hẳn** (mất luôn người huỷ và thời điểm huỷ).'],
      ['cancel-reason-pending', 'Lý do hủy đang đồng bộ', '"Lý do hủy" / "Đang cập nhật kết quả hủy đơn..." xám.'],
      ['sections-loading', 'Khối đang tải', 'Thanh toán: vòng Material 20 + "Đang tải thanh toán & công nợ…" (khe 12); Lịch sử: "Đang tải lịch sử…" (khe 16, viền nhạt) — hai thẻ khác khe, khác viền. "Thao tác" mờ.'],
      ['sections-error', 'Khối lỗi', 'Thanh toán: "Không tải được thanh toán & công nợ." + "Thử lại" (khe 4); Lịch sử: "Không tải được lịch sử." + "Thử lại" (khe 8).'],
      ['payment-pending', 'Thanh toán đang đồng bộ', '"Thanh toán đang đồng bộ. Thử lại sau." + "Thử lại".'],
      ['payment-blocked', 'Không quyền xem thanh toán', '"Bạn không có quyền xem thanh toán của đơn này." (không nút).'],
      ['loading', 'Đang tải', 'CircularProgressIndicator 36 giữa màn; không thanh dưới.'],
      ['blocked', 'Không có quyền', 'VEmptyState warning: ⚠ vàng, "Không có quyền xem đơn hàng", "Quay lại" **nền vàng** (nút primary nhận tone warning).'],
      ['not-found', 'Không tìm thấy', '(i) xám, "Không tìm thấy đơn hàng", "Đơn hàng không tồn tại hoặc đã bị xóa.", "Quay lại" xanh.'],
      ['pending', 'Đang cập nhật', 'Icon (i) nhưng tone warning: "Đơn hàng đang cập nhật" vàng, "Thử lại" nền vàng.'],
      ['error', 'Lỗi tải', 'Tone danger nhưng icon ⚠ (không phải ⓧ như SG-08): "Không thể tải chi tiết đơn hàng" đỏ, "Kiểm tra kết nối và thử lại.", "Thử lại" nền đỏ.'],
      ['toast-actions', 'Thao tác chưa tải', 'Bấm "Thao tác" khi thao tác lỗi: toast vàng "Vui lòng thử lại sau." (tiêu đề "Không thể tải thao tác" không hiện).'],
      ['toast-precheck', 'Không thể tiếp tục', 'Đổi/trả bị chặn: toast vàng "Đơn đang có phiếu đổi/trả chưa hoàn tất.".'],
      ['toast-receipt', 'Lỗi phiếu', 'Toast đỏ "Dịch vụ phiếu tạm thời không khả dụng. Vui lòng thử lại.".'],
    ],
  },
  {
    id: 'detail-sheet', group: 'orders', code: 'SG-09', title: 'Sheet Thao tác / Phiếu', route: '/sales/orders/o1', states: [
      ['actions', 'Thao tác (đã thu tiền)', 'Sheet có tiêu đề "Thao tác" + gạch; web sheet đáy 640. "Đổi/trả hàng" (icon history 22, khe 8). "Hủy đơn" **tắt**: nền xám, chữ xám, phụ đề đổi thành lý do "Đơn đã có thanh toán, vui lòng đổi/trả" (không mờ, không icon khoá). Không có "Thu tiền" (đúng BR-30).'],
      ['actions-unpaid', 'Thao tác (chưa thu)', 'Đơn bán nợ toàn bộ: "Hủy đơn" bật — nền đỏ nhạt, viền đỏ 30%, chữ + icon + › đỏ.'],
      ['receipt', 'Phiếu bán hàng', 'Chạm "Phiếu bán hàng": cùng sheet với SG-07 ("Xem phiếu" / "In phiếu" / "Chia sẻ phiếu").'],
    ],
  },
  {
    id: 'payment-debt', group: 'orders', code: 'SG-09b', title: 'Thanh toán & công nợ', route: '/sales/orders/o1', states: [
      ['paid', 'Đã trả đủ', 'Màn con (đẩy bằng Navigator, URL không đổi). "#DH-000130 · Nguyễn Văn Hùng" **chữ mono** xám. Thẻ "Tình trạng hiện tại" (viền nhạt): "Trạng thái" | "Đã thanh toán" (**giá trị chữ in font mono**), "Tổng đơn" nền xanh, "Đã thanh toán (TM)" nền trắng, "Còn phải thu 0đ" vàng. "Giao dịch": "Thu tiền · Tiền mặt 441.000đ" — **không có thời gian, người thu**.'],
      ['debt', 'Chưa thu', '"Trạng thái: Chưa thu"; không có TM / CK → dòng "Đã thanh toán 0đ" **nền xanh như "Tổng đơn"** (tone primary); "Hẹn thanh toán 05/12/2026" (mono). Không có thẻ "Giao dịch".'],
      ['partial', 'Trả một phần', '"Trạng thái: **Còn phải thu**" (nhãn trạng thái trùng tên dòng số tiền bên dưới; TH-05 ghi "Thanh toán một phần"); TM 1.000.000 + CK 500.000.'],
      ['returned', 'Có đổi/trả', 'Thêm "Từ đơn hàng gốc" (hàng sát tiêu đề, không khe) và "Từ phiếu đổi/trả #DT-000012" (khe 16 sau tiêu đề): chỉ có "Khách trả thêm 0đ" — **không thấy số tiền đã hoàn** 95.000đ; phải đọc ở "Giao dịch" ("Hoàn tiền · Tiền mặt"). Ba thẻ ba kiểu khe.'],
      ['offset', 'Có cấn trừ', '"Đã cấn trừ 120.000đ"; giao dịch "Cấn trừ · từ DH-000118" + › (chạm sang đơn đối ứng) — dòng duy nhất bấm được, trông như dòng khác.'],
    ],
  },
  {
    id: 'history', group: 'orders', code: 'SG-09c', title: 'Lịch sử', route: '/sales/orders/o1', states: [
      ['default', 'Đơn thường', '"DH-000130 · Nguyễn Văn Hùng" chữ thường, **không "#", không mono** (SG-09b có). Tiêu đề "Lịch sử" lặp lại ngay dưới app bar "Lịch sử". Mọi mốc cùng icon history tròn xanh; "Ghi nhận thanh toán tiền mặt 441.000đ" (số tiền dính vào tiêu đề). Thời gian "22/11/2026 10:32".'],
      ['returned', 'Có đổi/trả', '"Hoàn tất đổi/trả #DT-000012", "Ghi nhận hoàn tiền 95.000đ", "Tính lại quyết toán" — mốc kỹ thuật hiện ra cho người bán.'],
      ['cancelled', 'Đã hủy', '"Ghi nhận báo cáo hủy đơn", "Yêu cầu hoàn tác giá bán" (mốc nội bộ của hệ thống) đứng trên "Hủy đơn hàng"; lý do huỷ không có trong mốc.'],
    ],
  },
  {
    id: 'returns-list', group: 'orders', code: 'SG-09d', title: 'Phiếu đổi/trả của đơn', route: '/sales/orders/o1', states: [
      ['list', '2 phiếu', 'App bar "Phiếu đổi/trả" + phụ đề "Đơn DH-000130 · Nguyễn Văn Hùng". "Các lần đổi/trả (2)"; mỗi hàng: icon history 20, "DT-000014 · **Đổi/trả**" (loại luôn "Đổi/trả", không tách đổi / trả), "26/11/2026 14:02 · Hoàn tất", "Khách trả thêm 23.000đ" / "Hoàn lại 95.000đ" (textMuted, không màu theo chiều tiền).'],
      ['single', '1 phiếu', 'Một phiếu: vẫn phải qua màn danh sách này rồi mới tới SG-15.'],
      ['no-identity', 'Phiếu thiếu mã', 'Phiếu không có mã → hàng không bấm được, chỉ mất › (không mờ, không nói vì sao).'],
    ],
  },
  {
    id: 'cancel', group: 'orders', code: 'SG-10', title: 'Hủy đơn', route: '/sales/orders/o2', states: [
      ['default', 'Hủy đơn hàng?', 'Sheet không tiêu đề: "Hủy đơn hàng?" H3 đỏ; "Đơn DH-000129 sẽ chuyển sang Đã hủy và không thể mở lại."; "Lý do hủy" + ô "Nhập lý do nếu cần" + "Không bắt buộc" — **không có chip lý do** (TH-05 SG-10 có "Khách yêu cầu huỷ" / "Tạo trùng đơn" / "Lý do khác"); thẻ xám "Điều chỉnh dự kiến": "Tồn kho — **Hoàn lại 9 mặt hàng**" (đếm số lượng 2 + 6 + 1, đơn có 3 mặt hàng), "Công nợ — Giảm 441.000đ" (lấy tổng đơn). "Quay lại" **trên** "Hủy đơn hàng" (viền đỏ), cả hai large 52.'],
      ['typed', 'Đã nhập lý do', '"Khách đặt nhầm, sẽ lên đơn mới" — chữ này thành "Lý do hủy" trên SG-09; để trống thì SG-09 không có thẻ lý do.'],
      ['submitting', 'Đang hủy', '"Đang hủy..." và "Quay lại" cùng mờ (không vòng xoay).'],
      ['toast-failed', 'Bị chặn', 'Toast vàng "Đơn đã có phiếu đổi/trả, không thể hủy." thuộc Scaffold màn chi tiết nên nằm **dưới lớp phủ và sau sheet** (sheet vẫn mở): iPhone gần như không thấy, web chỉ ló hai mép tối. Người bán bấm "Hủy đơn hàng" mà không thấy gì xảy ra. TH-05 ghi hộp thoại "Không thể huỷ đơn".'],
    ],
  },
];

/** { màn: [mã ca, …] } cho tools/capture.mjs và test. */
export const CASES = Object.fromEntries(SCREENS.map((s) => [s.id, s.states.map(([id]) => id)]));
