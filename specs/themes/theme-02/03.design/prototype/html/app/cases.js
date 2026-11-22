// Danh sách ca dùng chung: main.js, viewer.js, tools/capture.mjs.
// Mỗi màn thuộc một nhóm (đợt): list (đợt 1), pcc (đợt 2), sub (đợt 3), settings (đợt 4).
// Mỗi state: [mã, nhãn ngắn, điều cần nhìn]. Mỗi ca vẽ ở cả hai khổ (iPhone 390, Web 1280).
export const GROUPS = [
  { id: 'list', title: 'Danh sách & tạo (đợt 1)' },
  { id: 'pcc', title: 'PCC (đợt 2)' },
  { id: 'sub', title: 'Màn con của sản phẩm (đợt 3)' },
  { id: 'settings', title: 'Cài đặt sản phẩm (đợt 4)' },
];

export const SCREENS = [
  {
    id: 'list', group: 'list', code: 'SP-01', title: 'Danh sách sản phẩm', route: '/products/items', states: [
      ['loaded', 'Có dữ liệu', 'App bar "Sản phẩm" + "48 sản phẩm" + nút ⋮ (bấm không làm gì). Ô tìm + nút lọc 44. 7 chip: "Tất cả (48)", "Sẵn sàng bán (31)", "Thiếu dữ liệu (17)", "Ngừng KD (3)" có số; "Còn hàng", "Hết hàng", "Đã xóa" không số. Không có hàng đầu danh sách (số kết quả / sắp xếp). Thẻ: ảnh 60 (hoặc ô xám có icon ảnh), tên, tên thương mại, ô trường bổ sung chữ 11, rồi giá | ĐVT chữ thường | tồn là **số trơn không đơn vị** ("24"), hết hàng → "Hết" chữ vàng. "Cát vệ sinh cho mèo" đang ngừng kinh doanh nhưng thẻ không có dấu gì; thẻ cũng không cho biết sản phẩm sẵn sàng bán hay thiếu dữ liệu. Giá thiếu là "_" (ĐVT thiếu là "–"). Web: 2 cột, danh sách 360 + cột phải "Chọn một sản phẩm để xem chi tiết."; nút + bị đẩy vào trong 280 px (gutter tính theo cửa sổ 1280).'],
      ['loading', 'Đang tải', '8 thẻ khung (ảnh 60 + 3 vạch + hàng 3 ô) nền surfaceAlt trên thẻ trắng (nhạt, khó thấy). App bar "0 sản phẩm"; chip chưa có số.'],
      ['search', 'Đang tìm', 'Từ khoá "amox": nút × trong ô; chip và số trên app bar không đổi (vẫn tổng toàn bộ). Không có dòng "n kết quả".'],
      ['chip-ready', 'Chip "Sẵn sàng bán"', 'Chip xanh; danh sách lọc ở máy chủ.'],
      ['chip-inactive', 'Chip "Ngừng KD"', 'Một sản phẩm ngừng kinh doanh; thẻ vẫn trông như đang bán.'],
      ['chip-in-stock', 'Chip "Còn hàng"', 'Lọc **cục bộ** trên các dòng đã tải (20 dòng đầu), không gọi máy chủ: sản phẩm còn hàng ở trang sau không hiện. Cột tồn là số trơn ("24"), không có đơn vị.'],
      ['chip-out-of-stock', 'Chip "Hết hàng"', 'Như "Còn hàng": lọc cục bộ, gồm cả sản phẩm ngừng kinh doanh; cột tồn ghi "Hết" chữ vàng.'],
      ['chip-deleted', 'Chip "Đã xóa"', '"Đã xóa (2)" (số chỉ có khi đang ở chip này); mỗi thẻ có nhãn nhỏ "Đã xóa" xám.'],
      ['cf-filtered', 'Đang lọc thông tin bổ sung', 'Nút lọc nền xanh nhạt, viền + icon xanh, số 2. Không thấy đang lọc theo gì; không có lối xoá lọc ngoài mở lại sheet.'],
      ['end', 'Cuối danh sách', '"Đã ở cuối danh sách" bodySmall xám, đệm dọc 16. Đã tải hết nên "Còn hàng (29)" / "Hết hàng (19)" có số.'],
      ['more', 'Đang tải thêm', 'Cuộn tới cuối: thêm thẻ khung dưới thẻ cuối (Flutter thêm 20 = pageSize).'],
      ['empty', 'Chưa có sản phẩm', 'Hộp rỗng canh giữa: icon hộp, "Chưa có sản phẩm nào được tạo", nút chính "+ Tạo sản phẩm" cách 32. Nút + nổi vẫn hiện (hai lối cùng việc).'],
      ['empty-filter', 'Chip không ra kết quả', '"Không có sản phẩm "Thiếu dữ liệu"" (ngoặc kép lồng ngoặc kép), không mô tả, không nút.'],
      ['empty-deleted', 'Chưa có sản phẩm đã xoá', '"Không có sản phẩm đã xóa." (có dấu chấm; các câu rỗng khác không có).'],
      ['no-result', 'Không kết quả', 'Tìm "xyz": "Không tìm thấy sản phẩm" + "Hãy thử tìm kiếm với từ khóa khác hoặc tạo sản phẩm mới." — không có nút "Xóa từ khóa" hay "Tạo sản phẩm".'],
      ['error', 'Lỗi tải', 'Chỉ một dòng chữ đỏ giữa vùng danh sách: "Lỗi: Đã xảy ra lỗi. Vui lòng thử lại." (chữ "lỗi" lặp), không icon, không nút thử lại; kéo xuống để tải lại cũng không được.'],
      ['error-permission', 'Không có quyền xem', 'Không có màn "không có quyền" riêng: vẫn ô tìm, chip, nút + và dòng đỏ "Lỗi: Bạn không có quyền thực hiện thao tác này."; app bar "0 sản phẩm".'],
    ],
  },
  {
    id: 'filter', group: 'list', code: 'SP-02', title: 'Lọc thông tin bổ sung', route: '/products/items', states: [
      ['default', 'Lọc sản phẩm', 'Sheet có tiêu đề "Lọc sản phẩm" + gạch. Mỗi trường: tên H4 + chip. **Mọi chip đều xanh như đang chọn** (chip đặt cứng tone primary, nên trạng thái chọn không đổi màu) → không biết đang chọn gì. "Bỏ lọc" | "Áp dụng". iPhone: sheet mở trong vùng tab nên thanh dưới vẫn hiện. Web: hộp thoại 480 có tiêu đề + nút Đóng.'],
      ['empty', 'Chưa có trường lọc', '"Chưa có thuộc tính mở rộng nào." (chữ "thuộc tính mở rộng" khác "thông tin bổ sung" ở nơi khác) + hai nút vẫn hiện.'],
    ],
  },
  {
    id: 'create', group: 'list', code: 'SP-03', title: 'Tạo nhanh sản phẩm', route: '/products/items/new', states: [
      ['new', 'Mới mở', 'Toàn màn ngoài khung (web không thanh bên, thân cột 720). Nút ← là arrowBack có thân (màn khác trong khung dùng ‹). 7 thẻ bước, bước 1 mở. Nhãn ô VFieldLabel 14 đậm. SKU | Barcode chia đôi; nút quét mã trong ô Barcode **bấm không làm gì**. Hai ô gạt "Quản lý theo lô" | "Bắt buộc hạn dùng" chia đôi, chữ xuống 2 dòng trên iPhone; ô hạn dùng mờ. "Bỏ qua" (chữ xám) | "Tiếp". Chân dính "Huỷ" | "Lưu sản phẩm" (mờ tới khi nhập gì đó).'],
      ['filled', 'Bước 1 · đã nhập', 'Đủ ô + bật lô → ô "Bắt buộc hạn dùng" sáng. "Lưu sản phẩm" bật.'],
      ['name-error', 'Bước 1 · thiếu tên', 'Chỉ nhập tên thương mại rồi Lưu: lỗi dưới "Tên nội bộ" + toast đỏ "Vui lòng nhập tên nội bộ sản phẩm." **đè lên chân "Huỷ | Lưu sản phẩm"**. Bấm "Tiếp" khi chưa có tên thì không báo gì.'],
      ['duplicate', 'Trùng SKU', 'Lỗi đỏ dưới SKU; nút chữ "↗ Mở sản phẩm "…"" (TextButton, chữ 13 xanh) dưới hàng SKU / Barcode.'],
      ['images-empty', 'Bước 2 · chưa có ảnh', 'Lưới 3 cột: chỉ ô "+ Thêm" (viền nhạt). Dưới là **hai dòng xám liền nhau**: "Chạm vào ảnh để đặt làm ảnh mặc định. Tối đa 8 ảnh." và "Chưa có ảnh" (chữ 12).'],
      ['images', 'Bước 2 · có ảnh', 'Ảnh bìa viền xanh 2 + nhãn "Mặc định"; một ảnh đang tải (phủ trắng + vòng); một ảnh lỗi (viền đỏ, "Lỗi tải"). Nút × tròn 24 trên mọi ảnh (vùng chạm 24). "Xem gallery" chữ xanh đậm. Câu "Một số ảnh tải lên thất bại — …".'],
      ['images-max', 'Bước 2 · đủ 8 ảnh', 'Không còn ô Thêm; "Đã đạt tối đa 8 ảnh." chữ vàng đậm + câu xám.'],
      ['unit', 'Bước 3 · Đơn vị cơ sở', 'Mô tả nhỏ; nhãn kiểu khác (13 đậm xám, lùi 4) và ô nhập kiểu Material (nền xám canvas, viền nhạt, cao ~40) khác ô VInput 44 ở bước 1. Khe dưới ô là 8 + 16.'],
      ['unit-dropdown', 'Bước 3 · gợi ý đơn vị', 'Gõ "h": danh sách nổi (bóng 8, bo 8) dưới ô: icon nhãn giá + tên đơn vị (hộp, hũ, chai). Không có dòng "Tạo đơn vị mới"; đơn vị lưu chữ thường.'],
      ['cost-no-unit', 'Bước 4 · chưa có ĐVT', 'Hộp vàng tự vẽ "Cần thiết lập đơn vị cơ sở ở bước trước rồi mới nhập được giá cơ sở." (chạm → về bước 3, không có dấu hiệu bấm được). "Bỏ qua" | "Tiếp" vẫn hiện.'],
      ['cost', 'Bước 4 · Giá cơ sở', 'Nhãn "Giá cơ sở (hộp)" kiểu nhỏ + ô tiền VInput 44 hậu tố "đ" (bước này lại dùng VInput, bước 3 thì không).'],
      ['price-store', 'Bước 5 · Giá cửa hàng', '3 nút chọn cách tính (36 cao, chữ 13). "Quy tắc: Khung giá mặc định"; 2 thẻ gợi ý: tiêu đề **"(+28.000000000000004%)" / "(+14.000000000000002%)"** (tỉ lệ 0,28 / 0,14 × 100 in thẳng số thực; tỉ lệ tròn như 0,3 thì ra "(+30.0%)"), giá H3 xanh.'],
      ['price-store-loading', 'Bước 5 · đang tải quy tắc', 'Vòng xoay Material giữa.'],
      ['price-store-missing', 'Bước 5 · chưa có khung giá', 'Hộp vàng "Chưa cấu hình khung giá cửa hàng. Vui lòng thiết lập trong Cài đặt sản phẩm." — không có lối sang Cài đặt.'],
      ['price-custom-empty', 'Bước 5 · Tự động riêng · trống', '"Lãi cơ sở" | "Giá sàn" (ô %), dòng mờ "Nhập tỷ lệ % để xem gợi ý giá."'],
      ['price-custom', 'Bước 5 · Tự động riêng', '"(+35.0%)" / "(+12.5%)" — số nguyên vẫn có ".0".'],
      ['price-manual', 'Bước 5 · Thủ công', '"Giá niêm yết" | "Giá bán sàn" (ô tiền) + dòng cảnh báo vàng có icon (bo 12, đệm 8 — hộp vàng các bước khác bo 8 đệm 12).'],
      ['price-manual-error', 'Bước 5 · Thủ công · lỗi', 'Lỗi dưới giá sàn "Giá sàn phải ≤ giá niêm yết" + toast "Giá sàn không được lớn hơn giá niêm yết." (hai câu khác nhau cho một lỗi).'],
      ['price-no-unit', 'Bước 5 · chưa có ĐVT', 'Hộp vàng "… mới nhập được khung giá bán."'],
      ['custom-fields', 'Bước 6 · Thông tin bổ sung', 'Tiêu đề "6. Thông tin dược", phụ "2/4 trường đã điền". Chọn một (VSelect "— Chọn —"), số, ô gạt "Kê đơn" (dấu * nếu bắt buộc là chữ thường, không đỏ), ngày ("Chọn ngày"). Mỗi ô cách 24.'],
      ['custom-fields-error', 'Bước 6 · thiếu trường bắt buộc', '"Trường này là bắt buộc" dưới ô + toast "Vui lòng điền đầy đủ các trường bắt buộc."'],
      ['note', 'Bước 7 · Ghi chú', 'Bước cuối không có "Bỏ qua" / "Tiếp"; ô ghi chú 4 dòng + bộ đếm "31/500" góc dưới phải + câu nhỏ dưới.'],
      ['no-groups', 'Không có nhóm bổ sung', 'Chỉ 6 bước, "6. Ghi chú".'],
      ['collapsed', 'Mọi bước đóng', 'Chạm tiêu đề bước đang mở → đóng hết. Chữ phụ không đổi theo dữ liệu (không tóm tắt đã nhập gì, không dấu ✓).'],
      ['submitting', 'Đang lưu', '"Lưu sản phẩm" có vòng xoay, "Huỷ" mờ.'],
      ['save-error', 'Lỗi lưu', 'Toast đỏ "Lỗi hệ thống khi tạo sản phẩm." đè lên chân.'],
    ],
  },
  {
    id: 'image-add', group: 'list', code: 'SP-03', title: 'Thêm ảnh sản phẩm', route: '/products/items/new', states: [
      ['default', 'Chọn nguồn ảnh', 'Sheet có tiêu đề + gạch; 3 ô (nền canvas, viền nhạt, icon trong hộp màu nhạt): "Chụp ảnh" (xanh lá), "Chọn từ thư viện", "Chọn tệp"; "Hủy" (chữ "ủ" — chân màn tạo ghi "Huỷ"). Ô không có mũi tên ›. iPhone: sheet phủ cả màn (route ngoài khung). Web: hộp thoại có tiêu đề + Đóng — và vẫn có "Hủy".'],
    ],
  },
  {
    id: 'pcc', group: 'pcc', code: 'SP-04', title: 'Product Control Center', route: '/products/items/sp1', states: [
      ['ready', 'Sẵn sàng bán', 'iPhone: PCC thay danh sách trong khung (thanh dưới vẫn hiện), nút ← arrowBack. Web: cột phải 679 (thân 640), danh sách đánh dấu dòng chọn, không có nút ←. App bar: tên (H3) + nhãn nhỏ "Sẵn sàng bán". Thẻ tóm tắt: ảnh 64, tên chữ thường (không đậm), "Giá niêm yết: 125.000 đ", "Tồn (hộp): 24". 10 thẻ mục cùng một khuôn (hộp icon xanh nhạt 40 + tiêu đề + phụ + nút chữ "Sửa"); thẻ nhóm thông tin bổ sung dùng emoji 💊. Phụ "Khung giá" dài 2 dòng: "Niêm yết · Sàn · Đơn vị · tên khung giá". Cuối là khối đỏ "Nâng cao" (đóng).'],
      ['ready-no-image', 'Sẵn sàng bán · chưa có ảnh', 'Nhãn "Sẵn sàng bán" nhưng ngay dưới là banner vàng "Cần bổ sung (1)" (blocker ảnh không chặn bán nhưng vẫn đếm). Ảnh trống → ô xám icon ảnh. Khung giá riêng → "· Giá riêng".'],
      ['incomplete', 'Thiếu dữ liệu', 'Nhãn đỏ "Thiếu dữ liệu"; banner "Cần bổ sung (4)"; "Thiếu Giá cơ sở định giá", "Thiếu khung giá bán"; thẻ nhóm 💊 nền đỏ nhạt + "Thiếu thông tin bắt buộc" (chữ xám, không đỏ). "Chưa có mã vạch". Thẻ tóm tắt "Giá niêm yết: --", "Tồn (lọ): 0 (Hết hàng)".'],
      ['no-unit', 'Chưa có đơn vị cơ sở', '"Cần bổ sung (4)"; "Thiếu đơn vị cơ sở"; Tồn kho "0" (không đơn vị); tóm tắt "Tồn (cơ sở): 0 (Hết hàng)". Lịch sử "Chưa có lịch sử".'],
      ['inactive', 'Ngừng kinh doanh', '**Không chỗ nào trên màn cho biết sản phẩm đang ngừng kinh doanh**: nhãn vẫn "Sẵn sàng bán", chỉ khi mở "Nâng cao" mới thấy "Kinh doanh lại".'],
      ['deleted', 'Đã xoá', 'Nhãn xám "Đã xóa". Nút "Sửa" của 6 thẻ đầu mờ (chạm thẻ không làm gì), nhưng thẻ nhóm bổ sung, Ghi chú, Lịch sử vẫn bấm được (sửa được dữ liệu của sản phẩm đã xoá). "Nâng cao" → "Khôi phục sản phẩm".'],
      ['loading', 'Đang tải', 'Tiêu đề lấy từ dòng danh sách; nhãn **"Thiếu dữ liệu" đỏ** trong lúc tải (kể cả sản phẩm sẵn sàng). Khe 48 + vòng Material.'],
      ['loading-deeplink', 'Đang tải (mở bằng link)', 'Không có dữ liệu từ danh sách: tiêu đề trống, chỉ có nhãn "Thiếu dữ liệu".'],
      ['error', 'Lỗi tải', 'Một dòng chữ xám giữa màn "Sản phẩm không tồn tại hoặc đã bị xoá.", không icon, không nút thử lại; nhãn "Thiếu dữ liệu" vẫn hiện.'],
      ['danger-open', 'Nâng cao · mở', 'Cuộn tới cuối: "Ngừng kinh doanh" (icon cấm) và "Xoá sản phẩm" (thùng rác), chữ đỏ, gạch ngăn đỏ nhạt lùi 16.'],
      ['danger-open-inactive', 'Nâng cao · ngừng KD', '"Kinh doanh lại" cũng chữ đỏ (việc tích cực mà tô như nguy hiểm). Chữ phụ của đầu khối vẫn ghi "Ngừng kinh doanh · Xoá sản phẩm".'],
      ['danger-open-deleted', 'Nâng cao · đã xoá', 'Chỉ "Khôi phục" (đỏ).'],
      ['toast-status', 'Toast đổi trạng thái', '"Đã cập nhật trạng thái kinh doanh của sản phẩm." — câu chung cho cả ngừng và kinh doanh lại. iPhone: trên thanh dưới; web: trong cột phải.'],
      ['toast-created', 'Vừa tạo xong', 'Từ màn tạo quay về: toast "Sản phẩm đã được khởi tạo!" (dấu chấm than; nơi khác dấu chấm).'],
    ],
  },
  {
    id: 'pcc-sheet', group: 'pcc', code: 'SP-04', title: 'Vòng đời / xoá / khôi phục', route: '/products/items/sp1', states: [
      ['deactivate', 'Ngừng kinh doanh?', 'Sheet có tiêu đề "Ngừng kinh doanh sản phẩm này?" + gạch; câu xám; "Huỷ" | "Ngừng kinh doanh" (đỏ). Đệm 20 (sheet khác đệm 16). iPhone: sheet trong vùng tab; web: hộp thoại 480 phủ cả thanh bên, có nút Đóng.'],
      ['deactivate-warning', 'Ngừng KD · cần xác nhận', 'Máy chủ trả cảnh báo → mở lại sheet với hộp vàng "Cần xác nhận" + "• Sản phẩm vẫn còn tồn kho hiện hành."'],
      ['reactivate', 'Kinh doanh lại?', '"Kinh doanh lại sản phẩm này?"; nút "Kinh doanh lại" **đỏ** (isDestructive: true).'],
      ['delete-checking', 'Xoá · đang kiểm tra', 'Sheet "Xoá sản phẩm này?" chỉ có vòng Material 36 + "Đang kiểm tra điều kiện..." dồn trái.'],
      ['delete', 'Xoá sản phẩm?', 'Câu xám + "Huỷ" | "Xoá sản phẩm" (đỏ). Tiêu đề "Xoá" (oa) — toast sau khi xoá ghi "xóa" (óa).'],
      ['delete-warning', 'Xoá · lưu ý', 'Hộp vàng "Lưu ý" + "• Sản phẩm vẫn còn tồn kho hiện hành." — vẫn xoá được.'],
      ['delete-blocked', 'Không xoá được', '"Sản phẩm "…" không thể xóa vì:" + lý do đỏ có icon + "Đóng" đầy ngang. Hiện máy chủ chỉ trả lý do cảnh báo nên gần như không gặp.'],
      ['deleting', 'Đang xoá', '"Đang xóa..." + vòng.'],
      ['restore', 'Khôi phục?', '"Khôi phục sản phẩm này?"; câu có chữ tiếng Anh "readiness"; hộp vàng "Readiness hiện tại" (không icon, không gạch đầu dòng — khác hộp "Cần xác nhận" / "Lưu ý"); "Khôi phục" xanh.'],
      ['restore-error', 'Khôi phục · lỗi', 'Câu lỗi đỏ đậm trong sheet **và** toast đỏ "Không thể khôi phục" cùng lúc.'],
      ['toast-deleted', 'Đã xoá', 'iPhone: quay về danh sách + toast "Sản phẩm đã được xóa thành công."; web: cột phải về "Chọn một sản phẩm…" + toast trong cột phải.'],
    ],
  },
  {
    id: 'checklist', group: 'pcc', code: 'SP-21', title: 'Checklist readiness', route: '/products/items/sp3/checklist', states: [
      ['blockers', 'Có mục cần bổ sung', 'Toàn màn ngoài khung, tiêu đề "Sẵn sàng vận hành" (PCC gọi "Thiếu dữ liệu" / "Cần bổ sung": ba tên cho một việc), nút ‹ (PCC dùng ←). Chỉ liệt kê mục thiếu, không có mục đã xong; mỗi ô bo 8 (thẻ PCC bo 12), icon vàng, nút chữ bên phải. Web: cột 720.'],
      ['no-unit-toast', 'Chưa có ĐVT · bấm "Thiết lập giá"', 'Toast vàng "Vui lòng thiết lập đơn vị cơ sở trước." thay vì dẫn sang màn đơn vị.'],
      ['empty', 'Không còn mục', '"Sản phẩm đã sẵn sàng vận hành." giữa màn (từ PCC không vào được khi không có blocker).'],
    ],
  },
  {
    id: 'history', group: 'pcc', code: 'SP-22', title: 'Lịch sử thay đổi', route: '/products/items/sp1/change-history', states: [
      ['loaded', 'Có dữ liệu', 'Ngoài khung; tiêu đề + tên sản phẩm; nút ← arrowBack. Thẻ khung giá: 3 hàng nhãn 92 | giá trị canh phải "A → B" + "Nguyên nhân: …". Thẻ khác: giá trị "A — B" (gạch dài, khung giá dùng mũi tên); đổi trạng thái hiện mã thô **"inactive — active"**; trường ẩn "*** — ***". Người làm **"bởi 3f9a2c1b"** (8 ký tự mã). Ngày "2026-11-20 15:42". Không có ngày nhóm, không icon theo loại.'],
      ['more', 'Đang tải thêm', 'Vòng Material cuối danh sách.'],
      ['loading', 'Đang tải', 'Vòng Material giữa màn.'],
      ['empty', 'Chưa có lịch sử', 'Icon đồng hồ 48 xám nhạt + "Chưa có lịch sử thay đổi nào" (không VEmptyState).'],
      ['error', 'Lỗi', 'Icon lỗi 48 đỏ + câu + "Thử lại" viền (danh sách sản phẩm lỗi thì không có nút).'],
    ],
  },
  {
    id: 'profile', group: 'sub', code: 'SP-05', title: 'Hồ sơ sản phẩm', route: '/products/items/sp1/profile-maintenance', states: [
      ['default', 'Mới mở', 'Ngoài khung, nút ← arrowBack, **không có tên sản phẩm** trên app bar (màn con khác có). 4 ô khe 16 (màn tạo khe 12). Hai ô gạt mỗi ô một hàng (màn tạo: chung một hàng). Chân "Huỷ | Lưu thay đổi" (mờ). Web: **hai gạch trên chân** — gạch hết bề ngang của VPageScaffold.bottomBar và gạch của ProductFormBottomBar trong cột 720.'],
      ['lot-on', 'Bật quản lý theo lô', 'Ô "Bắt buộc hạn dùng" sáng; "Lưu thay đổi" bật.'],
      ['locked', 'Đã có biến động kho', 'Hai ô gạt mờ + "Đã có biến động kho, không đổi được." chữ vàng.'],
      ['sku-error', 'Trùng SKU', 'Lỗi dưới ô SKU **và** toast đỏ cùng câu.'],
      ['name-error', 'Thiếu tên', 'Lỗi dưới tên.'],
      ['saving', 'Đang lưu', '"Lưu thay đổi" có vòng; "Huỷ" vẫn bấm được.'],
    ],
  },
  {
    id: 'images', group: 'sub', code: 'SP-06', title: 'Ảnh sản phẩm', route: '/products/items/sp1/images-maintenance', states: [
      ['default', 'Có ảnh', 'Như bước ảnh của màn tạo nhưng chữ là "Xem trước ảnh" (màn tạo "Xem gallery"); không có tên sản phẩm trên app bar. Web: ô ảnh ~212 px.'],
      ['empty', 'Chưa có ảnh', 'Chỉ ô "+ Thêm" + câu gợi ý (không có "Chưa có ảnh" như màn tạo).'],
      ['uploading', 'Đang tải lên', 'Ô "Thêm" thành vòng Material 36; ảnh đang tải không có lớp phủ "Đang tải" như màn tạo.'],
      ['max', 'Đủ 8 ảnh', '"Đã đạt tối đa 8 ảnh." chữ vàng đậm.'],
      ['delete-dialog', 'Xoá ảnh?', 'Dialog Material (cả iPhone — xác nhận khác của Theme 2 là sheet): vòng đỏ + thùng rác 32, "Xóa ảnh sản phẩm?" giữa, câu giữa, "Hủy" | "Xóa ảnh" đỏ.'],
      ['gallery', 'Gallery', 'Toàn màn nền gần đen, AppBar Material "Gallery ảnh" + "1/3"; ảnh giữa; đáy: pill "Mặc định", "Vuốt để xem ảnh khác" (web không vuốt được, không có nút trước / sau), nút "Đóng" viền trắng.'],
    ],
  },
  {
    id: 'note', group: 'sub', code: 'SP-07', title: 'Ghi chú', route: '/products/items/sp1/note', states: [
      ['default', 'Có ghi chú', 'Scaffold thường + VAppBar: nút ‹ (màn con khác ←); **web không giới hạn cột** — ô ghi chú và chân kéo hết 1280. Ô 6 dòng + bộ đếm. "Lưu thay đổi" mờ tới khi sửa.'],
      ['empty', 'Trống', 'Gợi ý "Ví dụ: Hàng nhập từ NCC A…".'],
      ['dirty', 'Đã sửa', '"Lưu thay đổi" bật.'],
    ],
  },
  {
    id: 'custom-fields', group: 'sub', code: 'SP-08', title: 'Nhập nhóm thông tin bổ sung', route: '/products/items/sp1/custom-fields/edit', states: [
      ['default', 'Có giá trị', 'Tiêu đề = tên nhóm, phụ = tên sản phẩm. Một khung trắng bo 12 chứa các ô, **không đệm đáy** (khoảng trống dưới là đệm 24 của ô cuối). Chọn một, số, ô gạt "Kê đơn", ngày.'],
      ['dirty', 'Đã sửa', '"Lưu thay đổi" bật. Bấm ← khi đã sửa thì **không hỏi**, mất thay đổi (CHECKLIST ghi "hỏi khi rời").'],
      ['error', 'Thiếu bắt buộc', '"Trường này là bắt buộc" + toast.'],
      ['loading', 'Đang tải', 'Tiêu đề tạm "Trường thông tin", nút ‹ (khi tải xong thành ←).'],
      ['inactive', 'Mọi trường đã tắt', 'Ô mờ; không có chân lưu.'],
    ],
  },
  {
    id: 'units', group: 'sub', code: 'SP-09', title: 'Đơn vị đo lường', route: '/products/items/sp1/measurement-units', states: [
      ['default', 'Có đơn vị', 'Hai thẻ có nhãn CHỮ HOA xám ("ĐƠN VỊ CƠ SỞ", "ĐƠN VỊ QUY ĐỔI (3)"). ĐVT cơ sở "hộp" chữ thường đậm. Mỗi đơn vị quy đổi: tên đậm, **tên lặp lại** ở dòng dưới, "20 x hộp"; chữ "giữ để mở" — chỉ nhấn giữ mới ra nút (web: không có cách bấm). Đơn vị tắt: nền xám + thẻ "Đã tắt". Nút "+ Thêm đơn vị quy đổi" viền xanh tự vẽ.'],
      ['no-base', 'Chưa có ĐVT cơ sở', '"Chưa thiết lập (không bắt buộc)." (PCC thì báo đỏ "Thiếu đơn vị cơ sở" và chặn sẵn sàng bán) + nút viền "+ Thiết lập đơn vị cơ sở".'],
      ['edit-base', 'Nhập ĐVT cơ sở', 'Ô + "Sẽ lưu ở dạng chữ thường: hộp" + "Huỷ" (chữ xám) | "Lưu". "Lưu thay đổi" ở chân cũng bật — hai nút lưu cho một việc.'],
      ['no-conv', 'Chưa có quy đổi', '"Chưa có đơn vị quy đổi." + nút thêm.'],
      ['adding', 'Thêm quy đổi', '"Tên đơn vị" | "Tỉ lệ (x hộp)" (nhãn bodySmall xám, khác VFieldLabel) + câu chữ thường + "Huỷ" | "Thêm".'],
      ['expanded', 'Mở thao tác', '"Tắt đơn vị" (viền) | "Xoá" (đỏ) | "Đóng" (chữ xám) — 3 nút nhỏ trong thẻ.'],
      ['expanded-off', 'Mở thao tác · đơn vị tắt', '"Bật đơn vị" | "Xoá" | "Đóng".'],
      ['toast-added', 'Đã thêm', 'Toast "Đã cập nhật đơn vị quy đổi"; "Lưu thay đổi" bật nhưng chỉ đóng màn (đã lưu rồi).'],
      ['toast-error', 'Lỗi nhập', 'Toast đỏ "Không thể dùng đơn vị cơ sở làm đơn vị quy đổi" — lỗi nhập hiện bằng toast, không dưới ô.'],
    ],
  },
  {
    id: 'units-sheet', group: 'sub', code: 'SP-09', title: 'Đơn vị · xác nhận', route: '/products/items/sp1/measurement-units', states: [
      ['deactivate', 'Tắt đơn vị?', '"Tắt đơn vị này?" — "Tắt" đỏ.'],
      ['reactivate', 'Bật lại?', '"Bật lại đơn vị?" — nút "Bật" **đỏ**.'],
      ['delete', 'Xoá đơn vị?', '"Xoá đơn vị quy đổi?" — câu dài 3 ý; "Xoá" đỏ; câu viết "xóa", tiêu đề "Xoá".'],
      ['delete-blocked', 'Không xoá được', '"Không thể xóa đơn vị" — "Đóng" | "Tắt đơn vị" **xanh** (cùng việc tắt mà sheet "Tắt đơn vị này?" tô đỏ).'],
    ],
  },
  {
    id: 'base-price', group: 'sub', code: 'SP-11', title: 'Giá cơ sở', route: '/products/items/sp1/manual-base-price', states: [
      ['default', 'Có giá', 'Thẻ: ô "Giá cơ sở hiện tại | 80.000 đ" (viền xám nhạt), nhãn nhỏ "Giá cơ sở mới (đ / 1 hộp)", ô tiền gợi ý "Ví dụ: 45,000" (dấu phẩy; ô hiện "80.000" dấu chấm), hậu tố "đ / hộp", câu nhỏ. Chân nằm trong thân (một gạch; màn con khác hai gạch).'],
      ['dirty', 'Đã sửa', '"Lưu thay đổi" bật.'],
      ['empty', 'Chưa có giá', '"Giá cơ sở hiện tại | —".'],
      ['no-unit', 'Chưa có ĐVT', 'Khung viền đứt "Cần thiết lập **đơn vị cơ sở** …" — không có nút sang màn đơn vị; chân "Lưu thay đổi" luôn mờ.'],
      ['saving', 'Đang lưu', 'Vòng trên nút.'],
    ],
  },
  {
    id: 'price-bands', group: 'sub', code: 'SP-12', title: 'Khung giá bán', route: '/products/items/sp1/price-bands', states: [
      ['default', 'Có đơn vị', '"ĐƠN VỊ & KHUNG GIÁ BÁN" (caption CHỮ HOA). Mỗi đơn vị một ô bo 8: tên + chữ "Sửa" / "Thiết lập" màu xanh (không phải nút, không vùng chạm 44); "Đơn vị cơ sở"; 3 hàng giá. Đơn vị tắt: "Đơn vị ngừng hoạt động" + nhãn "Không hoạt động" (đơn vị cùng trạng thái mà màn đơn vị gọi "Đã tắt").'],
      ['loading', 'Đang tải', 'Vòng Material.'],
      ['no-unit', 'Chưa có ĐVT', 'Khung viền đứt + chân "Huỷ | Lưu thay đổi" (màn chỉ xem mà có nút lưu, luôn mờ).'],
      ['error', 'Lỗi', 'Một dòng chữ đen giữa màn.'],
    ],
  },
  {
    id: 'edit-band', group: 'sub', code: 'SP-13', title: 'Sửa khung giá một đơn vị', route: '/products/items/sp1/price-bands/edit', states: [
      ['store', 'Theo khung giá cửa hàng', 'Cùng tiêu đề "Khung giá bán" với SP-12, không ghi đang sửa đơn vị nào (chỉ "1 hộp" nhỏ trong ô giá cơ sở). VChoiceList "Cách tính" 3 lựa chọn có mô tả. Ô chi tiết: "Giá niêm yết 28%" / "Giá sàn 14%", gạch, rồi **lặp lại nhãn** "Giá niêm yết 102.400 đ" / "Giá sàn 91.200 đ". Chữ trong ô dùng Text() không màu.'],
      ['custom', 'Tự động riêng', 'Ô % rộng cố định 120 + "= 108.000 đ"; "(dự kiến)"; hộp ghi chú bo 4 (hộp khác bo 8 / 12).'],
      ['manual', 'Nhập thủ công', 'Nhãn trái (2 phần) | ô tiền canh phải (3 phần); hộp ghi chú.'],
      ['overwrite', 'Ghi đè?', 'Sheet **không tiêu đề**: "Ghi đè khung giá hiện tại?" tự vẽ trong nội dung, ô xám giá hiện tại, "Hủy" | "Ghi đè" (xanh). Web: hộp thoại không tiêu đề + nút Đóng góc.'],
    ],
  },
  {
    id: 'settings', group: 'settings', code: 'SP-14', title: 'Cài đặt sản phẩm', route: '/more/product-settings', states: [
      ['default', 'Mặc định', 'Mở từ menu Thêm; route gốc ngoài khung (web mất thanh bên). Tiêu đề **"Sản phẩm"** — trùng tiêu đề danh sách sản phẩm. 2 thẻ: hộp icon 44 nền trắng (thẻ PCC: nền xanh nhạt 40), tiêu đề H4, mô tả, ›. Thứ tự: giá trước, nhóm trường sau.'],
    ],
  },
  {
    id: 'cf-groups', group: 'settings', code: 'SP-15', title: 'Nhóm & trường thông tin', route: '/more/product-settings/custom-fields', states: [
      ['loaded', 'Có nhóm', 'Nút + xanh trên app bar (danh sách sản phẩm dùng nút + nổi). Banner vàng tự vẽ (một câu hướng dẫn mà tô vàng như cảnh báo) có icon tay kéo trong câu. Thẻ: tay kéo, tên, VBadge "Đang dùng" / "Tạm tắt" (cỡ thường — PCC dùng cỡ nhỏ), "4 trường • 1 bắt buộc" (chấm "•"; PCC dùng "·").'],
      ['empty', 'Chưa có nhóm', 'Icon hộp thư 64 + "Chưa có nhóm thông tin nào" + "Tạo mẫu mặc định" (không VEmptyState, không nói mẫu gồm gì).'],
      ['loading', 'Đang tải', 'Vòng Material.'],
    ],
  },
  {
    id: 'cf-group', group: 'settings', code: 'SP-16', title: 'Chi tiết nhóm', route: '/more/product-settings/custom-fields/g1', states: [
      ['loaded', 'Có trường', 'Nút ⋮ trên app bar mở **màn sửa nhóm** (không phải menu). Nhãn tự vẽ "Đang dùng" (khác VBadge ở SP-15). "TRƯỜNG THÔNG TIN" | "+ Thêm trường" chữ 13 không vùng chạm 44. Dòng phụ trường lẫn Anh – Việt: "**Single select** • Bắt buộc • Tìm kiếm • Lọc • Hiển thị", "**Text** • …" (ô chọn kiểu dữ liệu ở SP-17 ghi "Tùy chọn", "Văn bản"). Trường tắt xuống cuối + nhãn "Tạm tắt".'],
      ['empty', 'Chưa có trường', 'Khung trắng bo 12: hộp xanh + "Chưa có trường nào" + "+ Thêm trường thông tin" — cùng lúc với "+ Thêm trường" ở hàng trên (hai lối).'],
      ['inactive', 'Nhóm tạm tắt', 'Nhãn "Tạm tắt" xám.'],
    ],
  },
  {
    id: 'upsert-group', group: 'settings', code: 'SP-16', title: 'Tạo / sửa nhóm', route: '/more/product-settings/custom-fields/upsert-group', states: [
      ['create', 'Tạo nhóm', 'Nút ← arrowBack (SP-14/15 dùng ‹). "Icon" + ô 56 + câu; lưới **8 cột** 30 emoji (gồm 🐄 🐖 🏭 …) — web cột 720 nên ô ~80 px. Nhãn "Tên nhóm *": dấu * là chữ trong nhãn, **cùng màu đen** (màn khác * đỏ). "Mô tả (tuỳ chọn)" (chữ "tuỳ"; nơi khác "tùy"). Chân hai gạch (web).'],
      ['edit', 'Sửa nhóm', 'Thêm hàng "Trạng thái hoạt động" + Switch Material (tắt: nền borderStrong nhạt hơn VSwitch).'],
      ['deactivate', 'Tạm tắt nhóm?', 'Sheet **không tiêu đề sheet**, tiêu đề tự vẽ trong nội dung; web: hộp thoại không tiêu đề + nút Đóng góc. "Huỷ" | "Tạm tắt" đỏ.'],
      ['leave', 'Thoát mà không lưu?', 'Sheet **có** tiêu đề "Thoát mà không lưu?" + gạch — "Ở lại" | "Thoát" đỏ (Theme 3 dùng "Rời khỏi màn hình?" / "Ở lại chỉnh sửa" | "Rời khỏi").'],
    ],
  },
  {
    id: 'upsert-field', group: 'settings', code: 'SP-17', title: 'Tạo / sửa trường', route: '/more/product-settings/custom-fields/g1/upsert-field', states: [
      ['create', 'Tạo trường', 'Tên, Mô tả, "Kiểu dữ liệu" = "Văn bản", "Nhóm" (ô tắt, mờ — chỉ để xem). "THUỘC TÍNH" (chữ hoa) + khung 3 hàng Switch Material: Bắt buộc, Cho phép tìm kiếm, Hiển thị trên danh sách sản phẩm.'],
      ['select', 'Kiểu "Tùy chọn"', 'Phần "Tùy chọn" | "+ Thêm" (TextButton.icon màu mặc định); mỗi dòng: tay kéo 16 + ô + thùng rác đỏ. Bật "Bắt buộc" → "Tham gia tính **readiness** của sản phẩm" (tiếng Anh). Thêm hàng "Cho phép lọc".'],
      ['edit', 'Cấu hình trường', 'Tiêu đề "Cấu hình trường" (tạo: "Tạo trường thông tin"). Câu vàng "Thay đổi kiểu dữ liệu có thể ảnh hưởng …"; "Hiển thị trên danh sách" bật → "Danh sách sản phẩm chỉ hiển thị giới hạn **field**." (tiếng Anh). Phần "TRẠNG THÁI" + "Đang dùng".'],
      ['locked', 'Đã có dữ liệu', '"Không đổi được kiểu dữ liệu do đã có dữ liệu." nhưng ô chọn kiểu vẫn trông như bấm được.'],
      ['required-confirm', 'Bật bắt buộc', 'Dialog VConfirmDialog (cả iPhone): tiêu đề trái, câu có "blocker readiness" (tiếng Anh), hai nút cỡ nội dung canh phải "Hủy" | "Xác nhận".'],
      ['deactivate', 'Tạm tắt trường?', 'Sheet không tiêu đề sheet, tiêu đề tự vẽ; "Tạm tắt" đỏ.'],
    ],
  },
  {
    id: 'store-rule', group: 'settings', code: 'SP-18', title: 'Khung giá cửa hàng', route: '/more/product-settings/store-price-rule', states: [
      ['default', 'Đã cấu hình', 'Tiêu đề "Giá sàn & Giá niêm yết" (thẻ giới thiệu ghi "Khung giá cửa hàng"). 4 khung bo 12 khác kiểu nhau. Giá niêm yết: icon lên xanh "+28.0%"; **Giá sàn: icon xuống + chữ đỏ "14.0%"** dù giá sàn vẫn cao hơn giá cơ sở 14% (tô như giảm). "✎ Sửa" chữ xanh. Khung "Lưu ý" vàng có gạch đầu dòng chấm tròn.'],
      ['empty', 'Chưa cấu hình', '"Chưa cấu hình khung giá cửa hàng. Nhấn Sửa để thiết lập…" + hai hàng "—".'],
      ['error', 'Lỗi tải', 'Banner đỏ tự vẽ + TextButton "Thử lại" (màu mặc định) ở đầu, phần dưới vẫn hiện như chưa cấu hình; thêm toast đỏ.'],
      ['loading', 'Đang tải', 'Vòng Material.'],
    ],
  },
  {
    id: 'store-rule-edit', group: 'settings', code: 'SP-19', title: 'Sửa khung giá cửa hàng', route: '/more/product-settings/store-price-rule/edit', states: [
      ['default', 'Mới mở', 'Tiêu đề "Chỉnh sửa khung giá" (SP-13 ghi "Khung giá bán"). Ô % là **ô nhiều dòng** (VTextFormField, cao 2 dòng) chữ H4; cạnh đó 2 nút ▲ ▼ 36 (dưới 44). Câu "Tính theo % trên Giá cơ sở" **hiện hai lần** (helper trong ô + dòng dưới). "XEM TRƯỚC VỚI VÍ DỤ": giá cơ sở 100.000 đ, giá sàn dự kiến chữ đỏ. "Lưu thay đổi" mờ tới khi sửa.'],
      ['error', 'Sàn > niêm yết', 'Lỗi đỏ dưới ô sàn (câu có dấu chấm; lỗi khác cùng ô thì không); helper trong ô ẩn nhưng dòng dưới vẫn hiện.'],
      ['confirm', 'Áp dụng?', 'Sheet không tiêu đề sheet: "Áp dụng quy tắc lên sản phẩm đã có giá?" + câu + "Hủy" | "Áp dụng" (xanh, dù đổi giá hàng loạt).'],
    ],
  },
  {
    id: 'store-rule-history', group: 'settings', code: 'SP-20', title: 'Lịch sử khung giá cửa hàng', route: '/more/product-settings/store-price-rule/history', states: [
      ['loaded', 'Có dữ liệu', 'Tiêu đề "Lịch sử thay đổi" (trùng SP-22). Banner vàng một câu. Thẻ: ngày ISO bold | "Hiện tại"; **"Bởi: 3f9a2c1b"** (SP-22 ghi "bởi …" thường); hai hàng tỉ lệ + "(+25.0% → +28.0%)" nhỏ canh phải. Lần đầu không có dòng trước → sau.'],
      ['empty', 'Chưa có', 'Icon đồng hồ + "Chưa có lịch sử thay đổi" (SP-22: "… thay đổi nào").'],
      ['error', 'Lỗi', 'Một dòng chữ xám, không nút thử lại (SP-22 có).'],
      ['loading', 'Đang tải', 'Vòng Material.'],
    ],
  },
];

export const CASES = Object.fromEntries(SCREENS.map((s) => [s.id, s.states.map(([id]) => id)]));
