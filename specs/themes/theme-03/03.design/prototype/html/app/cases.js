// Danh sách ca dùng chung: main.js, viewer.js, tools/capture.mjs.
// Mỗi màn thuộc một nhóm (đợt): list (đợt 1), detail (đợt 2), contacts (đợt 3).
// Mỗi state: [mã, nhãn ngắn, điều cần nhìn]. Mỗi ca vẽ ở cả hai khổ (iPhone 390, Web 1280).
export const GROUPS = [
  { id: 'list', title: 'Danh sách & tạo (đợt 1)' },
  { id: 'detail', title: 'Hồ sơ (đợt 2)' },
  { id: 'contacts', title: 'Liên hệ & chuyển đổi (đợt 3)' },
];

export const SCREENS = [
  {
    id: 'list', group: 'list', code: 'PT-01', title: 'Danh sách KH & NCC', route: '/partner', states: [
      ['loaded', 'Có dữ liệu (L-02)', 'App bar "KH & NCC" + "48 đối tác"; ô tìm + nút lọc 44; 4 chip nhanh; "Danh sách đối tác" / "Sắp xếp"; thẻ: avatar chữ tắt, tên, "Loại · Vai trò", SĐT, MST, "Cập nhật …", nhãn trạng thái (đang hoạt động cỡ thường, ngừng hoạt động cỡ nhỏ). "Mua lẻ / khác" (đối tác hệ thống) nằm lẫn trong danh sách. Web: 2 cột, danh sách 360 + cột phải "Chọn một KH & NCC để xem chi tiết."; nút + bị đẩy vào trong 280 px (gutter tính theo cửa sổ 1280) nên nằm sát mép trái cột danh sách.'],
      ['loading', 'Đang tải (L-01)', '8 khối xám 128 (bo 12). App bar ghi "0 đối tác" khi chưa có tổng lần nào.'],
      ['search', 'Đang tìm', 'Từ khoá "thú y": nút × trong ô tìm; đầu danh sách "3 kết quả phù hợp"; hết trang → "Đã ở cuối danh sách".'],
      ['quick-filter', 'Chip nhanh', 'Chọn "Khách hàng": chip xanh; nút lọc có số 1 (chip nhanh cũng đếm vào bộ lọc) và viền xanh; "31 kết quả phù hợp".'],
      ['filtered', 'Đang lọc nhiều', 'Vai trò + loại + trạng thái → số 3 trên nút lọc. Không có hàng chip "đang áp" + "Xóa lọc" (PartnerActiveFilters có code nhưng không được dùng) nên không thấy đang lọc gì, chỉ chip vai trò.'],
      ['end', 'Cuối danh sách (L-05)', '"Đã ở cuối danh sách" labelSmall xám, canh giữa dưới thẻ cuối.'],
      ['more', 'Đang tải thêm', 'Cuộn tới cuối: thêm khối xám dưới thẻ cuối (Flutter thêm 20 khối = pageSize).'],
      ['empty', 'Trống (L-03)', 'Hộp trắng (không viền) ở đầu vùng danh sách, không canh giữa dọc: "Chưa có KH & NCC" + mô tả + nút chữ "Thêm KH & NCC". Nút + nổi vẫn hiện.'],
      ['empty-no-create', 'Trống, không có quyền tạo', 'Không nút "Thêm KH & NCC", không nút +.'],
      ['filter-empty', 'Lọc không ra kết quả', 'Đang lọc (không từ khoá) mà rỗng → vẫn hiện "Chưa có KH & NCC / Thêm đối tác để bắt đầu…" như chưa có đối tác nào; đầu danh sách ghi "0 kết quả phù hợp".'],
      ['no-result', 'Không kết quả (L-04)', '"Không tìm thấy kết quả" + câu có từ khoá + "Xóa từ khóa" (nút chữ).'],
      ['error', 'Lỗi tải (L-06)', 'Biểu tượng mây gạch nền đỏ nhạt, tiêu đề chữ đỏ, mô tả, "Thử lại" (nút chính) canh giữa vùng còn lại; ô tìm / chip / "Sắp xếp" vẫn bấm được.'],
      ['view-only', 'Chỉ có quyền xem', 'Không có partner.create: không có nút +.'],
      ['no-permission', 'Không có quyền xem (L-07)', 'Cả khu (danh sách và cột phải) thay bằng một trang "KH & NCC" + ổ khoá + "Bạn không có quyền xem KH & NCC". Web: không còn 2 cột.'],
    ],
  },
  {
    id: 'filter', group: 'list', code: 'PT-02', title: 'Bộ lọc / Sắp xếp', route: '/partner', states: [
      ['filter', 'Bộ lọc', 'Sheet không tiêu đề: "Bộ lọc KH & NCC" (H4), 4 nhóm chip; "Thời gian cập nhật" là 3 chip chia đều (iPhone: chữ bị cắt "…", chữ canh trái). "Tùy chọn" bấm không làm gì. Vai trò không có chip "Tất cả" (Trạng thái thì có). "Đặt lại" | "Áp dụng". iPhone: sheet mở trong vùng tab nên thanh dưới vẫn hiện, không bị phủ tối. Web: hộp thoại 480 có đệm 16 / 24 + đệm riêng 16 của nội dung.'],
      ['filter-selected', 'Bộ lọc đã chọn', 'Khách hàng + Tổ chức + Đang hoạt động + 7 ngày.'],
      ['sort', 'Sắp xếp', 'Nhãn "Sắp xếp danh sách" + 4 radio (mỗi dòng cao 64 + khe 12) + "Áp dụng".'],
    ],
  },
  {
    id: 'create-type', group: 'list', code: 'PT-03', title: 'Thêm KH & NCC mới', route: '/partner', states: [
      ['default', 'Chọn loại hồ sơ', 'Sheet có tiêu đề "Thêm KH & NCC mới" + gạch; 2 thẻ (ô icon nền xanh nhạt, tiêu đề H4, mô tả, mũi tên ›). Web: hộp thoại có tiêu đề + nút Đóng.'],
    ],
  },
  {
    id: 'form', group: 'list', code: 'PT-05', title: 'Tạo / sửa hồ sơ', route: '/partner/new', states: [
      ['person-new', 'Tạo cá nhân · mới mở', 'Toàn màn (ngoài khung, web không thanh bên); nút ← là ô 40 icon 20 (khác nút ← 24 của màn khác). Mục "1. Loại hồ sơ" khoá; "2. Vai trò" mở sẵn; các mục khác đóng, mục "4. Hóa đơn / thuế" không có chữ phụ (khác các mục "Tùy chọn"). "Lưu & Xem" mờ, không nói vì sao. Viền mục borderDefault (nhạt hơn thẻ danh sách). iPhone: hàng nút dưới không chừa vùng an toàn đáy (34).'],
      ['person-role-error', 'Vai trò · chưa chọn', 'Bấm "Tiếp" khi chưa chọn: dòng đỏ "Vui lòng chọn vai trò giao dịch" dưới chip.'],
      ['person-main', 'Thông tin cá nhân · trống', 'Vai trò ✓ "Khách hàng". Khe giữa "Danh xưng" và "Họ và tên" 8, các ô sau 16.'],
      ['person-main-filled', 'Thông tin cá nhân · đã nhập', 'Đủ tên + SĐT → "Lưu & Xem" bật.'],
      ['person-main-errors', 'Thông tin cá nhân · lỗi', 'Bấm Tiếp / Lưu: lỗi dưới tên, SĐT, email; lỗi chỉ hiện trong mục đang mở.'],
      ['person-collapsed', 'Mọi mục đóng', 'Chạm tiêu đề mục đang mở → đóng hết; chữ phụ: "Khách hàng", tên, MST, "Tùy chọn"…; ✓ xanh cho mục đã "Tiếp".'],
      ['person-invoice', 'Hóa đơn / thuế (cá nhân)', 'MST không bắt buộc; ô MST → khe 8 → tên HĐ → khe 16 → email → khe 8 → địa chỉ (khe không đều). Không có cảnh báo.'],
      ['org-new', 'Tạo tổ chức · mới mở', '7 mục (thêm "4. Người liên hệ chính").'],
      ['org-main', 'Thông tin tổ chức', 'Ô chọn "Loại tổ chức" (VSelect, mũi tên xám) + 5 ô cách nhau 8 (cá nhân cách 16).'],
      ['org-contact-off', 'Người liên hệ chính · tắt', 'Mục mở có chữ phụ "Tùy chọn"; chỉ một ô tick "Thêm người liên hệ chính".'],
      ['org-contact', 'Người liên hệ chính · bật', 'Tick bật → 5 ô (khe 16).'],
      ['org-invoice', 'Hóa đơn / thuế (tổ chức) · trống', 'MST, tên HĐ, địa chỉ HĐ có dấu * nhưng không chặn lưu; banner vàng "Thiếu MST, tên xuất hóa đơn và địa chỉ hóa đơn. Vui lòng kiểm tra lại trước khi lưu." hiện ngay khi mở mục.'],
      ['org-invoice-partial', 'Hóa đơn / thuế · thiếu 2', 'Banner "Thiếu tên xuất hóa đơn và địa chỉ hóa đơn…".'],
      ['delivery-empty', 'Địa chỉ giao hàng · trống', 'Nhãn kiểu khác (bodySmall đậm 13) so với nhãn ô khác (H4 14); ô tỉnh viền borderStrong (ô nhập khác borderInput đậm hơn); ô xã tắt "Chọn tỉnh / thành phố trước".'],
      ['delivery', 'Địa chỉ giao hàng · đã chọn', 'Tên tỉnh / xã chữ đậm + nút × thay mũi tên.'],
      ['note', 'Ghi chú', 'Không có hàng Bỏ qua / Tiếp; ô ghi chú dày đặc (đệm 4 / 8, chữ cao 1.2) + "38/500" góc dưới phải.'],
      ['submitting', 'Đang lưu', '"Lưu & Xem" có vòng xoay, "Hủy" mờ.'],
      ['general-error', 'Lỗi lưu', 'Banner đỏ chỉ có tiêu đề ngay dưới mục 1.'],
      ['blocked', 'Không có quyền tạo', 'Banner đỏ "Bạn chưa có quyền tạo KH & NCC."; form vẫn sửa được nhưng "Lưu & Xem" tắt.'],
      ['edit-loading', 'Sửa · đang tải', 'Mở sửa một tổ chức: tiêu đề tạm ghi "Chỉnh sửa cá nhân" (loại mặc định); vòng xoay Material (không phải VLoading).'],
      ['edit', 'Sửa tổ chức', '"Chỉnh sửa tổ chức"; 6 mục (không có người liên hệ chính) nên số mục 4 / 5 / 6; "Lưu thay đổi" tắt tới khi sửa gì đó; mục đóng không có ✓ dù đã có dữ liệu.'],
      ['edit-dirty', 'Sửa · đã đổi', 'Đổi SĐT → "Lưu thay đổi" bật.'],
      ['edit-conflict', 'Sửa · xung đột phiên bản', 'Banner đỏ "Hồ sơ đã được cập nhật bởi người khác. Vui lòng tải lại rồi thử lại." — không có nút tải lại.'],
      ['leave', 'Rời khỏi màn hình?', 'Bấm ← / Hủy khi đã nhập: sheet có tiêu đề + gạch; "Ở lại chỉnh sửa" | "Rời khỏi" (đỏ).'],
    ],
  },
  {
    id: 'duplicate', group: 'list', code: 'PT-04', title: 'Trùng hồ sơ', route: '/partner/new', states: [
      ['exact', 'Trùng khớp hoàn toàn', 'Vòng đỏ 48 + "Trùng khớp hoàn toàn" (H3 w600) + câu + thẻ hồ sơ "SĐT: …" + "Đi đến hồ sơ" | "Quay lại". Web: hộp thoại không tiêu đề.'],
      ['possible', 'Có thể trùng', 'Vòng vàng; 2 thẻ; "Tiếp tục tạo mới" | "Xem chi tiết" — "Xem chi tiết" luôn mở hồ sơ đầu tiên; không có nút quay lại (chỉ vuốt / Đóng).'],
    ],
  },
  {
    id: 'picker', group: 'list', code: 'PT-06', title: 'Chọn khu vực hành chính', route: '/partner/new', states: [
      ['province', 'Chọn tỉnh', 'Cao 75% màn; tiêu đề + nút Đóng; ô tìm; 2 bước (số 1 nền xanh, số 2 xám mờ); danh sách 34 tỉnh sắp theo mã ký tự: "Thành phố …" trước "Tỉnh …", tên bắt đầu bằng "Đ" xuống cuối nhóm; mỗi dòng có "N xã/phường". Web: hộp thoại không tiêu đề → hai nút Đóng chồng góc phải.'],
      ['province-selected', 'Tỉnh đã chọn', 'Mở lại khi đã có tỉnh: dòng "Thành phố Cần Thơ" nền xanh nhạt + ✓; bước 1 hiện tên tỉnh dưới nhãn.'],
      ['province-empty', 'Tìm không thấy', '"Không tìm thấy tỉnh / thành phố" + câu có từ khoá.'],
      ['ward', 'Chọn xã', 'Bước 1 dấu ✓ + tên tỉnh, bước 2 đang chọn; ô tìm "Tìm kiếm xã, phường tại Thành phố Cần Thơ..."; dòng xã không có số đếm.'],
    ],
  },
];

export const CASES = Object.fromEntries(SCREENS.map((s) => [s.id, s.states.map(([id]) => id)]));
