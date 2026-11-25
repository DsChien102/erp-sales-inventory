// Danh sách ca dùng chung: main.js, viewer.js, tools/capture.mjs.
// Mỗi màn thuộc một nhóm (đợt): public (đợt 1), admin (đợt 2), account (đợt 3).
// Mỗi state: [mã, nhãn ngắn, điều cần nhìn]. Ghi chú mô tả bản iPhone (chép Flutter); bản web thiết kế lại ghi ở WEB_NOTES cuối file.
// Ca chỉ có trên iPhone: IPHONE_ONLY cuối file; còn lại vẽ ở cả hai khổ (iPhone 390, Web 1280).
export const GROUPS = [
  { id: 'public', title: 'Công khai (đợt 1)' },
  { id: 'admin', title: 'Quản trị (đợt 2)' },
  { id: 'account', title: 'Tài khoản (đợt 3)' },
];

export const SCREENS = [
  {
    id: 'login', group: 'public', code: 'ID-01', title: 'Đăng nhập', route: '/login', states: [
      ['default', 'Mặc định', 'Thương hiệu căn giữa (icon app 64 × 64), thẻ form (hai ô, "Đăng nhập", "Quên mật khẩu?"), danh sách hai dòng Đăng ký cửa hàng mới / Kích hoạt tài khoản. Dòng bản quyền bị Spacer đẩy xuống đáy.'],
      ['empty-submit', 'Bấm Đăng nhập khi trống', 'Lỗi dưới từng ô (VFieldError), viền đỏ. Không có banner.'],
      ['wrong-credentials', 'Sai email / mật khẩu', '"Email hoặc mật khẩu không chính xác." hiện dưới ô Email (không phải ô Mật khẩu), không toast.'],
      ['network', 'Lỗi mạng (ID-x1)', 'Banner đỏ "Đăng nhập thất bại" ngay dưới ô Mật khẩu, trên nút "Đăng nhập".'],
      ['submitting', 'Đang đăng nhập', 'Nút chính có vòng xoay và mờ (onPressed null → vDisabledOpacity); "Quên mật khẩu?" và hai dòng lối vào cũng mờ.'],
      ['forgot-no-email', 'Quên mật khẩu khi chưa nhập email', 'Bấm "Quên mật khẩu?" khi ô Email trống → lỗi dưới ô Email.'],
      ['joined', 'Đã tham gia tổ chức (ID-x2)', 'Sau kích hoạt lời mời: banner xanh "Tham gia tổ chức thành công", email điền sẵn.'],
      ['reset-success', 'Banner đổi mật khẩu', 'Từ Tài khoản của tôi → đổi mật khẩu xong → đăng xuất về đây: banner xanh.'],
      ['reset-toast', 'Toast đặt lại mật khẩu', 'Quay về từ Quên mật khẩu: toast (chỉ hiện câu message, không hiện title). Web: toast kéo hết bề ngang.'],
    ],
  },
  {
    id: 'signup', group: 'public', code: 'ID-02', title: 'Đăng ký cửa hàng', route: '/signup', states: [
      ['account', 'Bước 1 · Tài khoản', 'Thanh tiến độ 3 đoạn; 6 ô (Họ và tên đệm + Tên cùng hàng); mô tả quy tắc mật khẩu dưới ô Mật khẩu; "Tiếp tục" + link "Đã có tài khoản? Đăng nhập".'],
      ['account-errors', 'Bước 1 · Lỗi', 'Bấm Tiếp tục: lỗi dưới từng ô; lỗi thay chỗ dòng mô tả mật khẩu. Số điện thoại không bắt buộc (không có *).'],
      ['store', 'Bước 2 · Cửa hàng', 'Email liên hệ tự điền email tài khoản; ô Xã / phường tắt khi chưa chọn tỉnh; hai nút chia đôi.'],
      ['store-errors', 'Bước 2 · Lỗi', 'Lỗi dưới tên, SĐT, tỉnh, xã, địa chỉ. Ô tỉnh / xã viền đỏ.'],
      ['store-filled', 'Bước 2 · Đã điền', 'Ô tỉnh / xã có giá trị: thêm nút xoá ×.'],
      ['picker-province', 'Chọn tỉnh (sheet)', 'Sheet "Khu vực hành chính" cao 75% màn. Web: hộp thoại 480 có hai nút Đóng (của hộp thoại + của sheet).'],
      ['picker-ward', 'Chọn xã (sheet)', 'Tab 2 sau khi chọn tỉnh; tab 1 hiện tên tỉnh + dấu ✓.'],
      ['store-submitting', 'Đang tạo cửa hàng', '"Đang tạo..." + vòng xoay; "Quay lại" mờ.'],
      ['server-error', 'Lỗi máy chủ', 'Banner đỏ chỉ có tiêu đề (câu lỗi làm tiêu đề, không có mô tả) giữa thanh bước và form.'],
      ['email-exists', 'Email đã đăng ký', 'Thay cả form bằng một dòng lỗi đỏ + "Đăng nhập" + "Quên mật khẩu". Thanh bước vẫn ở bước 2.'],
      ['verify', 'Bước 3 · Xác minh email', 'VerifyEmailView: ô 6 số, "Xác minh", "Gửi lại mã sau 00:59" (chữ thường). Không có tiêu đề riêng (tiêu đề chỉ ở thanh bước).'],
      ['verify-error', 'Bước 3 · Sai mã', 'Cả sáu ô viền đỏ, vòng đỏ nhạt chỉ ở ô đang focus; chữ số không đỏ; dòng lỗi đỏ bên dưới.'],
    ],
  },
  {
    id: 'verify', group: 'public', code: 'ID-03', title: 'Xác minh email', route: '/verify-email', states: [
      ['default', 'Vào từ Đăng nhập (ID-x4)', 'Thẻ nhập mã trên nền xám, biểu tượng thư + tiêu đề canh giữa; "Gửi lại mã" bấm được ngay (allowImmediateResend), không đếm ngược; "Đăng xuất" dạng link ở đáy màn.'],
      ['countdown', 'Sau khi gửi lại', 'Đếm ngược "Gửi lại mã sau 00:59" là chữ thường (không bấm được), hết giờ thành link "Gửi lại mã".'],
      ['filled', 'Đủ 6 số (thoáng qua)', 'Thoáng qua: đủ mã là onCompleted tự gửi xác minh ngay → chuyển sang "Đang xác minh". Nút "Xác minh" gần như không cần bấm.'],
      ['submitting', 'Đang xác minh', 'Ô mã mờ; nút "Xác minh" có vòng xoay.'],
      ['error', 'Sai mã', 'Dòng lỗi đỏ; mọi ô viền đỏ, vòng đỏ nhạt chỉ ở ô đang focus, chữ số không đỏ.'],
      ['resend-failed', 'Gửi lại mã lỗi', 'Gửi lại lỗi: toast đỏ, ô mã không đỏ, "Gửi lại mã" bấm lại được.'],
    ],
  },
  {
    id: 'reset', group: 'public', code: 'ID-04 · ID-23', title: 'Đặt lại mật khẩu', route: '/login/reset-password', states: [
      ['requesting', 'Đang gửi mã', 'Vào màn là gửi mã ngay: chỉ có app bar + vòng tải 40 giữa màn, nền trắng.'],
      ['request-failed', 'Gửi mã lỗi', 'Thân giữa màn "Không gửi được mã" + câu lỗi + "Thử lại", đồng thời toast đỏ cùng câu (lặp hai lần).'],
      ['verify', 'Bước 1 · Nhập mã', 'Thanh 2 bước, tiêu đề canh trái, ô mã trải hết bề ngang, ghi chú 10 phút ngay dưới ô mã. Đếm ngược là chữ thường; hết giờ thành link "Gửi lại mã".'],
      ['verify-filled', 'Bước 1 · Đủ 6 số (thoáng qua)', 'Thoáng qua: đủ mã là onCompleted gọi xác nhận ngay → lớp phủ "Đang xác nhận". "Xác nhận mã" chỉ bật trong khoảnh khắc này.'],
      ['verifying', 'Đang xác nhận mã', 'Lớp phủ trắng 50% + vòng tải 40 phủ cả màn.'],
      ['verify-wrong', 'Sai mã', 'Không có lỗi dưới ô (errorText không được truyền): chỉ toast đỏ "Mã xác minh không đúng hoặc đã hết hạn.".'],
      ['resend-ready', 'Hết đếm ngược', '"Gửi lại mã" bật.'],
      ['resent-toast', 'Đã gửi lại mã', 'Toast xanh dương "Đã gửi lại mã xác nhận."; đếm lại "00:60" (nhãn luôn 00:ss).'],
      ['create', 'Bước 2 · Mật khẩu mới', 'Thanh 2 bước, tiêu đề 22, hai ô gợi ý "••••", thẻ "Quy tắc mật khẩu"; thanh dưới "Quay lại" | "Đặt lại mật khẩu" (mờ khi chưa nhập đủ).'],
      ['create-filled', 'Bước 2 · Đã nhập', 'Nút "Đặt lại mật khẩu" bật.'],
      ['create-errors', 'Bước 2 · Lỗi', 'Lỗi dưới hai ô + toast đỏ "Vui lòng kiểm tra lại…".'],
      ['create-submitting', 'Đang đặt lại', 'Lớp phủ trắng 50% + vòng tải.'],
      ['from-account', 'Từ Tài khoản của tôi (ID-23)', '/more/my-account/reset-password: cùng màn, mã gửi tới email đang đăng nhập; trong khung StoreShell (web ≥ 1024 có thanh bên 84; ảnh vẽ trang trần).'],
    ],
  },
  {
    id: 'no-org', group: 'public', code: 'ID-05', title: 'Chưa thuộc tổ chức', route: '/no-organization', states: [
      ['default', 'Mặc định', 'Biểu tượng tòa nhà + tiêu đề + mô tả canh giữa; "Nhập mã lời mời" và "Đăng xuất" (link) ở đáy màn.'],
    ],
  },
  {
    id: 'invitation', group: 'public', code: 'ID-06 · ID-07', title: 'Lời mời', route: '/invitation', states: [
      ['entry', 'Nhập mã', 'Nền trắng: tiêu đề + hướng dẫn canh trái, ô mã 8 ký tự nhóm 4 + 4 (cao 52), mô tả "Mã không phân biệt…"; "Tiếp tục" ngay dưới ô mã.'],
      ['entry-partial', 'Đang nhập', '4/8 ký tự; ô thứ 5 có viền xanh + vòng. Đủ 8 ký tự là tự gửi kiểm mã (không cần bấm Tiếp tục).'],
      ['entry-empty', 'Bấm Tiếp tục khi trống', '"Vui lòng nhập mã lời mời".'],
      ['entry-format', 'Mã chưa đủ 8 ký tự', '"Mã lời mời phải gồm 8 ký tự chữ hoặc số".'],
      ['entry-invalid', 'Mã không hợp lệ', 'Lỗi từ máy chủ hiện dưới ô.'],
      ['entry-expired', 'Mã hết hạn', '"Mã lời mời đã hết hạn. Liên hệ người gửi để nhận mã mới."'],
      ['entry-network', 'Lỗi mạng khi kiểm mã', '"Không thể xác thực mã. Kiểm tra kết nối và thử lại."'],
      ['inspecting', 'Đang kiểm mã', '"Tiếp tục" có vòng xoay; ô mã và nút ← mờ.'],
      ['confirm', 'Sheet xác nhận', 'Hiện cho cả tài khoản đã có và chưa có. Web: hộp thoại 480, nội dung có hai lớp đệm (hộp thoại 16 + nội dung 16).'],
      ['accepting', 'Đang tiếp nhận (tài khoản đã có)', 'Sau "Xác nhận": quay về màn nhập mã với nút đang xoay, rồi sang /login (banner).'],
      ['register', 'Đăng ký tài khoản mới', 'Dấu tích + "Mã lời mời hợp lệ", họ + tên cùng hàng, email khoá là một dòng có biểu tượng khoá; "Kích hoạt tài khoản" ngay dưới form.'],
      ['register-errors', 'Đăng ký · Lỗi', 'Lỗi dưới từng ô; nhãn "Xác nhận mật khẩu" (đăng ký cửa hàng ghi "Nhập lại mật khẩu").'],
      ['register-filled', 'Đăng ký · Đã điền', 'Đủ thông tin.'],
      ['register-submitting', 'Đăng ký · Đang gửi', 'Mọi ô mờ, nút có vòng xoay.'],
      ['register-failed', 'Đăng ký · Lỗi máy chủ', 'Toast đỏ (chỉ câu message); hai ô mật khẩu bị xoá trắng.'],
      ['declined', 'Đã từ chối', 'Màn kết quả nền trắng, không app bar: biểu tượng + tiêu đề + câu canh giữa; "Nhập mã khác" ở đáy màn.'],
      ['blocked', 'Không thể tiếp tục', 'Lỗi khi tiếp nhận (ví dụ bị thu hồi giữa chừng): câu lỗi từ máy chủ.'],
    ],
  },
  // ================================================================ đợt 2 — quản trị (route trong StoreShell; ảnh vẽ trang trần nên không có thanh bên)
  {
    id: 'org-profile', group: 'admin', code: 'ID-11', title: 'Hồ sơ tổ chức', route: '/more/organization-profile', states: [
      ['no-legal', 'Chưa có hồ sơ pháp lý', 'Tên tổ chức đầu màn; thẻ thông tin; thẻ pháp lý gồm hộp vàng "Chưa có hồ sơ pháp lý" + dòng nhắc "Bổ sung…" + link. Nút "Thao tác ⌃" ở thanh dưới.'],
      ['with-legal', 'Đã có hồ sơ pháp lý', 'Thẻ pháp lý 4 dòng, không hộp vàng. Địa chỉ đăng ký dài xuống dòng canh phải.'],
      ['loading', 'Đang tải', 'VLoading 40 giữa màn.'],
      ['error', 'Lỗi tải', '"Không tải được hồ sơ" + câu lỗi + "Thử lại" giữa màn.'],
      ['forbidden', 'Không có quyền', 'OrganizationEmptyView: "Không có quyền xem tổ chức" — câu "…quản lý tổ chức nền tảng" còn sót từ quản trị nền tảng.'],
      ['actions', 'Sheet Thao tác', 'Không tiêu đề sheet; tự vẽ "Thao tác hồ sơ" + 2 thẻ.'],
      ['actions-legal', 'Sheet Thao tác (đã có pháp lý)', 'Thẻ 2 đổi thành "Chỉnh sửa hồ sơ pháp lý".'],
      ['toast-saved', 'Toast đã lưu thông tin', 'Quay về sau khi sửa: toast chỉ hiện câu message, nổi trên thanh dưới.'],
      ['toast-legal-saved', 'Toast đã lưu pháp lý', 'message rỗng → hiện title "Đã lưu hồ sơ pháp lý."'],
    ],
  },
  {
    id: 'org-edit', group: 'admin', code: 'ID-12', title: 'Chỉnh thông tin tổ chức', route: '/more/organization-profile/edit', states: [
      ['filled', 'Mặc định (điền sẵn)', 'Thẻ liên hệ (tên, SĐT, email) + thẻ địa chỉ (tỉnh, xã, địa chỉ); tỉnh / xã không bắt buộc (không *); câu ghi chú dưới form. Thanh dưới Hủy | Lưu thay đổi.'],
      ['errors', 'Bấm Lưu khi thiếu', 'Lỗi dưới từng ô; "Tên hiển thị." bị lỗi thay chỗ.'],
      ['submitting', 'Đang lưu', '"Lưu thay đổi" vòng xoay, "Hủy" mờ; các ô vẫn sửa được.'],
      ['discard', 'Rời khi đã sửa', 'VConfirmDialog "Bỏ thay đổi?" — hai nút dồn phải.'],
      ['toast-state-changed', 'Dữ liệu đã thay đổi', 'Toast vàng (chỉ câu message), vẫn ở lại form.'],
      ['toast-failed', 'Lỗi lưu', 'Toast đỏ "Không thể kết nối…".'],
      ['loading', 'Đang tải', 'VLoading giữa màn.'],
    ],
  },
  {
    id: 'org-legal', group: 'admin', code: 'ID-13', title: 'Hồ sơ pháp lý', route: '/more/organization-profile/legal', states: [
      ['add-empty', 'Thêm mới', 'Tiêu đề "Thêm hồ sơ pháp lý"; hai thẻ; "Loại chủ thể" * là hai nút Hộ kinh doanh | Doanh nghiệp; mô tả mã số thuế; câu ghi chú dưới form.'],
      ['add-errors', 'Bấm Lưu khi trống', 'Lỗi dưới 3 ô (hai nút loại chủ thể viền đỏ) + toast đỏ "Vui lòng điền đầy đủ…" — báo hai lần.'],
      ['add-tax-format', 'Mã số thuế sai dạng', 'Câu lỗi dài thay dòng mô tả; vẫn kèm toast "Thiếu thông tin" dù không thiếu.'],
      ['edit-filled', 'Chỉnh sửa', 'Tiêu đề "Chỉnh hồ sơ pháp lý", điền sẵn.'],
      ['submitting', 'Đang lưu', '"Lưu hồ sơ" vòng xoay.'],
      ['duplicate', 'Mã số thuế trùng (sheet)', 'Sheet cảnh báo: tiêu đề, câu, hộp vàng, "Vẫn lưu" / "Kiểm tra lại".'],
      ['discard', 'Rời khi đã sửa', 'Hộp thoại "Bỏ thay đổi?" như ID-12.'],
      ['loading', 'Đang tải', 'VLoading giữa màn.'],
    ],
  },
  {
    id: 'users', group: 'admin', code: 'ID-14', title: 'Người dùng', route: '/more/users', states: [
      ['members', 'Tab Thành viên', 'App bar "Người dùng · 3 thành viên"; tab hai nút liền; ô tìm + bộ lọc (nền trắng); chip nhanh; thẻ (tên, nhãn, email, vai trò); "Mời thành viên" ở thanh dưới.'],
      ['invitations', 'Tab Lời mời', 'Thẻ email + dòng vai trò + dòng "hạn · gửi" + nhãn (Đang chờ vàng, Sắp hết hạn / Lỗi gửi đỏ, Hết hạn xám).'],
      ['loading', 'Đang tải thành viên', 'Phụ đề "Đang tải thành viên"; VLoading dưới hàng chip; thanh dưới vẫn hiện.'],
      ['invitations-loading', 'Đang tải lời mời', 'Phụ đề "Đang tải lời mời".'],
      ['invitations-empty', 'Chưa có lời mời', 'Hộp icon 56 + "Chưa có lời mời" + nút "Mời thành viên" (khung cao 480 canh giữa); không có thanh dưới.'],
      ['no-results', 'Không có kết quả', 'Tìm "hoàng": phụ đề "0 kết quả", "Không tìm thấy kết quả" + "Xóa bộ lọc".'],
      ['chip-suspended', 'Chip Tạm ngừng', 'Chip đang chọn tone primary; còn 1 thẻ.'],
      ['forbidden', 'Không có quyền', 'Khiên vàng, "Bạn không có quyền quản lý" + nút xanh "Quay lại". Phụ đề "Chưa cấp quyền".'],
      ['error', 'Lỗi tải', 'Dấu × đỏ, tiêu đề đỏ, nút đỏ "Thử lại".'],
      ['filter-members', 'Bộ lọc thành viên (sheet)', 'Sheet có tiêu đề + gạch; chip kiểu riêng (viền / nền xanh nhạt) khác chip nhanh. Web: hộp thoại 480.'],
      ['filter-invitations', 'Bộ lọc lời mời (sheet)', 'Kết quả gửi, Thời gian (Tùy chọn mở chọn khoảng ngày).'],
      ['filter-applied', 'Bộ lọc đang áp dụng', 'Chấm xanh 8 ở góc nút bộ lọc; chip nhanh vẫn "Tất cả" (vai trò lọc không hiện ra ngoài).'],
      ['toast-revoked', 'Toast đã thu hồi', 'Hẹp: về danh sách, toast đáy.'],
    ],
  },
  {
    id: 'invite', group: 'admin', code: 'ID-15', title: 'Mời thành viên', route: '/more/users/invite', states: [
      ['empty', 'Mặc định', 'Thẻ Email (ghi chú dưới ô) + thẻ "Vai trò ban đầu" 4 dòng radio có mô tả. Gợi ý "nhanvien@minhphat.vn" (không phải tên cửa hàng).'],
      ['filled', 'Đã điền', 'Chọn "Nhân viên bán hàng".'],
      ['empty-submit', 'Bấm Gửi khi trống', 'Chỉ ô Email báo "Vui lòng nhập email và chọn vai trò." — ô vai trò không đỏ.'],
      ['no-role', 'Thiếu vai trò', 'Lỗi giống câu trên hiện dưới thẻ vai trò; thẻ viền đỏ.'],
      ['bad-email', 'Email sai', '"Email không hợp lệ".'],
      ['submitting', 'Đang gửi', '"Đang gửi..." mờ, không vòng xoay (khác các màn khác).'],
      ['toast-failed', 'Lỗi gửi', 'Toast đỏ "Đã có lời mời đang chờ xử lý."'],
      ['loading', 'Đang tải vai trò', 'VLoading giữa màn.'],
      ['roles-failed', 'Không tải được vai trò', 'Tiêu đề + câu lỗi + "Thử lại".'],
    ],
  },
  {
    id: 'invitation-detail', group: 'admin', code: 'ID-16', title: 'Chi tiết lời mời', route: '/more/users/invitations/i1', states: [
      ['pending', 'Đang chờ', 'Email + hạn đầu màn; thẻ "Thông tin lời mời" (vai trò ban đầu, trạng thái, giao nhận). "Thao tác ⌃" ở thanh dưới.'],
      ['delivery-failed', 'Gửi email lỗi', 'Nhãn đỏ "Lỗi gửi", "Giao nhận: Chưa gửi được email".'],
      ['expired', 'Hết hạn', 'Nhãn "Hết hạn"; không có thanh thao tác.'],
      ['loading', 'Đang tải', 'VLoading.'],
      ['error', 'Lỗi tải', '"Không tải được lời mời".'],
      ['actions', 'Sheet Thao tác', 'Có tiêu đề "Thao tác lời mời"; ô "Gửi lại" và ô đỏ "Thu hồi".'],
      ['revoke', 'Sheet Thu hồi', 'Tiêu đề đỏ; ô lý do dính sát câu mô tả (không khe); "Thu hồi lời mời" viền đỏ dưới "Quay lại".'],
      ['revoke-empty', 'Thu hồi khi trống lý do', 'Lỗi "Vui lòng nhập lý do thu hồi." (nhãn không có * dù bắt buộc).'],
      ['revoke-submitting', 'Đang thu hồi', 'Ô lý do và "Quay lại" mờ, nút đỏ vòng xoay.'],
      ['toast-created', 'Vừa gửi lời mời', 'Sau ID-15: toast hiện ở trang chi tiết (title, message rỗng).'],
      ['toast-created-warning', 'Tạo xong nhưng email lỗi', 'Toast vàng "Email chưa gửi được…".'],
      ['toast-resent', 'Đã gửi lại', 'Toast "Đã gửi lại lời mời."'],
      ['toast-resend-failed', 'Gửi lại lỗi email', 'Toast vàng.'],
      ['toast-state-changed', 'Dữ liệu đã thay đổi', 'Toast vàng.'],
    ],
  },
  {
    id: 'member-detail', group: 'admin', code: 'ID-17', title: 'Chi tiết thành viên', route: '/more/users/members/m2', states: [
      ['active', 'Hoạt động', 'Ô tròn + tên + email đầu màn; hai thẻ; "Danh tính: Chỉ đọc" cho mọi thành viên không phải chủ (dễ hiểu nhầm là quyền). Thao tác ⌃.'],
      ['suspended', 'Tạm ngừng', 'Banner vàng giữa hai thẻ; "Tạm ngừng lúc".'],
      ['removed', 'Đã loại', 'Đầu màn + thẻ đầu mờ 60%; banner info; không thanh thao tác.'],
      ['owner', 'Chủ sở hữu duy nhất', '"Quyền sở hữu: Chủ sở hữu"; không có thanh thao tác.'],
      ['loading', 'Đang tải', 'VLoading.'],
      ['error', 'Lỗi tải', '"Không tải được thành viên".'],
      ['actions', 'Sheet Thao tác (hoạt động)', 'Đổi vai trò, Tạm ngừng, Loại (đỏ).'],
      ['actions-suspended', 'Sheet Thao tác (tạm ngừng)', 'Đổi vai trò, Kích hoạt lại, Loại.'],
      ['deactivate', 'Xác nhận tạm ngừng', 'Tiêu đề đỏ; nút "Tạm ngừng" viền đỏ (không nền).'],
      ['reactivate', 'Xác nhận kích hoạt lại', 'Tiêu đề đen; nút xanh.'],
      ['remove', 'Xác nhận loại', 'Tiêu đề đỏ, nút viền đỏ.'],
      ['remove-submitting', 'Đang loại', 'Vòng xoay trong nút đỏ, "Quay lại" mờ.'],
      ['toast-deactivated', 'Đã tạm ngừng', 'Toast ở trang chi tiết, trên thanh thao tác.'],
      ['toast-role-changed', 'Đã đổi vai trò', 'Toast thành công.'],
      ['toast-last-owner', 'Chủ sở hữu cuối cùng', 'Toast vàng "Không thể thực hiện vì đây là chủ sở hữu cuối cùng."'],
    ],
  },
  {
    id: 'select-role', group: 'admin', code: 'ID-18', title: 'Chọn vai trò', route: '/more/users/members/m2', states: [
      ['default', 'Mặc định', 'Ô tròn + tên + nhãn đầu màn; danh sách một khối, vai trò hiện tại dòng đầu nền xám có nhãn "Hiện tại"; chưa chọn → "Tiếp tục" mờ. Không có màn "Xem trước thay đổi" — chọn xong lưu ngay.'],
      ['selected', 'Đã chọn Thủ kho', 'Dòng chọn nền xanh nhạt; radio bật.'],
      ['suspended', 'Thành viên tạm ngừng', 'Nhãn đỏ "Tạm ngừng" cạnh tên; ô tròn xám.'],
    ],
  },
  {
    id: 'roles', group: 'admin', code: 'ID-19', title: 'Vai trò', route: '/more/roles', states: [
      ['list', 'Danh mục', '4 thẻ: tên + nhãn "Đang dùng" + mô tả + mũi tên; chân thẻ là người đang giữ hoặc "Chưa có thành viên đang giữ vai trò này.". Bỏ ghi chú kỹ thuật trong ngoặc.'],
      ['loading', 'Đang tải', 'Không có vòng xoay: "0 vai trò hệ thống" + danh sách trống.'],
      ['failed', 'Lỗi tải', 'Thẻ giữa màn, tiêu đề đỏ, link "Thử lại" (xanh).'],
      ['detail', 'Chi tiết vai trò', 'Ô khiên + tên vai trò + mô tả đầu màn; thẻ "Thành viên đang giữ vai trò" (ô tròn + tên).'],
      ['detail-empty', 'Chi tiết · chưa ai giữ', '"Chưa có thành viên đang giữ vai trò này."'],
    ],
  },
  {
    id: 'audit', group: 'admin', code: 'ID-20', title: 'Lịch sử quản trị', route: '/more/audit-logs', states: [
      ['list', 'Danh sách', 'Ô tìm + chip nền trắng cố định; danh sách gộp theo ngày (giờ | tiêu đề, người, "<loại đối tượng>: <tên>"). "Tải thêm" cuối danh sách.'],
      ['chip-member', 'Chip Thành viên', 'Không có chip "Lời mời" dù có sự kiện lời mời.'],
      ['loading', 'Đang tải', 'VLoading dưới phần đầu.'],
      ['empty', 'Chưa có hoạt động', 'Thẻ trống lệch lên trên (Align −0.75).'],
      ['no-results', 'Không có kết quả', '"Không có hoạt động phù hợp" + "Xóa bộ lọc".'],
      ['error', 'Lỗi tải', 'Tiêu đề đỏ, link "Thử lại".'],
      ['forbidden', 'Không có quyền', 'Khiên vàng.'],
      ['filter', 'Bộ lọc (sheet)', 'Tiêu đề "Bộ lọc nhật ký nền tảng" (sót chữ "nền tảng"); nhóm "Loại chủ thể" chọn được nhưng không được áp dụng.'],
      ['filter-applied', 'Lọc 7 ngày', 'Chấm xanh trên nút bộ lọc, "24 hoạt động trong 7 ngày".'],
    ],
  },
  {
    id: 'audit-detail', group: 'admin', code: 'ID-20', title: 'Chi tiết hoạt động', route: '/more/audit-logs/a1', states: [
      ['detail', 'Chi tiết', 'Ô biểu tượng + tên hoạt động đầu màn, nhãn kết quả; một thẻ bốn phần (Dữ liệu thay đổi · Ngữ cảnh · Đối tượng · Thông tin truy vết). "Loại chủ thể: Chủ cửa hàng" là vai trò.'],
      ['actor-unavailable', 'Không còn người thực hiện', 'Nhãn "Không còn dữ liệu" + hộp vàng trên thẻ.'],
      ['loading', 'Đang tải', 'VLoading.'],
      ['not-found', 'Không tìm thấy', '"Không tìm thấy hoạt động" + "Thử lại".'],
      ['toast-copied', 'Đã sao chép mã', 'Toast hiện cả mã theo dõi đầy đủ.'],
    ],
  },
  // ================================================================ đợt 3 — tài khoản (ID-23 đã vẽ ở đợt 1: reset / from-account)
  {
    id: 'account', group: 'account', code: 'ID-21', title: 'Tài khoản của tôi', route: '/more/my-account', states: [
      ['owner', 'Chủ sở hữu', 'Ô tròn chữ viết tắt + tên + nhãn; thẻ 5 dòng; "Thao tác tài khoản" ba dòng ngay trong màn (không còn nút / sheet Thao tác).'],
      ['staff', 'Thành viên thường', 'Không có nhãn; không có dòng vai trò / tổ chức nào trên màn.'],
      ['no-phone', 'Chưa có số điện thoại', '"(chưa có)" màu nhạt.'],
      ['loading', 'Đang tải', 'VLoading giữa màn.'],
      ['error', 'Lỗi tải', '"Không tải được hồ sơ" + "Thử lại".'],
      ['logout', 'Xác nhận đăng xuất', 'Tiêu đề đỏ; hai nút large 52 chia đôi (các sheet khác dùng nút 44 xếp dọc).'],
      ['toast-updated', 'Đã cập nhật', 'Toast "Đã cập nhật thông tin cá nhân" ở đáy màn.'],
      ['toast-logout-failed', 'Đăng xuất thất bại', 'Toast đỏ "Không thể đóng phiên trên máy."'],
    ],
  },
  {
    id: 'account-edit', group: 'account', code: 'ID-22', title: 'Chỉnh sửa thông tin', route: '/more/my-account', states: [
      ['default', 'Mặc định', 'Thẻ "Ảnh đại diện" (bấm chưa làm gì) + thẻ form: họ + tên cùng hàng, số điện thoại, email khoá một dòng; "Lưu thay đổi" mờ tới khi có thay đổi.'],
      ['changed', 'Đã sửa', '"Lưu thay đổi" bật.'],
      ['errors', 'Lỗi', 'Hai ô tên viền đỏ; số điện thoại sai chỉ có dòng lỗi, viền ô không đỏ.'],
      ['submitting', 'Đang lưu', '"Đang lưu..." mờ, không vòng xoay; các ô vẫn sửa được.'],
      ['discard', 'Rời khi đã sửa', 'Hộp thoại "Bỏ thay đổi?".'],
      ['toast-failed', 'Lỗi lưu', 'Toast đỏ "Không lưu được" (chỉ câu message).'],
      ['loading', 'Đang tải', 'VLoading.'],
      ['error', 'Lỗi tải', '"Không tải được hồ sơ" + "Thử lại".'],
    ],
  },
];

