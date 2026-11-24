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
  {
    id: 'detail', group: 'detail', code: 'PT-07', title: 'Hồ sơ KH & NCC', route: '/partner/p1', states: [
      ['org-both', 'Tổ chức KH & NCC', 'Avatar 64 + tên H3 + "Tổ chức • KH & NCC" + thẻ trạng thái (kiểu riêng: bo 4, 11 px — khác VBadge ở danh sách); hàng SĐT  •  MST; các thẻ đều đóng (ListTile dense 48): Thông tin, Công nợ (Theme 6, kiểu thẻ riêng có chevron), Người liên hệ "2", Hóa đơn, Địa chỉ, Ghi chú… Hàng nút "Chỉnh sửa" (viền, chữ xanh) | "Thao tác ˄". Web: cột phải 679 → thân cột 640 canh giữa nên hàng nút đáy không chạm hai mép cột; không có nút ←; danh sách bên trái đánh dấu dòng đang mở. iPhone: có nút ‹, thanh dưới vẫn hiện.'],
      ['org-both-end', 'Tổ chức · cuộn cuối', 'Khối NCC (Theme 7) sau Ghi chú: "Chương trình ưu đãi" là VCard (viền đậm) chứa dòng VListRow + nhãn trạng thái + thanh tiến độ; "Lịch sử nhập hàng" không có thẻ bọc, mỗi phiếu là một VCard riêng, ngày dạng "2026-11-18" (chuỗi thô từ DB), tiền "đ" (Công nợ dùng "₫"). Cuối cùng "Lịch sử thao tác " (icon bánh răng).'],
      ['org-expanded', 'Tổ chức · mở thẻ', 'Thông tin tổ chức mở: nhãn 11 px, giá trị 14; ô trống ghi "—". Người liên hệ mở: tối đa 2 người (chính lên đầu, thẻ "Chính"), gạch, "⊕ Thêm người liên hệ" | "Xem tất cả (2) ›".'],
      ['blocks-loading', 'Khối Theme 6 / 7 đang tải', 'Công nợ chưa tải → không vẽ gì nhưng khe 8 vẫn còn (hai khe liền nhau); Chương trình ưu đãi: khối xám 44; Lịch sử nhập hàng: vòng xoay Material giữa khối.'],
      ['programs-error', 'Chương trình ưu đãi lỗi', '"Không tải được chương trình ưu đãi." + "Thử lại" (tertiary). Lịch sử nhập hàng lỗi thì không báo lỗi: hiện như chưa có phiếu.'],
      ['person-missing', 'Cá nhân thiếu hoá đơn', 'Banner vàng "Hồ sơ còn thiếu thông tin / Thiếu MST và địa chỉ hóa đơn." Thẻ Hóa đơn có nhãn đỏ "Thiếu MST và địa chỉ" (chữ khác banner); Địa chỉ, Ghi chú nhãn vàng "Chưa có"; Công nợ "Không còn nợ". Không có thẻ Người liên hệ (cá nhân).'],
      ['person-expanded', 'Cá nhân · mở nhiều thẻ', 'Thông tin cá nhân, Hóa đơn, Địa chỉ, Ghi chú mở: hàng loạt "—".'],
      ['supplier-empty', 'NCC chưa có chương trình / phiếu', 'Không có Công nợ (không phải khách). "Chưa có chương trình đang chạy." + "+ Tạo chương trình"; Lịch sử nhập hàng chỉ còn một dòng chữ mặc định (không tiêu đề, không DS).'],
      ['person-both', 'Cá nhân KH & NCC', 'Công nợ "Còn nợ 2.350.000 ₫ · 1 đơn" (chưa quá hạn: không nhãn); chương trình rỗng; 1 phiếu nhập.'],
      ['inactive', 'Ngừng hoạt động', 'Banner vàng "KH & NCC này sẽ không được chọn cho giao dịch mới." (không có banner thiếu thông tin dù thiếu); thẻ "Ngừng hoạt động" vàng.'],
      ['system', 'Đối tác hệ thống "Mua lẻ / khác"', 'Banner xanh "Đối tác hệ thống… Không sửa hoặc xoá được."; không có hàng nút đáy; không có khối NCC dù có vai trò NCC; thẻ Người liên hệ vẫn có "Thêm người liên hệ"; nhãn đỏ "Thiếu MST, tên HĐ và địa chỉ".'],
      ['system-end', 'Đối tác hệ thống · cuộn cuối', 'Thẻ "Lịch sử thao tác" vẫn mở được.'],
      ['loading', 'Đang tải', 'Khung xám: tròn 64 + 3 vạch; 5 hàng thẻ 48 viền nhạt.'],
      ['error', 'Lỗi tải', 'Ô icon mây 64 + "Không tải được hồ sơ" + nút viền rộng 220 "Thử lại" (khác danh sách: nút chính).'],
      ['not-found', 'Không tìm thấy', 'Hình ghép: tài liệu mờ 90 + "?" + kính lúp 64; "Không tìm thấy hồ sơ"; "Quay lại".'],
      ['contact-only', 'Chỉ là người liên hệ', '"Không phải hồ sơ đối tác" + "Người liên hệ chỉ quản lý trong hồ sơ tổ chức…".'],
      ['no-permission', 'Không có quyền', 'Khiên mờ 120 + vòng "?"; "Không có quyền xem hồ sơ".'],
      ['toast-created', 'Toast tạo xong', '"Đã tạo KH & NCC thành công". Web: toast nằm trong cột phải, đè hàng nút đáy. iPhone: nổi ngay trên thanh dưới, đè hàng nút.'],
      ['toast-updated', 'Toast cập nhật', '"Đã cập nhật hồ sơ KH & NCC" (không có dấu chấm; "Đã ngừng hoạt động KH & NCC." có).'],
      ['toast-deactivated', 'Toast ngừng hoạt động', '"Đã ngừng hoạt động KH & NCC."'],
      ['toast-failed', 'Toast lỗi', 'VToast đỏ "Hồ sơ đã được cập nhật bởi người khác. Vui lòng tải lại."'],
      ['toast-transformed', 'Toast chuyển đổi', 'Toast tự vẽ (không phải VToast): chấm 24, × 20 mờ không có vùng chạm 44, đệm 14.'],
    ],
  },
  {
    id: 'detail-sheet', group: 'detail', code: 'PT-07', title: 'Thao tác hồ sơ (sheet)', route: '/partner/p1', states: [
      ['actions-person', 'Thao tác · cá nhân', 'Sheet không tiêu đề, chữ "Thao tác hồ sơ" H3 trong nội dung; 3 thẻ (Chuyển thành tổ chức, Ngừng hoạt động, Xóa hồ sơ) mỗi thẻ có ›; "Hủy" viền đầy ngang. Web: hộp thoại không tiêu đề → nút Đóng góc + đệm đôi.'],
      ['actions-org', 'Thao tác · tổ chức', 'Không có "Chuyển thành tổ chức".'],
      ['actions-inactive', 'Thao tác · đang ngừng', '"Kích hoạt lại" (icon nguồn xanh).'],
      ['deactivate', 'Ngừng hoạt động?', 'Vòng vàng 64; câu 2 dòng; "Lý do (không bắt buộc)" + ô 3 dòng + "0/200"; nút xác nhận "Ngừng hoạt động" màu xanh chính (không phải vàng / đỏ).'],
      ['deactivate-primary', 'Ngừng · đang là liên hệ chính', 'Banner vàng tiêu đề rỗng: hàng icon trơ, câu thụt 32.'],
      ['reactivate', 'Kích hoạt lại?', 'Vòng xanh 64 + câu + "Hủy" | "Kích hoạt lại".'],
      ['delete-confirm', 'Xóa hồ sơ?', 'Nút × riêng 32 ở góc (web: thêm nút Đóng của hộp thoại → hai ×); vòng đỏ; câu đậm "không xóa giao dịch…"; "Xóa hồ sơ" đỏ.'],
      ['delete-blocked', 'Không thể xóa (có giao dịch)', 'Icon cảnh báo 56 không hộp (khác vòng 64 của các sheet khác); "Quay lại" | "Ngừng hoạt động".'],
      ['delete-blocked-inactive', 'Không thể xóa · đang ngừng', 'Chỉ còn "Quay lại" đầy ngang.'],
      ['transform-primary-blocked', 'Không thể chuyển (liên hệ chính)', 'Bấm "Chuyển thành tổ chức" khi cá nhân đang là liên hệ chính của tổ chức khác: như sheet chặn xoá — tay kéo tự vẽ (iPhone hai tay kéo), icon tổ chức 44 vàng, "Đóng" | "Xem tổ chức".'],
      ['add-contact-method', 'Thêm người liên hệ (từ hồ sơ)', 'Bấm "Thêm người liên hệ" trong thẻ: sheet 2 lựa chọn. iPhone: mở trong vùng tab nên "Hủy" sát mép dưới sheet (SafeArea = 0, không có khe dưới). Khe chữ → › thẻ 1 là 8, thẻ 2 là 16.'],
      ['delete-primary-blocked', 'Không thể xóa (liên hệ chính)', 'Sheet tự vẽ thêm tay kéo 40 × 4 → iPhone có hai tay kéo; icon thùng rác 44 đỏ không hộp; "Đóng" | "Xem tổ chức". Cùng tiêu đề "Không thể xóa hồ sơ" với sheet trên nhưng icon / khe khác.'],
    ],
  },
  {
    id: 'history', group: 'detail', code: 'PT-12', title: 'Lịch sử thao tác', route: '/partner/p1/history', states: [
      ['loaded', 'Có dữ liệu', 'Toàn màn (ngoài khung, web không thanh bên); app bar có dòng phụ tên đối tác + nút ← 24 (arrowBack). Thẻ: tiêu đề đậm | ngày "2026-11-21 16:40" (định dạng khác dd/MM/yyyy ở danh sách); thay đổi "Nhãn: cũ → mới" sắp theo nhãn; "Lý do: …" nghiêng; "bởi 3f9a2c1b" = 8 ký tự đầu mã người dùng, không phải tên. "Tạo đối tác" không có dòng thay đổi. Chỉ tải 20 dòng đầu, không tải thêm.'],
      ['loading', 'Đang tải', 'Vòng xoay Material giữa màn.'],
      ['empty', 'Trống', '"Chưa có lịch sử thao tác nào" + mô tả.'],
      ['error', 'Lỗi', 'Ô icon cảnh báo đỏ + tiêu đề đỏ + câu lỗi chung + "Thử lại".'],
    ],
  },
  {
    id: 'contacts', group: 'contacts', code: 'PT-08', title: 'Người liên hệ', route: '/partner/p1/contacts', states: [
      ['loaded', 'Có người liên hệ', 'Toàn màn (ngoài khung, web không thanh bên); tiêu đề giữa; "⋯" góc phải bấm không làm gì. Thẻ xanh nhạt tên tổ chức + "Tổ chức • KH & NCC"; ô tìm; "3 người liên hệ"; dòng có gạch ngăn (không phải thẻ như danh sách đối tác); thẻ "Chính" / "Ngừng hoạt động" caption bo 4. Nút + nổi (mặc định xanh).'],
      ['search', 'Đang tìm', 'Lọc trên máy "hà" → 1 người; số đếm đổi theo.'],
      ['empty', 'Chưa có', 'Hình ghép 3 vòng người + chấm "+"; "Chưa có người liên hệ"; nút viền "Gợi ý thêm người liên hệ" (chữ khác "Thêm người liên hệ"); không có ô tìm; nút + vẫn hiện.'],
      ['loading', 'Đang tải', 'Vòng xoay Material giữa màn; không nút +.'],
      ['error', 'Lỗi', 'Icon lỗi 48 đỏ + "Đã xảy ra lỗi" (H3 w600) + câu lỗi + "Quay lại" — kiểu thứ ba của trạng thái lỗi trong theme.'],
      ['no-permission', 'Không có quyền', '"Không có quyền quản lý người liên hệ".'],
      ['toast-added', 'Toast thêm xong', '"Thêm người liên hệ thành công" (câu khác kiểu "Đã …" của hồ sơ).'],
    ],
  },
  {
    id: 'contact-sheet', group: 'contacts', code: 'PT-08', title: 'Sheet người liên hệ', route: '/partner/p1/contacts', states: [
      ['add-method', 'Thêm người liên hệ', 'Mở từ PT-08 (ngoài khung): iPhone có vùng an toàn đáy. Web: hộp thoại không tiêu đề + VPagePadding → chữ cách mép 32.'],
      ['actions', 'Thao tác liên hệ', '"Thao tác" H3 + gạch + 3 ListTile (56, icon 24): Chỉnh sửa liên hệ, Đặt làm chính, Gỡ khỏi tổ chức (đỏ, › đỏ) + "Hủy". Kiểu khác sheet thao tác hồ sơ (thẻ có vòng icon).'],
      ['actions-primary', 'Thao tác · người chính', 'Không có "Đặt làm chính".'],
      ['change-primary', 'Đổi người liên hệ chính?', 'Widget tự bọc VBottomSheet trong showVAdaptiveSheet → iPhone: hai tay kéo, sheet lồng sheet; web: trong hộp thoại có tay kéo và bo trên. Hai avatar 48 + mũi tên.'],
      ['remove', 'Gỡ người liên hệ?', 'Không icon đầu (khác các sheet xác nhận của hồ sơ); khe giữa hai nút 8 (sheet khác 12); "Gỡ liên hệ" đỏ.'],
    ],
  },
  {
    id: 'contact-form', group: 'contacts', code: 'PT-09', title: 'Thêm / sửa người liên hệ', route: '/partner/p1/contacts/new', states: [
      ['new', 'Thêm mới', '"Hủy" / "Lưu" là nút chữ trên app bar (form hồ sơ dùng hàng nút đáy); tiêu đề giữa; 6 ô cách 16; công tắc "Người liên hệ chính" + câu phụ. Thứ tự vai trò khác TH-03.'],
      ['filled', 'Đã nhập', 'Công tắc bật.'],
      ['errors', 'Lỗi', '"Vui lòng nhập họ tên" (form hồ sơ: "Vui lòng nhập họ và tên"), "Vui lòng chọn vai trò", SĐT không hợp lệ.'],
      ['submitting', 'Đang lưu', 'Các ô mờ; không có vòng xoay nào; "Lưu" trên app bar vẫn bấm được.'],
      ['server-error', 'Lỗi máy chủ', 'Hộp đỏ nhạt tự vẽ (không phải VBanner) ở đầu form.'],
      ['edit', 'Sửa liên hệ', '"Chỉnh sửa liên hệ"; dữ liệu điền sẵn.'],
      ['edit-loading', 'Sửa · đang tải', 'Vòng xoay Material.'],
    ],
  },
  {
    id: 'contact-select', group: 'contacts', code: 'PT-10', title: 'Chọn từ cá nhân', route: '/partner/p1/contacts/select', states: [
      ['loaded', 'Danh sách', 'Ô chọn tròn 22 (chọn nhiều nhưng trông như radio); "Chọn (0)" mờ. Hàng nút nằm trong thân → web hẹp theo cột 720.'],
      ['selected', 'Đã chọn 2', '"Chọn (2)" bật; vòng xanh có dấu ✓.'],
      ['empty', 'Không có kết quả', 'Một dòng chữ giữa màn "Không tìm thấy cá nhân nào." (không VEmptyState).'],
      ['loading', 'Đang tải', 'Vòng xoay Material.'],
      ['error', 'Lỗi', 'Chỉ một dòng chữ đỏ giữa màn, không có nút thử lại.'],
    ],
  },
  {
    id: 'transform', group: 'contacts', code: 'PT-11', title: 'Chuyển thành tổ chức', route: '/partner/p2/transform', states: [
      ['step1', 'Bước 1 · trống', 'Tiêu đề giữa; nút ← arrowBack. Đệm thân 12 (màn khác 16). Thanh 3 bước chia 5 phần bằng nhau; dưới là vạch 96 × 4 giống tay kéo. Nhãn ô là chữ xám 13 (không phải VFieldLabel 14 đậm như form hồ sơ), ô cách 8. Không điền sẵn SĐT / email của cá nhân. "Huỷ" (chữ "uỷ", nơi khác "Hủy").'],
      ['step1-errors', 'Bước 1 · lỗi', 'Lỗi dưới ô + banner vàng "Không thể chuyển đổi khi thiếu thông tin bắt buộc hoặc dữ liệu bị trùng."; "Tiếp" mờ tới khi hợp lệ.'],
      ['step1-filled', 'Bước 1 · đã nhập', 'Đủ thông tin.'],
      ['step1-duplicate', 'Bước 1 · trùng SĐT', 'Máy chủ báo trùng → quay về bước 1, lỗi dưới ô SĐT, không có banner, "Tiếp" vẫn bật.'],
      ['step2', 'Bước 2 · xem trước', '"Xem trước chuyển đổi"; vạch dưới thanh bước rộng 44 (bước 1: 96). Hai khối "Trước / Sau khi chuyển" nền surfaceAlt trùng nền trang (không thấy khối) + mũi tên xanh; thẻ người liên hệ chính; banner info; "Quay lại" | "Xác nhận". Bước 3 "Xác nhận" trên thanh không bao giờ sáng.'],
      ['step2-error', 'Bước 2 · lỗi', 'Banner vàng "Không thể chuyển đổi hồ sơ. Vui lòng thử lại." dưới thanh bước.'],
      ['confirm', 'Hộp thoại xác nhận', 'Dialog Material (cả iPhone; các xác nhận khác là sheet): vòng vàng 58 viền 2; tiêu đề giữa nhưng 3 câu canh trái.'],
      ['submitting', 'Đang chuyển', 'Lớp phủ màu textPrimary (gần đen, đặc) che toàn thân + vòng xoay xanh.'],
      ['blocked-permission', 'Không có quyền', 'Khiên mờ + dấu +; "Không có quyền chuyển đổi"; nút viền đầy ngang (lỗi hồ sơ: rộng 220).'],
      ['blocked-stale', 'Dữ liệu đã đổi', 'Mây mờ + cảnh báo đỏ; "Dữ liệu đã thay đổi"; "Tải lại".'],
    ],
  },
];

export const CASES = Object.fromEntries(SCREENS.map((s) => [s.id, s.states.map(([id]) => id)]));
