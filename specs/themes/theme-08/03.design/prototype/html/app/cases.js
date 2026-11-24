// Danh sách ca dùng chung: main.js, viewer.js, tools/capture.mjs.
// Mỗi màn thuộc một nhóm (đợt): setup (đợt 1), order (đợt 2).
// Mỗi state: [mã, nhãn ngắn, điều cần nhìn]. Mỗi ca vẽ ở cả hai khổ (iPhone 390, Web 1280).
export const GROUPS = [
  { id: 'setup', title: 'Thiết lập HĐĐT (đợt 1)' },
  { id: 'order', title: 'Phát hành & gửi trên đơn (đợt 2)' },
];

export const SCREENS = [
  {
    id: 'overview', group: 'setup', code: 'HD-01', title: 'Hóa đơn điện tử (tổng quan)', route: '/more/einvoice', states: [
      ['not-ready', 'Tổ chức mới', 'Route ngoài khung: không thanh bên / thanh dưới. App bar "Hóa đơn điện tử" + ←. Khối vàng: "Cần hoàn tất" (13 w600 vàng, **chữ thường**, spec vẽ IN HOA), "Chưa sẵn sàng phát hành" (18 w600), "Còn 1 điều kiện cần hoàn tất…", "Xem và hoàn tất ›" canh phải. 3 thẻ: icon chìa khoá / tệp có dấu ✓ / thanh trượt trong ô xám 40. **"Cấu hình phát hành" mờ 0.4** (chưa kết nối). "Tự động hóa" vẫn bấm được dù chưa sẵn sàng. Web: cột 720 giữa nền xám.'],
      ['not-ready-template', 'Đã kết nối, chưa chọn mẫu', '"MISA meInvoice · Đã kết nối"; "Chưa chọn mẫu hóa đơn mặc định"; thẻ "Cấu hình phát hành" hết mờ. "Còn 1 điều kiện…". "Xem và hoàn tất" mở HD-04.'],
      ['check-required', 'Kết nối chờ kiểm tra', 'Phụ đề "Cần kiểm tra lại" (chữ xám như mọi phụ đề, không màu cảnh báo). Mẫu đã chọn trước đó nhưng cubit không tải danh sách mẫu khi chưa connected → phụ đề "Cấu hình phát hành" **in GUID thô** "7f3c9a2e-41b8-…" và thẻ mờ.'],
      ['reconnect-required', 'Kết nối lỗi', '"Cần kết nối lại" (xám). Chính sách đang bật cả hai nhưng phụ đề "Tự động hóa" vẫn câu cố định "Phát hành hóa đơn và gửi email tự động." — đọc như đang bật tự động trong khi thực ra không phát hành được. Phụ đề mẫu in GUID.'],
      ['ready-manual', 'Sẵn sàng · thủ công', 'Khối xanh: "Sẵn sàng phát hành" + mô tả; **không** có nhãn trên / liên kết. "1C26TAA · Có mã của cơ quan thuế". "Phát hành thủ công · Gửi email thủ công".'],
      ['ready-auto', 'Sẵn sàng · tự động', '"Phát hành tự động · Gửi email tự động".'],
      ['ready-mixed', 'Sẵn sàng · phát hành tự động', 'Mẫu 2C26TBB; "Phát hành tự động · Gửi email thủ công".'],
      ['template-unknown', 'Mẫu không còn trong danh sách', 'Đã kết nối, mẫu mặc định không có trong list_provider_templates (MISA đã xoá / đổi) → phụ đề in GUID; mức sẵn sàng vẫn "Sẵn sàng phát hành".'],
      ['loading', 'Đang tải', 'VLoading 40 giữa thân; app bar vẫn hiện.'],
      ['error', 'Lỗi tải', 'Ô 64 nền đỏ nhạt + icon ⊗; "Không thể tải dữ liệu" (18 w700 **đen**, chỉ icon đỏ); mô tả; nút link "Thử lại" sát dưới mô tả (VEmptyContent không có khe).'],
      ['no-permission', 'Không có quyền', 'Router chặn trước khi tạo cubit (einvoice.manage_configuration): ô 64 nền vàng nhạt + khoá; "Không có quyền truy cập"; mô tả; link "Quay lại".'],
    ],
  },
  {
    id: 'connection', group: 'setup', code: 'HD-02', title: 'Kết nối MISA', route: '/more/einvoice/connection', states: [
      ['form', 'Chưa kết nối', '"Thông tin kết nối" 14 w700 (spec vẽ IN HOA). Thẻ: "Nhà cung cấp | MISA meInvoice", "Mã số thuế đơn vị phát hành | 0312345678" (nhãn dài, giá trị đẩy phải). Chú thích MST. Ô "Tài khoản MISA *", "Mật khẩu MISA *" có nút mắt. Chú thích mật khẩu. Thanh dưới **nằm trong thân**: "Hủy" | "Kết nối" (web: thanh rộng bằng cột 720, không hết cửa sổ như PR-04 Theme 4).'],
      ['form-filled', 'Đã nhập', 'Tài khoản "ketoan@anphat.vn", mật khẩu chấm.'],
      ['form-invalid', 'Thiếu thông tin', 'Bấm "Kết nối" khi trống: hai ô viền đỏ + "Vui lòng nhập tài khoản MISA" / "Vui lòng nhập mật khẩu MISA"; chú thích mật khẩu vẫn hiện dưới lỗi.'],
      ['form-submitting', 'Đang kết nối', 'Hai ô khoá (mờ); "Hủy" tắt; "Kết nối" vòng xoay.'],
      ['form-reconnect', 'Kết nối lại (form)', 'Từ trạng thái lỗi bấm "Kết nối lại": về form trống, nút chính "Kết nối lại". **Không thấy trạng thái lỗi cũ / tài khoản cũ**; "Hủy" thoát luôn khỏi màn (pop) chứ không quay về thẻ lỗi.'],
      ['toast-auth-failed', 'Sai tài khoản', 'Toast đỏ "Tài khoản hoặc mật khẩu không đúng. Hãy kiểm tra lại." (tiêu đề "Không kết nối được" không vẽ). Toast **đè lên thanh "Hủy / Kết nối"** (thanh nằm trong thân, SnackBar không né).'],
      ['toast-generic', 'Lỗi khác', 'Toast đỏ "Có lỗi xảy ra, vui lòng thử lại."'],
      ['connected', 'Đã kết nối', 'Thẻ 4 hàng: "Trạng thái | Đã kết nối" (xanh lá), "Nhà cung cấp", "Tài khoản | ke***@anphat.vn", "MST đơn vị phát hành". "Cập nhật gần nhất: 09:12, 07/10/2026". Thanh dưới: "Ngắt kết nối" viền đỏ đầy ngang. Không có lối kiểm tra lại / đổi tài khoản khi đang kết nối.'],
      ['connected-no-time', 'Đã kết nối · thiếu thông tin', 'Không có tài khoản che → bỏ hàng "Tài khoản"; không có mốc kiểm tra → bỏ dòng "Cập nhật gần nhất".'],
      ['toast-connected', 'Vừa kết nối', 'Toast xanh "Kết nối MISA meInvoice thành công." trên thẻ đã kết nối.'],
      ['pending', 'Chờ kết nối', '"Chờ kết nối" xanh dương + vòng xoay 14 bên phải. Banner xanh "Đang chờ kết nối" + "Hệ thống đang tự động hoàn tất kết nối…". Trang hỏi lại mỗi 2 giây. Nút duy nhất "Ngắt kết nối" (không có "Tải lại trạng thái" dù copy có sẵn).'],
      ['error', 'Lỗi kết nối', '"Lỗi kết nối" đỏ; banner đỏ "Không thể kết nối với MISA meInvoice". Thanh dưới hai nút: "Ngắt kết nối" (viền đỏ) | "Kết nối lại" (xanh).'],
      ['toast-reconnected', 'Vừa kết nối lại', 'Toast xanh "Tài khoản kết nối MISA đã được cập nhật."'],
      ['disconnecting', 'Đang ngắt kết nối', 'isSubmitting: "Ngắt kết nối" chỉ mờ đi, **không vòng xoay** (form thì có).'],
      ['loading', 'Đang tải', 'VLoading giữa thân.'],
      ['load-error', 'Lỗi tải', 'Như HD-01.'],
      ['no-permission', 'Không có quyền', 'Route này không chặn ở router; RPC trả không quyền → cùng trạng thái khoá như HD-01.'],
    ],
  },
  {
    id: 'disconnect', group: 'setup', code: 'HD-03', title: 'Xác nhận ngắt kết nối', route: '/more/einvoice/connection', states: [
      ['default', 'Từ "Đã kết nối"', 'showVAdaptiveSheet: iPhone sheet đáy (tay kéo, "Ngắt kết nối MISA?" + gạch); web 1280 hộp thoại 480 giữa màn có nút × (khác các sheet đáy 640 của Theme 4). Nội dung xám; "Ngắt kết nối" nền đỏ, "Giữ kết nối" viền — nút nguy hiểm đứng trên.'],
      ['from-error', 'Từ "Lỗi kết nối"', 'Nền là trạng thái lỗi kết nối (hai nút).'],
    ],
  },
  {
    id: 'issuance', group: 'setup', code: 'HD-04', title: 'Cấu hình phát hành', route: '/more/einvoice/issuance', states: [
      ['selected', 'Đã chọn mẫu', 'Câu giới thiệu "…mẫu hóa đơn và **hình thức ký số** mặc định…" nhưng màn chỉ có ô chọn mẫu. Ô "Mẫu hóa đơn *" hiện "1C26TAA" + mũi tên ▾; dòng mô tả "Đồng bộ gần nhất: 09:15, 07/10/2026". Thẻ "Thông tin mẫu": Ký hiệu / Cấp mã / Loại hóa đơn. "Hủy" | "Lưu" luôn bấm được (không theo dõi đã đổi hay chưa).'],
      ['menu', 'Mở danh sách mẫu', 'Menu xổ ngay dưới ô, rộng bằng ô, viền + bóng nhẹ; 3 dòng chỉ ký hiệu (không tên loại hóa đơn); **dòng đang chọn không đánh dấu**. Mũi tên đổi xanh.'],
      ['selected-other', 'Mẫu máy tính tiền', '"1C26TVE"; Loại hóa đơn "Hóa đơn giá trị gia tăng (máy tính tiền)" dài → xuống dòng canh phải.'],
      ['empty', 'Chưa chọn mẫu', 'Ô trống hint "Chọn mẫu hóa đơn" xám; không có thẻ thông tin.'],
      ['empty-no-sync', 'Chưa đồng bộ', 'Không có mốc đồng bộ → bỏ dòng "Đồng bộ gần nhất".'],
      ['invalid', 'Thiếu mẫu', 'Bấm "Lưu" khi trống: viền đỏ + "Vui lòng chọn mẫu hóa đơn" thay dòng đồng bộ.'],
      ['submitting', 'Đang lưu', 'Cả ô chọn (kèm nhãn, dòng đồng bộ) mờ 0.4; "Hủy" tắt; "Lưu" vòng xoay.'],
      ['toast-saved', 'Đã lưu', 'Toast xanh "Mẫu hóa đơn mặc định đã được cập nhật."; **ở lại màn** (không tự quay về tổng quan). Toast đè thanh dưới.'],
      ['toast-incompatible', 'Mẫu không tương thích', 'Toast đỏ "Mẫu hóa đơn không tương thích với cấu hình ký hiện tại."'],
      ['toast-not-connected', 'Chưa kết nối', 'Toast đỏ "Cần kết nối MISA trước khi lưu mẫu hóa đơn mặc định."'],
      ['toast-error', 'Lỗi lưu', 'Toast đỏ "Có lỗi xảy ra, vui lòng thử lại."'],
      ['loading', 'Đang tải', 'VLoading giữa thân.'],
      ['load-error', 'Lỗi tải', 'Như HD-01.'],
      ['no-permission', 'Không có quyền', 'Như HD-01.'],
    ],
  },
  {
    id: 'automation', group: 'setup', code: 'HD-05', title: 'Tự động hóa', route: '/more/einvoice/automation', states: [
      ['off', 'Đang tắt cả hai', 'Thẻ "Quy tắc tự động" (spec vẽ IN HOA): hai hàng nhãn 14 w700 + công tắc; mô tả xám bên dưới; gạch giữa. Mô tả gửi email dài 4 dòng trên iPhone. "Hủy" | "Lưu".'],
      ['issue-on', 'Bật phát hành', 'Công tắc 1 xanh. Có thể bật "Tự động gửi email" khi "Tự động phát hành" tắt (không ràng buộc).'],
      ['both-on', 'Bật cả hai', 'Hai công tắc xanh.'],
      ['submitting', 'Đang lưu', 'Chỉ công tắc mờ; nhãn và mô tả giữ màu; "Lưu" vòng xoay.'],
      ['toast-saved', 'Đã lưu', 'Toast xanh "Quy tắc phát hành và gửi email đã được cập nhật."; ở lại màn.'],
      ['toast-not-ready', 'Chưa đủ điều kiện', 'Bật tự động khi thiết lập chưa xong: toast đỏ "Cần hoàn tất thiết lập…"; công tắc vẫn bật trên màn (không tự trả về).'],
      ['toast-state-changed', 'Thiết lập đã đổi', 'Toast vàng "Chính sách tự động đã được cập nhật ở nơi khác. Hãy tải lại rồi lưu lại." — màn không có nút tải lại.'],
      ['toast-error', 'Lỗi lưu', 'Toast đỏ "Có lỗi xảy ra, vui lòng thử lại."'],
      ['loading', 'Đang tải', 'VLoading giữa thân.'],
      ['load-error', 'Lỗi tải', 'Như HD-01.'],
      ['no-permission', 'Không có quyền', 'Như HD-01.'],
    ],
  },
  {
    id: 'result', group: 'order', code: 'HD-06', title: 'Dòng HĐĐT · Kết quả bán hàng', route: '/sales/result/o1', states: [
      ['not-issued', 'Chưa phát hành', 'Màn SG-06 (route cấp gốc, ngoài khung): app bar "Kết quả bán hàng" **không có ←**; thanh dưới "Về trang chủ" | "Tạo đơn mới". Cuộn tới cuối: khối "Chứng từ & hóa đơn" (14 w700) gồm "Phiếu bán hàng" và dòng HĐĐT: icon tệp ✓ 24, "Hóa đơn điện tử" 14 w700, "Quản lý HĐĐT" xám, badge xám "Chưa phát hành", ›. Hai thẻ trong cùng khối khác số đo: phiếu (icon cách 12, tiêu đề w600) vs HĐĐT (icon cách 16, tiêu đề w700). Lúc mới vào, dòng hiện "Chưa phát hành" khi chưa tải xong trạng thái thật và chưa bấm được — trông y như bấm được.'],
      ['processing', 'Đang xử lý', 'Badge xanh nhạt "Đang xử lý"; dòng vẫn có › nhưng bấm không có gì xảy ra (không mờ, không vòng xoay). Sau khi xác nhận phát hành **không có toast thành công** — chỉ badge đổi.'],
      ['issued', 'Đã phát hành', 'Badge xanh "Đã phát hành". Trạng thái gửi email (Đã gửi / Gửi lỗi) **không hiện trên dòng**, phải mở sheet mới thấy.'],
      ['failed', 'Phát hành lỗi', 'Badge đỏ "Phát hành lỗi"; phụ đề vẫn "Quản lý HĐĐT" (không nói lỗi gì).'],
      ['buyer-not-ready', 'Người mua thiếu thông tin', 'Phụ đề vàng "Chưa đủ thông tin"; badge vẫn "Chưa phát hành".'],
      ['unavailable', 'Không tải được khối HĐĐT', 'Thiếu dữ liệu đơn / repository: thẻ dự phòng SalesEntryRow "Hóa đơn điện tử" + "Quản lý hóa đơn" + badge vàng "Chưa tải được"; có › nhưng không bấm được.'],
    ],
  },
  {
    id: 'detail', group: 'order', code: 'HD-06', title: 'Dòng HĐĐT · Chi tiết đơn', route: '/sales/orders/o1', states: [
      ['not-issued', 'Chưa phát hành', 'Màn SG-08 "Chi tiết đơn hàng" + ←; thanh dưới "Thao tác ⌃" (nút 52). Cuộn tới cuối: Sản phẩm, rồi "Chứng từ & hóa đơn": Phiếu bán hàng / **Hóa đơn điện tử** / Lịch sử. Dòng HĐĐT giống hệt SG-06.'],
      ['processing', 'Đang xử lý', 'Như SG-06.'],
      ['issued', 'Đã phát hành', 'Như SG-06.'],
      ['failed', 'Phát hành lỗi', 'Như SG-06.'],
      ['buyer-not-ready', 'Người mua thiếu thông tin', 'Phụ đề vàng "Chưa đủ thông tin".'],
      ['toast-preview-error', 'Lỗi xem trước', 'Bấm "Kiểm tra & xem trước" lỗi → sheet tự đóng, toast đỏ "Xem trước hóa đơn chưa sẵn sàng. Vui lòng thử lại sau ít giây." trên thanh "Thao tác".'],
      ['toast-no-template', 'Chưa chọn mẫu', 'Bấm "Phát hành" khi chưa có mẫu mặc định: toast đỏ "Chưa chọn mẫu hóa đơn. Vui lòng cập nhật cấu hình phát hành." — không có lối mở thiết lập.'],
      ['toast-document', 'Lỗi lưu tài liệu', 'Toast đỏ "Không thể lưu tài liệu hóa đơn trên thiết bị. Vui lòng thử lại."'],
    ],
  },
  {
    id: 'pre-issue', group: 'order', code: 'HD-07', title: 'Sheet trước phát hành', route: '/sales/orders/o1', states: [
      ['default', 'Sẵn sàng phát hành', 'showVAdaptiveSheet "Hóa đơn điện tử": iPhone sheet đáy, web hộp thoại 480 có ×. Ba thẻ thao tác (đệm 16 / 8 ngoài, 16 trong): "Phát hành hóa đơn điện tử" (Gửi phát hành qua MISA), "Kiểm tra & xem trước", "Gửi hóa đơn" + badge nhỏ "Chưa gửi" **luôn mờ** (chưa phát hành thì không gửi được nhưng vẫn hiện).'],
      ['preview-loading', 'Đang tạo xem trước', 'Thẻ xem trước mờ + vòng xoay 20 thay ›; "Phát hành" cũng mờ.'],
      ['buyer-not-ready', 'Người mua thiếu thông tin', 'Banner vàng "Chưa đủ thông tin để phát hành" + link xanh đậm "Cập nhật thông tin khách hàng" (mở sửa khách, sheet đóng). "Phát hành" mờ, phụ đề "Cần bổ sung đủ thông tin". Không nói thiếu trường nào.'],
      ['buyer-no-partner', 'Thiếu thông tin · khách lẻ', 'Không có mã khách → không có link sửa; banner vàng nhưng không có lối xử lý.'],
      ['not-connected', 'MISA chưa kết nối', 'Blocker PROVIDER_NOT_CONNECTED: "Phát hành" mờ, phụ đề vẫn "Gửi phát hành qua MISA" — **không có dòng nào giải thích** vì sao tắt, không có lối mở thiết lập. Xem trước vẫn bấm được.'],
      ['preview-unsupported', 'Không hỗ trợ xem trước', 'Thẻ "Kiểm tra & xem trước" mờ, không giải thích.'],
      ['failed-provider', 'Lỗi · MISA từ chối', 'Mở lại sau lỗi: banner đỏ "Phát hành hóa đơn điện tử không thành công" + thông điệp nguyên văn của MISA. Thẻ vẫn ghi "Phát hành hóa đơn điện tử" (không đổi thành "Phát hành lại").'],
      ['failed-integrity', 'Lỗi · dữ liệu không khớp', '"Dữ liệu đơn hàng hoặc cấu hình không khớp. Vui lòng kiểm tra lại."'],
      ['failed-generic', 'Lỗi · không rõ', '"Đã xảy ra lỗi khi phát hành hóa đơn điện tử. Vui lòng kiểm tra và thử lại."'],
    ],
  },
  {
    id: 'confirm', group: 'order', code: 'HD-08', title: 'Xác nhận phát hành', route: '/sales/orders/o1', states: [
      ['default', 'Có mã CQT', '"Phát hành hóa đơn điện tử?"; "Đơn hàng #DH-000129 · Tổng tiền 5.199.232đ"; "Mẫu C26TAA · Ký hiệu 1C26TAA · Có mã CQT" — **"Mẫu" in serial** (C26TAA, gần trùng ký hiệu) chứ không phải số mẫu. Nút chính "Phát hành hóa đơn điện tử" trên, "Hủy" dưới. Không nhắc người mua / email nhận.'],
      ['mtt', 'Máy tính tiền', '"… · Máy tính tiền".'],
      ['no-signing', 'Chưa có hình thức ký', 'Hồ sơ không có hình thức ký → "… · —".'],
    ],
  },
  {
    id: 'post-issue', group: 'order', code: 'HD-09', title: 'Sheet sau phát hành', route: '/sales/orders/o1', states: [
      ['not-sent', 'Chưa gửi', 'Sheet "Hóa đơn điện tử" (cùng tiêu đề với HD-07): "Xem hóa đơn điện tử", "Tài liệu XML & PDF", "Gửi hóa đơn" + badge xám "Chưa gửi" (cỡ thường; HD-07 dùng cỡ nhỏ). Không có số hóa đơn / ngày phát hành / mã tra cứu trong sheet.'],
      ['sent', 'Đã gửi', 'Badge xanh "Đã gửi"; bấm "Gửi hóa đơn" mở HD-12 (gửi lại).'],
      ['sending', 'Đang gửi', 'Badge "Đang gửi"; thẻ gửi mờ.'],
      ['failed', 'Gửi lỗi', 'Badge đỏ "Gửi lỗi"; phụ đề vẫn "Gửi qua email".'],
      ['unknown', 'Không xác định', 'Badge vàng "Không xác định kết quả" dài đẩy chữ hẹp lại; phụ đề "Lần gửi gần nhất cần được kiểm tra trong lịch sử gửi." — lịch sử chỉ mở được từ HD-12.'],
      ['pending', 'Đang chờ gửi tự động', 'deliveryPending: badge "Đã gửi" nhưng thẻ gửi mờ, không giải thích.'],
      ['official-loading', 'Đang mở bản chính thức', 'Thẻ "Xem hóa đơn điện tử" vòng xoay; hai thẻ còn lại mờ.'],
    ],
  },
  {
    id: 'documents', group: 'order', code: 'HD-10', title: 'Tài liệu hóa đơn điện tử', route: '/sales/orders/o1', states: [
      ['idle', 'Chọn tài liệu', 'Sheet "Tài liệu hóa đơn điện tử": "Lưu bản PDF" (icon tệp trống), "Lưu tệp XML" (icon tệp có dòng). Không có tên tệp / dung lượng.'],
      ['loading-pdf', 'Đang lưu PDF', 'Thẻ PDF vòng xoay + mờ; thẻ XML **không mờ** nhưng không bấm được.'],
      ['loading-xml', 'Đang lưu XML', 'Ngược lại.'],
    ],
  },
  {
    id: 'send', group: 'order', code: 'HD-11', title: 'Gửi hóa đơn điện tử', route: '/sales/orders/o1', states: [
      ['suggested', 'Email từ hồ sơ khách', 'Sheet "Gửi hóa đơn điện tử": ô "Email người nhận *" đã điền; mô tả "Email chỉ áp dụng cho lần gửi này."; dòng nguồn "Hồ sơ khách hàng" (xám, trông như mô tả thứ hai). "Gửi hóa đơn" | "Hủy" xếp dọc. Một ô email, không thêm CC.'],
      ['last-used', 'Email dùng gần nhất', 'Nguồn "Email đã dùng gần nhất cho khách hàng này".'],
      ['empty', 'Chưa có email', 'Ô trống hint "Nhập email", không dòng nguồn; "Gửi hóa đơn" mờ.'],
      ['invalid', 'Email sai', 'Viền đỏ + "Email không đúng định dạng." thay mô tả; nút mờ.'],
      ['submitting', 'Đang gửi', 'Ô khoá; "Gửi hóa đơn" vòng xoay; "Hủy" tắt.'],
      ['locked', 'Đang có lệnh gửi khác', 'operationLocked: ô khoá, nút mờ — **không hiện câu "Yêu cầu gửi trước đang được xử lý…"** dù copy có sẵn.'],
      ['snack-error', 'Lỗi gửi', 'Lỗi gửi hiện bằng **SnackBar Material mặc định** (không phải VToast) gắn vào Scaffold của màn đơn → nằm dưới lớp phủ và dưới sheet: iPhone bị sheet che hẳn, web chỉ thấy dải tối mờ ở đáy.'],
    ],
  },
  {
    id: 'resend', group: 'order', code: 'HD-12', title: 'Gửi lại hóa đơn điện tử', route: '/sales/orders/o1', states: [
      ['default', 'Gửi lại', 'Sheet "Gửi lại hóa đơn điện tử": email điền sẵn theo **lần gửi cuối** (mua.hang@…, lần đó không xác định kết quả), nguồn "Lần gửi gần nhất của hóa đơn này"; dưới là "Đã gửi gần nhất đến ketoan@… · 07/10/2026, 14:36" (lần **thành công** cuối) → hai email khác nhau cạnh nhau. Link "Xem lịch sử gửi" giữa. Nút chính vẫn là "Gửi hóa đơn" (không phải "Gửi lại").'],
      ['no-success', 'Chưa lần nào thành công', 'Không có dòng "Đã gửi gần nhất…", chỉ còn link lịch sử.'],
      ['invalid', 'Email sai', 'Lỗi định dạng; nút mờ.'],
      ['submitting', 'Đang gửi', 'Link lịch sử mờ; nút vòng xoay.'],
    ],
  },
  {
    id: 'history', group: 'order', code: 'HD-13', title: 'Lịch sử gửi hóa đơn', route: '/sales/orders/o1/einvoice-history', states: [
      ['loaded', 'Có lịch sử', 'Trang đẩy bằng MaterialPageRoute từ sheet (không phải route GoRouter): "Lịch sử gửi hóa đơn" + ←. "Các lần gửi"; thẻ 3 hàng, mới nhất trên: "Không xác định kết quả · mua.hang@…" + badge cùng chữ (**trạng thái lặp hai lần** mỗi hàng); "08/10/2026 · 09:10 · Người dùng". Không có lý do lỗi.'],
      ['empty', 'Chưa có', 'VEmptyState có viền giữa màn: icon hộp thư + "Chưa có lịch sử gửi hóa đơn." (có dấu chấm trong tiêu đề).'],
      ['error', 'Lỗi tải', 'Tiêu đề và mô tả **cùng một câu** "Không thể tải lịch sử gửi hóa đơn."; nút "Thử lại" kiểu tertiary.'],
      ['loading', 'Đang tải', 'VLoading giữa.'],
    ],
  },
];

export const CASES = Object.fromEntries(SCREENS.map((s) => [s.id, s.states.map(([id]) => id)]));
