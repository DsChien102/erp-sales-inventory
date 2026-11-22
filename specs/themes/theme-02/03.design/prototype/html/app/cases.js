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
      ['loaded', 'Có dữ liệu', 'App bar "Sản phẩm" + "48 sản phẩm" + nút ⋮ (bấm không làm gì). Ô tìm + nút lọc 44. 7 chip: "Tất cả (48)", "Sẵn sàng bán (31)", "Thiếu dữ liệu (17)", "Ngừng KD (3)" có số; "Còn hàng", "Hết hàng", "Đã xóa" không số. Không có hàng đầu danh sách (số kết quả / sắp xếp). Thẻ: ảnh 60 (hoặc ô xám có icon ảnh), tên, tên thương mại, ô trường bổ sung chữ 11, rồi giá | ĐVT chữ thường | **cột tồn luôn trống**. "Cát vệ sinh cho mèo" đang ngừng kinh doanh nhưng thẻ không có dấu gì; thẻ cũng không cho biết sản phẩm sẵn sàng bán hay thiếu dữ liệu. Giá thiếu là "_" (ĐVT thiếu là "–"). Web: 2 cột, danh sách 360 + cột phải "Chọn một sản phẩm để xem chi tiết."; nút + bị đẩy vào trong 280 px (gutter tính theo cửa sổ 1280).'],
      ['loading', 'Đang tải', '8 thẻ khung (ảnh 60 + 3 vạch + hàng 3 ô) nền surfaceAlt trên thẻ trắng (nhạt, khó thấy). App bar "0 sản phẩm"; chip chưa có số.'],
      ['search', 'Đang tìm', 'Từ khoá "amox": nút × trong ô; chip và số trên app bar không đổi (vẫn tổng toàn bộ). Không có dòng "n kết quả".'],
      ['chip-ready', 'Chip "Sẵn sàng bán"', 'Chip xanh; danh sách lọc ở máy chủ.'],
      ['chip-inactive', 'Chip "Ngừng KD"', 'Một sản phẩm ngừng kinh doanh; thẻ vẫn trông như đang bán.'],
      ['chip-in-stock', 'Chip "Còn hàng"', 'Lọc **cục bộ** trên các dòng đã tải (20 dòng đầu), không gọi máy chủ: sản phẩm còn hàng ở trang sau không hiện. Cột tồn vẫn trống nên không thấy vì sao dòng này "còn hàng".'],
      ['chip-out-of-stock', 'Chip "Hết hàng"', 'Như "Còn hàng": lọc cục bộ, gồm cả sản phẩm ngừng kinh doanh.'],
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
      ['unit-dropdown', 'Bước 3 · gợi ý đơn vị', 'Gõ "h": danh sách nổi (bóng 8, bo 8) dưới ô: icon nhãn giá + tên đơn vị (Hộp, Hũ, Chai). Không có dòng "Tạo đơn vị mới".'],
      ['cost-no-unit', 'Bước 4 · chưa có ĐVT', 'Hộp vàng tự vẽ "Cần thiết lập đơn vị cơ sở ở bước trước rồi mới nhập được giá cơ sở." (chạm → về bước 3, không có dấu hiệu bấm được). "Bỏ qua" | "Tiếp" vẫn hiện.'],
      ['cost', 'Bước 4 · Giá cơ sở', 'Nhãn "Giá cơ sở (Hộp)" kiểu nhỏ + ô tiền VInput 44 hậu tố "đ" (bước này lại dùng VInput, bước 3 thì không).'],
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
];

export const CASES = Object.fromEntries(SCREENS.map((s) => [s.id, s.states.map(([id]) => id)]));
