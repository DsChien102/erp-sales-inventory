// Danh sách ca dùng chung: main.js, viewer.js, tools/capture.mjs.
// Mỗi màn thuộc một nhóm (đợt): list (đợt 1), detail (đợt 2).
// Mỗi state: [mã, nhãn ngắn, điều cần nhìn]. Mỗi ca vẽ ở cả hai khổ (iPhone 390, Web 1280).
export const GROUPS = [
  { id: 'list', title: 'Danh sách & form (đợt 1)' },
  { id: 'detail', title: 'Chi tiết & lịch sử (đợt 2)' },
];

export const SCREENS = [
  {
    id: 'list', group: 'list', code: 'PR-01', title: 'Danh sách giá riêng', route: '/pricing', states: [
      ['loaded', 'Có dữ liệu', 'Route ngoài khung: không thanh bên / thanh dưới (iPhone và web). App bar "Giá riêng" + "24 giá riêng", **không có nút ←** (vào từ menu Thêm). Ô tìm + nút lọc 44 (tune). 3 chip. Hàng "Sắp xếp: Cập nhật gần nhất ›" canh phải (mũi tên › dù mở sheet). Thẻ: avatar tròn chữ tắt, tên KH, tên SP (cùng đậm w600, cùng cỡ), "Đơn vị: Hộp", badge bên phải; hàng giá "Giá riêng" | "Giá niêm yết" chữ mono đậm; "Hiệu lực: 01/07/2026 – Không giới hạn" + ›. **Thẻ không có SĐT khách.** "Đã tắt" (Trần Thị Mai) và "Hết hiệu lực" (Lê Hoàng Phúc) cùng màu xám. Giá thiếu → "—". Tiền "105.000đ" (không cách; Theme 2 ghi "125.000 đ"). Web: thân cột 720 giữa nền xám; nút + bị đẩy vào trong 280 px.'],
      ['loading', 'Đang tải', '6 thẻ khung (tròn 40 + 4 vạch); app bar "0 giá riêng"; không có nút + (quyền tạo chưa biết).'],
      ['search', 'Đang tìm', 'Từ khoá "an phát": nút × trong ô; app bar đổi thành "2 giá riêng" (tổng theo bộ lọc, không ghi là kết quả tìm). Không có dòng "n kết quả".'],
      ['search-loading', 'Đang tìm · đang tải', 'Mỗi lần gõ / đổi chip / đổi sắp xếp: danh sách bị thay hết bằng 6 thẻ khung (tải lại từ đầu, isFirstLoad), app bar giữ số cũ.'],
      ['chip-applying', 'Chip "Đang áp dụng"', 'Chip xanh; app bar "15 giá riêng". Chip không có số.'],
      ['chip-below', 'Chip "Dưới giá sàn"', 'Một thẻ: badge "Đang áp dụng" + "Dưới giá sàn" xếp dọc; giá riêng chữ đỏ.'],
      ['filtered', 'Đang lọc nâng cao', 'Nút lọc nền xanh nhạt, viền + icon xanh, số 2. Không thấy đang lọc theo gì, không có lối xoá lọc nhanh.'],
      ['sorted', 'Đã đổi sắp xếp', '"Sắp xếp: Cảnh báo cần xử lý trước" — thẻ dưới sàn và "Cần kiểm tra" lên đầu.'],
      ['more', 'Đang tải thêm', 'Cuộn tới cuối: một vạch khung 120 × 12 giữa dưới thẻ cuối.'],
      ['end', 'Cuối danh sách', 'Đã tải hết: không có dòng "Đã ở cuối danh sách" (danh sách sản phẩm có).'],
      ['empty', 'Chưa có giá riêng', 'Icon nhãn giá, "Chưa có giá riêng nào", "Tạo giá riêng để bắt đầu.", nút "Thêm giá riêng" cách 32. Nút + nổi cùng hiện (hai lối cùng việc). Ô tìm, chip, sắp xếp vẫn hiện.'],
      ['no-result', 'Tìm không ra', 'Tìm "xyz" → **vẫn câu "Chưa có giá riêng nào" + nút "Thêm giá riêng"** (không có trạng thái "không kết quả" L-04 của TH-04; không có "Xóa từ khoá").'],
      ['error', 'Lỗi tải', 'Cả thân (kể cả ô tìm, chip) thay bằng VEmptyState đỏ: icon mây gạch, "Không tải được danh sách", 2 dòng mô tả, "Thử lại". Không nút +. App bar "0 giá riêng".'],
      ['error-more', 'Lỗi khi tải thêm', 'Đã có dữ liệu mà tải trang sau lỗi: không toast, không nút thử lại; vạch khung cuối danh sách đứng mãi.'],
      ['no-permission', 'Không có quyền xem', 'Vẫn ô tìm, chip, "Sắp xếp"; thân là hộp khoá "Không có quyền truy cập" + "Bạn không có quyền xem danh sách giá riêng."; app bar "0 giá riêng"; không nút +.'],
      ['no-create', 'Xem được, không tạo được', 'Không có nút + (canCreate = false). Nhìn như ca "Có dữ liệu" bỏ nút +.'],
    ],
  },
  {
    id: 'filter', group: 'list', code: 'PR-02', title: 'Bộ lọc giá riêng', route: '/pricing', states: [
      ['default', 'Mới mở', 'showVBottomSheet (không phải sheet thích ứng): web cũng là sheet đáy rộng 640 giữa (M3), không phải hộp thoại. Tiêu đề "Bộ lọc giá riêng" + gạch. 4 nhóm (nhãn bodySmall w600 xám). **Mọi chip đều xanh như đang chọn** (tone primary đặt cứng) → không biết đang chọn gì. Nhóm "Nguồn tạo" còn chip **"Nhập Excel"** dù nhập Excel đã bỏ (6-A). "Đang chọn 0 bộ lọc" caption. "Đặt lại" | "Áp dụng". "Đặt lại" đóng sheet và áp ngay.'],
      ['selected', 'Đã chọn 3 bộ lọc', 'Chọn "Đã tắt", "Tạo thủ công", "30 ngày gần đây" → "Đang chọn 3 bộ lọc"; chip trông y như lúc chưa chọn. Nhóm "Thời gian cập nhật" không có "Tất cả" (bấm lại để bỏ chọn).'],
    ],
  },
  {
    id: 'sort', group: 'list', code: 'PR-02', title: 'Sắp xếp danh sách', route: '/pricing', states: [
      ['default', 'Sắp xếp', 'Sheet không tiêu đề (khác "Bộ lọc giá riêng" có tiêu đề + gạch); nhãn ô "Sắp xếp danh sách" 14 w600; 7 lựa chọn radio; "Áp dụng" đầy ngang. Web: sheet đáy 640.'],
    ],
  },
  {
    id: 'form', group: 'list', code: 'PR-04', title: 'Tạo giá riêng', route: '/pricing/new', states: [
      ['new', 'Mới mở', 'Nút ← arrowBack có thân (màn chọn dùng ‹). Không nút Lưu trên app bar (TH-04 vẽ có): "Hủy | Lưu" ở chân, Lưu mờ. 3 phần tiêu đề H3 18 w600: "Thông tin áp dụng" (3 ô chọn có ›; "Đơn vị bán" mờ "Chọn sản phẩm trước"), "Mức giá áp dụng" (ô tiền hậu tố đ), "Thời gian hiệu lực" ("Từ ngày *" trống "Chọn ngày" — không mặc định hôm nay; "Đến ngày" "Không giới hạn" chữ mờ như gợi ý). Ghi chú 2 dòng + "0/500". Web: cột 720.'],
      ['customer-picked', 'Đã chọn khách + SP', 'Chọn sản phẩm xong: ô "Đơn vị bán" sáng; chưa nhập giá nên chưa có bảng so sánh.'],
      ['filled', 'Đủ thông tin', 'Thẻ so sánh **nền xanh viền xanh** (kể cả khi giá thấp hơn giá hiện tại): "Giá hiện tại 115.741đ", "Giá sàn 90.741đ", "So với giá hiện tại **10.741đ (-9,3%)**" đỏ — **số tiền chênh âm mất dấu trừ**, chỉ % có "-"; "So với giá sàn +14.259đ (+15,7%)" xanh. Giá hiện tại là giá trước VAT (115.741đ) trong khi danh sách ghi "Giá niêm yết 125.000đ". Ô tiền dùng dấu phẩy "105,000" (VMoneyValidator), chỗ khác dấu chấm. Lưu sáng.'],
      ['price-only-list', 'Chưa chọn đơn vị', 'Chọn sản phẩm (chưa chọn đơn vị) đã có "Giá hiện tại" của sản phẩm nhưng chưa có giá sàn → bảng chỉ 2 hàng.'],
      ['below-floor', 'Dưới giá sàn', 'Banner vàng đầu form "Giá riêng thấp hơn giá sàn" + "Bạn vẫn có thể lưu nếu có quyền ghi đè giá sàn." (không biết mình có quyền không). Thẻ so sánh vẫn nền xanh, hai hàng chênh chữ đỏ.'],
      ['above-list', 'Cao hơn giá hiện tại', '"+19.259đ (+16,6%)" xanh: giá riêng cao hơn giá niêm yết cũng tô xanh như tốt.'],
      ['conflict', 'Sau khi báo trùng', 'Máy chủ trả DUPLICATE_ACTIVE_RULE → sau sheet, banner xanh dương "Lưu ý tự động ghi đè giá trùng" + "Xem giá riêng hiện có >" (labelSmall 11, chữ ">" thay icon) ở đầu form, phải cuộn lên mới thấy.'],
      ['submitting', 'Đang lưu', '"Đang lưu..." (không vòng xoay), cả hai nút mờ.'],
      ['save-error', 'Lỗi lưu', 'Toast đỏ "Không thể lưu giá riêng. Vui lòng thử lại." nổi ngay trên hàng "Hủy | Lưu" (không đè). Câu chung cho mọi lỗi không phân loại; không nói lỗi ở ô nào. Web: toast kéo hết bề ngang cửa sổ (trừ lề), không theo cột 720.'],
      ['note-long', 'Ghi chú dài + có ngày đến', 'Ghi chú 2 dòng tự giãn tới 3 dòng; bộ đếm "…/500" góc dưới phải. "Đến ngày" có giá trị.'],
      ['no-permission', 'Không có quyền tạo', 'Cubit phát NoPermission rồi ngay sau đó phát lại form → **màn chặn chỉ hiện một khung hình rồi mất**, người dùng thực tế thấy toast lỗi. Ca này vẽ đúng màn chặn: nút ‹ (không phải ←), hộp khoá tone primary, "Đóng".'],
    ],
  },
  {
    id: 'form-edit', group: 'list', code: 'PR-04', title: 'Sửa giá riêng', route: '/pricing/r1/edit', states: [
      ['edit', 'Sửa', 'App bar "Sửa giá riêng" + tên KH. Thẻ "Thông tin áp dụng" chỉ đọc: avatar + tên + **mã khách dạng UUID** "7c9e6679-7425-…" (không phải SĐT); "Sản phẩm" | "Đơn vị bán" canh phải. Cuối form thẻ xám "Cập nhật gần nhất", "Cập nhật bởi: Nguyễn Thị Lan", "05/10/2026 · 10:21". Không có F-01 (đang tải): form lấy dữ liệu từ màn chi tiết truyền sang; mở thẳng URL thì bị đưa về danh sách.'],
      ['edit-dates', 'Đổi ngày', 'Chỉ đổi "Đến ngày" → banner "Lưu ý tự động ghi đè giá trùng" hiện ngay **dù không có giá riêng nào trùng** (hasConflictingRule = đã đổi ngày).'],
      ['edit-below', 'Sửa · dưới sàn', 'Banner vàng dưới sàn đầu form, trên thẻ thông tin.'],
      ['state-changed', 'Dữ liệu đã đổi', 'STATE_CHANGED: cả form thay bằng hộp vàng "Giá riêng đã được cập nhật" + "Tải lại" (không phải banner + giữ form như TH-04 F-07) → mất phần đang sửa.'],
      ['no-permission', 'Không có quyền sửa', 'Như ca tạo: chỉ một khung hình. "Bạn không có quyền sửa giá riêng".'],
    ],
  },
  {
    id: 'form-sheet', group: 'list', code: 'PR-04', title: 'Sheet của form', route: '/pricing/new', states: [
      ['effective-to', 'Đến ngày', 'Bấm ô "Đến ngày": sheet không tiêu đề, chữ "Đến ngày" H4 giữa, "Chọn ngày cụ thể" (viền) rồi "Không giới hạn" (nút chính xanh) — việc phụ lại là nút chính. "Từ ngày" mở thẳng lịch. Web: sheet đáy 640.'],
      ['overwrite', 'Tự động ghi đè giá trùng?', 'Tên hàm "Dialog" nhưng là sheet đáy; hàng tiêu đề tự vẽ H3 w700 + × 20 (vùng chạm 28); câu xám; banner xanh dương; "Hủy" | "Ghi đè & Lưu" (nút chính xanh, không phải đỏ). Không nói trùng với giá riêng nào.'],
      ['leave', 'Rời khỏi màn hình?', 'Sheet có tiêu đề + gạch (khác hai sheet trên tự vẽ tiêu đề + ×); "Ở lại chỉnh sửa" | "Rời khỏi" (đỏ); khe giữa hai nút 12 (sheet khác 16).'],
      ['save-confirm', 'Lưu thay đổi?', 'Sửa chỉ đổi giá: thẻ "Giá riêng: 105.000đ → 99.000đ" (mũi tên + giá mới xanh) và **"Đến ngày: Không giới hạn → Không giới hạn"** dù không đổi ngày. Ô lý do 3 dòng; bộ đếm "0/200" là chữ tự vẽ dưới ô (ô ghi chú form thì bộ đếm nằm trong ô).'],
      ['save-confirm-dates', 'Lưu thay đổi? · đổi ngày', 'Đổi cả ngày đến → thêm banner "Lưu ý tự động ghi đè"; có lý do "Điều chỉnh theo phụ lục HĐ" → "26/200".'],
    ],
  },
  {
    id: 'pick-customer', group: 'list', code: 'PR-05', title: 'Chọn khách hàng', route: '/pricing/pick-customer', states: [
      ['loaded', 'Danh sách', 'Nút ‹ (form dùng ←). Ô tìm tự focus (viền đậm). Thẻ: ô chữ tắt vuông bo 16 cỡ 52 nền xanh nhạt, tên, email hoặc SĐT, nhãn vai trò ("KH & NCC" / "Khách hàng") cùng kiểu chữ với dòng trên; radio bên phải; thẻ có bóng. "Chọn" đầy ngang, mờ tới khi chọn. Phải chạm thẻ rồi bấm "Chọn" (2 bước), không chọn ngay.'],
      ['selected', 'Đã chọn', 'Thẻ chọn: nền xanh nhạt, viền xanh, bóng đậm hơn, radio xanh. "Chọn" sáng.'],
      ['loading', 'Đang tải', '3 khối xám 72 bo 4 (không phải khung thẻ).'],
      ['empty', 'Không tìm thấy', 'Icon người, "Không tìm thấy khách hàng", "Thử từ khóa khác hoặc kiểm tra chính tả."; "Chọn" mờ vẫn hiện.'],
      ['error', 'Lỗi', 'Hộp lỗi trung tính (không đỏ, khác lỗi danh sách): "Đã xảy ra lỗi" + "Không tải được danh sách khách hàng." + "Thử lại".'],
    ],
  },
  {
    id: 'pick-product', group: 'list', code: 'PR-06', title: 'Chọn sản phẩm', route: '/pricing/pick-product', states: [
      ['loaded', 'Danh sách', 'Ô icon hộp 52 nền trắng (không thấy viền ô) + tên 1 dòng (tên dài bị cắt "…"), "Giá hiện tại: 115.741đ" (giá **trước VAT**, số lẻ), "Đơn vị cơ bản: Hộp". Sản phẩm chưa có giá / chưa có đơn vị: bỏ dòng, thẻ thấp hơn.'],
      ['selected', 'Đã chọn', 'Thẻ đầu nền xanh nhạt + radio xanh.'],
      ['empty', 'Không tìm thấy', 'Icon hộp, "Không tìm thấy sản phẩm".'],
      ['error', 'Lỗi', '"Đã xảy ra lỗi" + "Không tải được danh sách sản phẩm."'],
    ],
  },
  {
    id: 'pick-unit', group: 'list', code: 'PR-07', title: 'Chọn đơn vị bán', route: '/pricing/pick-unit/sp1', states: [
      ['loaded', 'Danh sách', 'Không có ô tìm, không ghi đang chọn đơn vị của sản phẩm nào. Radio bên **trái** (hai màn chọn trước bên phải). "Giá hiện tại: 115.741đ • Giá sàn: 90.741đ"; thiếu giá hiện tại nhưng có sàn → "Giá hiện tại: -- • Giá sàn: 4.000đ"; sàn ẩn ("Thùng") → chỉ giá hiện tại; thiếu cả hai thì bỏ dòng. "Đơn vị cơ bản" dưới tên.'],
      ['selected', 'Đã chọn', 'Thẻ "Hộp" nền xanh nhạt.'],
      ['empty', 'Chưa có đơn vị', 'Icon thước, "Chưa có đơn vị bán", "Sản phẩm này chưa được cấu hình đơn vị bán."'],
      ['error', 'Lỗi', '"Không tải được danh sách đơn vị bán."'],
    ],
  },
  {
    id: 'detail', group: 'detail', code: 'PR-08', title: 'Chi tiết giá riêng', route: '/pricing/r1', states: [
      ['applying', 'Đang áp dụng', 'Ngoài khung. Nút ← là IconButton 48 (form dùng ô 40, màn chọn dùng ‹). App bar "Chi tiết giá riêng" + tên KH. Thẻ đầu không tiêu đề: 4 hàng (icon xanh 18 | nhãn 128 xám | giá trị canh phải bodySmall 13) + "Trạng thái" badge — tên KH lặp lại ngay dưới app bar. Thẻ "Thông tin giá" (H4 w700 + gạch): Giá riêng đậm, Giá niêm yết, Giá sàn, **"Chênh lệch 20.000đ (-16,0%)" đỏ — mất dấu trừ ở phần tiền**, không nói so với gì. "Hiệu lực & nguồn". "Lịch sử gần đây" 3 hoạt động + "Xem tất cả lịch sử ›". Chân: một nút "Thao tác" đầy ngang (mọi việc nằm sau sheet).'],
      ['below-floor', 'Dưới giá sàn', 'Banner vàng "Cần kiểm tra" + "• Giá riêng đang thấp hơn giá sàn hiện tại" (gạch đầu dòng tự ghép), khe 8 (thẻ dưới cách nhau 16). Giá riêng chữ đỏ. Badge vẫn "Đang áp dụng" xanh.'],
      ['needs-review', 'Cần kiểm tra', 'Banner liệt kê **mã lỗi thô "• product_unit_reference_inactive"** từ RPC. Thiếu SĐT → "—"; "Giá niêm yết —", "Giá sàn Ẩn theo quyền" (thật ra là thiếu giá, không phải ẩn), "Chênh lệch —".'],
      ['disabled', 'Đã tắt', 'Banner xanh dương "Giá riêng đã tắt" (thông tin, không cảnh báo); badge "Đã tắt" xám; thêm thẻ "Thông tin tắt" (Người tắt, Thời gian "02/09/2026 16:40" — không có "·" như form, Lý do).'],
      ['disabled-no-reason', 'Đã tắt · thiếu dữ liệu', '"Người tắt —", "Lý do Không có".'],
      ['not-yet', 'Chưa hiệu lực', 'Badge xanh dương "Chưa hiệu lực"; ngày đến có giá trị (chữ mono), "Không giới hạn" thì chữ thường.'],
      ['expired', 'Hết hiệu lực', 'Badge xám (giống "Đã tắt"). Chỉ còn thao tác lịch sử nhưng vẫn phải bấm "Thao tác" mới thấy.'],
      ['floor-hidden', 'Giá sàn ẩn', '"Giá sàn: Ẩn theo quyền" chữ thường (không mono).'],
      ['no-actions', 'Không có thao tác', 'availableActions rỗng → không có thanh chân.'],
      ['no-history', 'Chưa có lịch sử gần đây', 'Thẻ "Lịch sử gần đây" chỉ còn tiêu đề + gạch + "Xem tất cả lịch sử ›" (không câu "chưa có").'],
      ['loading', 'Đang tải', '3 khối xám 120 / 160 / 100; app bar chưa có tên KH; không có chân.'],
      ['not-found', 'Không tìm thấy', 'Icon kính lúp "Không tìm thấy" + "Mức giá riêng này không tồn tại hoặc đã bị xóa."; không nút về danh sách.'],
      ['no-permission', 'Không có quyền', 'Hộp khoá "Không có quyền truy cập".'],
      ['error', 'Lỗi', 'Hộp trung tính "Đã xảy ra lỗi" + "Thử lại".'],
      ['toast-created', 'Vừa tạo xong', 'Từ form quay về: toast "Đã tạo giá riêng thành công" trên thanh "Thao tác" (tiêu đề "Thành công" không hiện).'],
      ['toast-disabled', 'Vừa tắt', 'Toast "Giá riêng sẽ không áp dụng cho đơn hàng mới." (title "Đã tắt giá riêng" không hiện → toast không nói vừa tắt).'],
      ['toast-reenable-error', 'Bật lại lỗi', 'Toast đỏ "Vui lòng thử lại sau." — không nói việc gì lỗi (title "Không thể bật lại" không hiện).'],
    ],
  },
  {
    id: 'detail-sheet', group: 'detail', code: 'PR-08', title: 'Sheet thao tác / tắt / bật lại', route: '/pricing/r1', states: [
      ['actions', 'Thao tác', 'Sheet "Thao tác" + gạch. Hàng: ô icon 40 bo 12 nền màu 10% | nhãn w600 | ›. "Tắt giá riêng" chữ + icon đỏ. Web: sheet đáy 640.'],
      ['actions-disabled', 'Thao tác · đã tắt', '"Bật lại giá riêng" chữ + icon xanh; không có "Sửa giá riêng".'],
      ['disable', 'Tắt giá riêng?', 'Tiêu đề sheet "Tắt giá riêng" + gạch, ngay dưới lại có icon cảnh báo tròn 56 đỏ + "Tắt giá riêng?" (hai tiêu đề gần trùng). Thẻ tóm tắt "105.000đ / Hộp". Ô lý do 2 dòng không bộ đếm. "Giữ giá riêng" | "Tắt giá riêng" (đỏ).'],
      ['disable-submitting', 'Đang tắt', '"Đang tắt..." không vòng xoay, cả hai nút mờ.'],
      ['reenable-loading', 'Bật lại · đang kiểm tra', 'Sheet "Bật lại giá riêng" + gạch; 2 khối xám 56 / 120 (không có chữ "đang kiểm tra").'],
      ['reenable', 'Bật lại giá riêng?', 'Icon ✓ tròn xanh 56 + "Bật lại giá riêng?" dưới tiêu đề sheet gần trùng. Thẻ tóm tắt + "Hiệu lực từ" / "Đến ngày". Banner "Lưu ý" ghi đè **(xoá)** giá trùng. "Giữ đã tắt" | "Bật lại giá riêng".'],
      ['reenable-below', 'Bật lại · dưới sàn', 'Banner vàng "Giá dưới giá sàn" + ô tích "Tôi xác nhận bật lại giá dưới giá sàn"; "Bật lại giá riêng" mờ tới khi tích.'],
      ['reenable-below-ack', 'Bật lại · đã xác nhận', 'Ô đã tích, nút sáng.'],
      ['reenable-blocked', 'Không thể bật lại', 'Icon cảnh báo đỏ + "Không thể bật lại" + "Đã có giá riêng khác đang áp dụng cho cùng khách hàng và sản phẩm." — không có lối mở giá riêng đang chặn. Chỉ còn "Giữ đã tắt" đầy ngang (nút viền làm nút duy nhất).'],
      ['reenable-error', 'Bật lại · lỗi kiểm tra', 'Hộp trung tính "Không thể kiểm tra" + "Thử lại" trong sheet.'],
    ],
  },
  {
    id: 'history', group: 'detail', code: 'PR-10', title: 'Lịch sử giá riêng', route: '/pricing/r1/history', states: [
      ['loaded', 'Có dữ liệu', 'Nút ‹ (chi tiết dùng ←). App bar + tên KH, rồi **tên KH lặp lại** ở hàng ngữ cảnh dưới ô tìm cùng "SP · ĐV" chữ 12 mờ. Chip "Tất cả" | "Sửa giá". "5 kết quả" … "Mới nhất trước ˅" (bấm là đảo, không mở menu). Dòng thời gian: icon tròn 36 theo màu loại + gạch dọc; thẻ: nhãn ngắn ("Sửa giá", "Tắt" — chi tiết dùng "Sửa giá riêng", "Tắt giá riêng"), "người · nguồn" **và** badge nguồn (nguồn hiện 2 lần), ngày giờ, ›. Icon "Sửa" nền trắng (tone primary) khó thấy trên nền xám.'],
      ['quick-price', 'Chip "Sửa giá"', 'Chip "Sửa giá" giữ cả "Tạo giá riêng". Nút lọc sáng xanh + chấm tròn (không có số như danh sách).'],
      ['search', 'Đang tìm', '"đức" → khớp tên người; tìm chỉ theo nhãn hoạt động + tên người, lọc trên các dòng đã tải.'],
      ['filtered', 'Đang lọc', 'Hàng chip đang lọc "Sửa giá ✕", "90 ngày gần đây ✕" (dấu ✕ là ký tự trong chữ) + "Xóa lọc" chữ đỏ.'],
      ['filtered-actor', 'Lọc theo người', 'Lọc theo người thực hiện: nút lọc sáng nhưng **không có chip nào** cho biết đang lọc theo người, vẫn hiện "Xóa lọc".'],
      ['oldest', 'Cũ nhất trước', '"Cũ nhất trước ˅" — đảo các dòng đã tải, không tải lại từ máy chủ.'],
      ['more', 'Đang tải thêm', 'Cuối danh sách một ô xám vuông 40 × 40.'],
      ['empty', 'Chưa có lịch sử', 'Vòng trắng 64 icon đồng hồ + "Chưa có lịch sử thay đổi" (H4 w700) + câu + "Quay lại chi tiết" (nút viền) — ô tìm, chip, "0 kết quả" vẫn hiện bên trên.'],
      ['no-result', 'Tìm không ra', '"giá sàn" → "Không tìm thấy lịch sử phù hợp" + "Đặt lại bộ lọc" (đúng TH-04).'],
      ['loading', 'Đang tải', 'Khối 44 + 32 + 4 khối 80 (khung giả ô tìm, chip); app bar chưa có tên KH.'],
      ['error', 'Lỗi', 'Vòng đỏ 64 + "Không tải được lịch sử" + "Thử lại" (nút viền). Kiểu trạng thái riêng (không VEmptyState như danh sách / chi tiết).'],
      ['no-permission', 'Không có quyền', 'Vòng khoá + "Bạn không có quyền xem lịch sử giá riêng" + "Quay lại" (nút viền).'],
      ['long-name', 'Tên dài', 'Hàng ngữ cảnh là Row không co: "Công ty TNHH Thú y An Phát" + "Dầu tắm trị ve rận cho chó mèo 250ml · Chai" **tràn mép phải** (Flutter debug hiện sọc vàng đen; bản phát hành bị cắt).'],
    ],
  },
  {
    id: 'history-sheet', group: 'detail', code: 'PR-10', title: 'Sheet lịch sử', route: '/pricing/r1/history', states: [
      ['filter', 'Bộ lọc lịch sử', 'Sheet không tiêu đề; tự vẽ "Bộ lọc lịch sử" H3 w700, **không gạch, không ×** (bộ lọc danh sách có tiêu đề + gạch). Nhãn nhóm 14 w600 đen (danh sách: 13 xám). Chip có đổi màu khi chọn (danh sách thì không). "Người thực hiện": **"Tất cả" nằm CUỐI** (sắp theo mã ký tự). "Thời gian" có 90 ngày (danh sách: 7 / 30).'],
      ['filter-selected', 'Bộ lọc · đã chọn', '"Sửa giá", "Trần Minh Đức", "30 ngày gần đây" xanh.'],
      ['activity', 'Chi tiết hoạt động · sửa', 'Sheet "Chi tiết hoạt động" + gạch. Thẻ đầu icon tròn 44 + "Sửa giá riêng" + "05/10/2026 10:21 · Nguyễn Thị Lan" + "Nguồn: Tạo thủ công". Bảng "So sánh trước / sau" luôn đủ 4 hàng dù chỉ đổi giá; cột "Sau" của giá luôn xanh đậm. "Chênh lệch giá sàn +12.000đ → +7.000đ". "Xem chi tiết giá riêng >" nút viền (">" là chữ) — bấm chỉ quay lại màn chi tiết.'],
      ['activity-created', 'Chi tiết hoạt động · tạo', 'Tạo mới: cột "Trước" của "Ngày bắt đầu" ghi **"Không giới hạn"** (giá trị rỗng mặc định của ngày), giá "—", chênh lệch sàn "-" (gạch ngắn). Không có lý do → "Không có ghi chú" nghiêng.'],
    ],
  },
];

export const CASES = Object.fromEntries(SCREENS.map((s) => [s.id, s.states.map(([id]) => id)]));