export const CASES = Object.fromEntries(SCREENS.map((s) => [s.id, s.states.map(([id]) => id)]));

/** Ca chỉ có trên iPhone: web đã bỏ thanh / sheet "Thao tác" (nút nằm ngay trong khối). */
export const IPHONE_ONLY = {
  'org-profile': ['actions', 'actions-legal'], 'invitation-detail': ['actions'], 'member-detail': ['actions', 'actions-suspended'],
};
/** Các khổ vẽ được của một ca. */
export const devicesFor = (screen, state) => (IPHONE_ONLY[screen]?.includes(state) ? ['iphone'] : ['iphone', 'web']);

/** Bản web thiết kế lại (impeccable live 2026-11-24/25). '*' = chung cả màn; có mã ca thì ghi thêm cho ca đó. */
export const WEB_NOTES = {
  login: { '*': 'Khối thương hiệu trái 42%, form 400 bên phải canh giữa dọc; "Quên mật khẩu?" cùng dòng nhãn Mật khẩu.' },
  signup: { '*': 'Thanh tiến độ 3 đoạn + thẻ trắng cột 520; "Đã có tài khoản? Đăng nhập" dưới thẻ (bước 1).' },
  verify: { '*': 'Thẻ cột 520 giữa màn, ô mã trải đều; "Xác minh" trước "Gửi lại mã", đếm ngược là chữ thường; "Đăng xuất" dưới thẻ.' },
  reset: { '*': 'Thanh 2 bước + thẻ cột 520; "Gửi lại mã" dạng link, đếm ngược là chữ thường; bước 2 giữ thanh dưới.' },
  'no-org': { '*': 'Thẻ ngang cột 560 giữa màn: biểu tượng | nội dung + hai nút cùng hàng.' },
  invitation: { '*': 'Nhập mã: một thẻ cột 520, "Tiếp tục" trong thẻ. Đăng ký: banner + thẻ + thanh dưới cột 520.' },
  'org-profile': { '*': 'Đầu trang (tên + email · điện thoại); thao tác ở từng khối (bút chì / "Thêm hồ sơ pháp lý"); không banner, không thanh dưới.' },
  'org-edit': { '*': 'Thẻ trắng, lưới 2 cột.', discard: 'Hộp xác nhận rộng tối đa 440.' },
  'org-legal': { '*': 'Cùng bố cục lưới 2 cột với Chỉnh thông tin tổ chức; ô mã số thuế không có dòng mô tả.', discard: 'Hộp xác nhận rộng tối đa 440.' },
  users: { '*': 'Bảng toàn màn, nút "Mời thành viên", tab trái – tìm / lọc phải; chi tiết mở toàn màn có ←.', loading: 'Skeleton 4 dòng.', 'invitations-loading': 'Skeleton 4 dòng.' },
  invite: { '*': 'Vai trò chọn bằng 4 thẻ có mô tả, 2 cột.' },
  'invitation-detail': { '*': 'Toàn màn có ←; khối "Thông tin lời mời" với "Gửi lại lời mời" / "Thu hồi lời mời" ngay trong khối.' },
  'member-detail': { '*': 'Toàn màn có ←; nút thao tác nằm cuối khối "Trạng thái truy cập".' },
  'select-role': { '*': 'Toàn màn có ←.' },
  roles: { '*': 'Bảng toàn màn; mô tả bỏ ghi chú kỹ thuật trong ngoặc; chi tiết toàn màn có ←.', loading: 'Skeleton 4 dòng.' },
  audit: { '*': 'Bảng toàn màn (Hoạt động | Người thực hiện | Đối tượng | Thời điểm).', loading: 'Skeleton 5 dòng.' },
  'audit-detail': { '*': 'Cột 720, một thẻ 4 phần: Thay đổi, Ngữ cảnh, Đối tượng, Thông tin truy vết.' },
  account: { '*': 'Hai cột: thẻ hồ sơ + "Đăng xuất" | "Thông tin cá nhân" (bút chì) + "Bảo mật"; không thanh dưới.' },
  'account-edit': { '*': 'Một thẻ cột 560, dòng "Ảnh đại diện" ở đầu thẻ.', discard: 'Hộp xác nhận rộng tối đa 440.' },
};
export const webNote = (screen, state) => [WEB_NOTES[screen]?.['*'], WEB_NOTES[screen]?.[state]].filter(Boolean).join(' ');
