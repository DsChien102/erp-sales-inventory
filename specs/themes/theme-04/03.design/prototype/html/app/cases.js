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
];

export const CASES = Object.fromEntries(SCREENS.map((s) => [s.id, s.states.map(([id]) => id)]));
