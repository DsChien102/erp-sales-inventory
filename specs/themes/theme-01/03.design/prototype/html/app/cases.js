// Danh sách ca dùng chung: main.js, viewer.js, tools/capture.mjs.
// Mỗi màn thuộc một nhóm (đợt): public (đợt 1), admin (đợt 2), account (đợt 3).
// Mỗi state: [mã, nhãn ngắn, điều cần nhìn]. Mỗi ca vẽ ở cả hai khổ (iPhone 390, Web 1280).
export const GROUPS = [
  { id: 'public', title: 'Công khai (đợt 1)' },
  { id: 'admin', title: 'Quản trị (đợt 2)' },
  { id: 'account', title: 'Tài khoản (đợt 3)' },
];

export const SCREENS = [
  {
    id: 'login', group: 'public', code: 'ID-01', title: 'Đăng nhập', route: '/login', states: [
      ['default', 'Mặc định', 'Logo V45 80 × 80, tên, khẩu hiệu, hai ô, "Quên mật khẩu?", hai nút, "Kích hoạt tài khoản". Dòng bản quyền bị Spacer đẩy xuống đáy. Web: cột 480 canh trên, nền trắng hết cửa sổ.'],
      ['empty-submit', 'Bấm Đăng nhập khi trống', 'Lỗi dưới từng ô (VFieldError), viền đỏ. Không có banner.'],
      ['wrong-credentials', 'Sai email / mật khẩu', '"Email hoặc mật khẩu không chính xác." hiện dưới ô Email (không phải ô Mật khẩu), không toast.'],
      ['network', 'Lỗi mạng (ID-x1)', 'Banner đỏ "Đăng nhập thất bại" ngay dưới ô Mật khẩu, trên "Quên mật khẩu?".'],
      ['submitting', 'Đang đăng nhập', 'Nút chính có vòng xoay và mờ (onPressed null → vDisabledOpacity); ba nút còn lại cũng mờ.'],
      ['forgot-no-email', 'Quên mật khẩu khi chưa nhập email', 'Bấm "Quên mật khẩu?" khi ô Email trống → lỗi dưới ô Email.'],
      ['joined', 'Đã tham gia tổ chức (ID-x2)', 'Sau kích hoạt lời mời: banner xanh "Tham gia tổ chức thành công", email điền sẵn.'],
      ['reset-success', 'Banner đổi mật khẩu', 'Từ Tài khoản của tôi → đổi mật khẩu xong → đăng xuất về đây: banner xanh.'],
      ['reset-toast', 'Toast đặt lại mật khẩu', 'Quay về từ Quên mật khẩu: toast (chỉ hiện câu message, không hiện title). Web: toast kéo hết bề ngang.'],
    ],
  },
  {
    id: 'signup', group: 'public', code: 'ID-02', title: 'Đăng ký cửa hàng', route: '/signup', states: [
      ['account', 'Bước 1 · Tài khoản', 'VSteps 3 bước; 6 ô; mô tả quy tắc mật khẩu dưới ô Mật khẩu; "Tiếp tục" + link "Đã có tài khoản? Đăng nhập".'],
      ['account-errors', 'Bước 1 · Lỗi', 'Bấm Tiếp tục: lỗi dưới từng ô; lỗi thay chỗ dòng mô tả mật khẩu. Số điện thoại không bắt buộc (không có *).'],
      ['store', 'Bước 2 · Cửa hàng', 'Email liên hệ tự điền email tài khoản; ô Xã / phường tắt khi chưa chọn tỉnh; hai nút chia đôi.'],
      ['store-errors', 'Bước 2 · Lỗi', 'Lỗi dưới tên, SĐT, tỉnh, xã, địa chỉ. Ô tỉnh / xã viền đỏ.'],
      ['store-filled', 'Bước 2 · Đã điền', 'Ô tỉnh / xã có giá trị: thêm nút xoá ×.'],
      ['picker-province', 'Chọn tỉnh (sheet)', 'Sheet "Khu vực hành chính" cao 75% màn. Web: hộp thoại 480 có hai nút Đóng (của hộp thoại + của sheet).'],
      ['picker-ward', 'Chọn xã (sheet)', 'Tab 2 sau khi chọn tỉnh; tab 1 hiện tên tỉnh + dấu ✓.'],
      ['store-submitting', 'Đang tạo cửa hàng', '"Đang tạo..." + vòng xoay; "Quay lại" mờ.'],
      ['server-error', 'Lỗi máy chủ', 'Banner đỏ chỉ có tiêu đề (câu lỗi làm tiêu đề, không có mô tả) giữa thanh bước và form.'],
      ['email-exists', 'Email đã đăng ký', 'Thay cả form bằng một dòng lỗi đỏ + "Đăng nhập" + "Quên mật khẩu". Thanh bước vẫn ở bước 2.'],
      ['verify', 'Bước 3 · Xác minh email', 'VerifyEmailView: ô 6 số, "Gửi lại mã sau 00:59" (mờ), "Xác minh". Không có tiêu đề riêng (tiêu đề chỉ ở thanh bước).'],
      ['verify-error', 'Bước 3 · Sai mã', 'Chỉ ô đang focus viền đỏ + vòng đỏ nhạt; các ô khác giữ viền xám, chữ số không đỏ; dòng lỗi đỏ bên dưới.'],
    ],
  },
  {
    id: 'verify', group: 'public', code: 'ID-03', title: 'Xác minh email', route: '/verify-email', states: [
      ['default', 'Vào từ Đăng nhập (ID-x4)', 'Tiêu đề H3; "Gửi lại mã" bấm được ngay (allowImmediateResend), không đếm ngược; "Đăng xuất" dạng link cuối.'],
      ['countdown', 'Sau khi gửi lại', 'Đếm ngược "Gửi lại mã sau 00:59", nút mờ.'],
      ['filled', 'Đủ 6 số (thoáng qua)', 'Thoáng qua: đủ mã là onCompleted tự gửi xác minh ngay → chuyển sang "Đang xác minh". Nút "Xác minh" gần như không cần bấm.'],
      ['submitting', 'Đang xác minh', 'Ô mã mờ; nút "Xác minh" có vòng xoay.'],
      ['error', 'Sai mã', 'Dòng lỗi đỏ; chỉ ô đang focus viền đỏ + vòng đỏ nhạt, các ô khác viền xám, chữ số không đỏ.'],
      ['resend-failed', 'Gửi lại mã lỗi', 'resend() lỗi → câu lỗi mạng hiện đúng chỗ lỗi mã (dưới sáu ô), "Gửi lại mã" bấm lại được.'],
    ],
  },
  {
    id: 'reset', group: 'public', code: 'ID-04 · ID-23', title: 'Đặt lại mật khẩu', route: '/login/reset-password', states: [
      ['requesting', 'Đang gửi mã', 'Vào màn là gửi mã ngay: chỉ có app bar + vòng tải 40 giữa màn, nền xám.'],
      ['request-failed', 'Gửi mã lỗi', 'Thân giữa màn "Không gửi được mã" + câu lỗi + "Thử lại", đồng thời toast đỏ cùng câu (lặp hai lần).'],
      ['verify', 'Bước 1 · Nhập mã', 'Thẻ "Xác minh email" dính sát nhãn "Mã xác nhận" (không khe). Gửi lại là nút secondary đầy ngang (đăng ký dùng link).'],
      ['verify-filled', 'Bước 1 · Đủ 6 số (thoáng qua)', 'Thoáng qua: đủ mã là onCompleted gọi xác nhận ngay → lớp phủ "Đang xác nhận". "Xác nhận mã" chỉ bật trong khoảnh khắc này.'],
      ['verifying', 'Đang xác nhận mã', 'Lớp phủ trắng 50% + vòng tải 40 phủ cả màn.'],
      ['verify-wrong', 'Sai mã', 'Không có lỗi dưới ô (errorText không được truyền): chỉ toast đỏ "Mã xác minh không đúng hoặc đã hết hạn.".'],
      ['resend-ready', 'Hết đếm ngược', '"Gửi lại mã" bật.'],
      ['resent-toast', 'Đã gửi lại mã', 'Toast xanh dương "Đã gửi lại mã xác nhận."; đếm lại "00:60" (nhãn luôn 00:ss).'],
      ['create', 'Bước 2 · Mật khẩu mới', 'Tiêu đề H3, hai ô gợi ý "••••", thẻ "Quy tắc mật khẩu"; thanh dưới "Quay lại" | "Đặt lại mật khẩu" (mờ khi chưa nhập đủ).'],
      ['create-filled', 'Bước 2 · Đã nhập', 'Nút "Đặt lại mật khẩu" bật.'],
      ['create-errors', 'Bước 2 · Lỗi', 'Lỗi dưới hai ô + toast đỏ "Vui lòng kiểm tra lại…".'],
      ['create-submitting', 'Đang đặt lại', 'Lớp phủ trắng 50% + vòng tải.'],
      ['from-account', 'Từ Tài khoản của tôi (ID-23)', '/more/my-account/reset-password: cùng màn, mã gửi tới email đang đăng nhập; mở ngoài khung (web không có thanh bên).'],
    ],
  },
  {
    id: 'no-org', group: 'public', code: 'ID-05', title: 'Chưa thuộc tổ chức', route: '/no-organization', states: [
      ['default', 'Mặc định', 'Tiêu đề + mô tả canh giữa, hai nút đầy ngang; cả khối canh giữa dọc màn. Không icon.'],
    ],
  },
  {
    id: 'invitation', group: 'public', code: 'ID-06 · ID-07', title: 'Lời mời', route: '/invitation', states: [
      ['entry', 'Nhập mã', 'VPageScaffold nền xám: banner info, ô mã 8 ký tự, mô tả "Mã không phân biệt…"; "Tiếp tục" ở thanh dưới. iPhone: ô co còn ~38 px.'],
      ['entry-partial', 'Đang nhập', '4/8 ký tự; ô thứ 5 có viền xanh + vòng. Đủ 8 ký tự là tự gửi kiểm mã (không cần bấm Tiếp tục).'],
      ['entry-empty', 'Bấm Tiếp tục khi trống', '"Vui lòng nhập mã lời mời".'],
      ['entry-format', 'Mã chưa đủ 8 ký tự', '"Mã lời mời phải gồm 8 ký tự chữ hoặc số".'],
      ['entry-invalid', 'Mã không hợp lệ', 'Lỗi từ máy chủ hiện dưới ô.'],
      ['entry-expired', 'Mã hết hạn', '"Mã lời mời đã hết hạn. Liên hệ người gửi để nhận mã mới."'],
      ['entry-network', 'Lỗi mạng khi kiểm mã', '"Không thể xác thực mã. Kiểm tra kết nối và thử lại."'],
      ['inspecting', 'Đang kiểm mã', '"Tiếp tục" có vòng xoay; ô mã và nút ← mờ.'],
      ['confirm', 'Sheet xác nhận', 'Hiện cho cả tài khoản đã có và chưa có. Web: hộp thoại 480, nội dung có hai lớp đệm (hộp thoại 16 + nội dung 16).'],
      ['accepting', 'Đang tiếp nhận (tài khoản đã có)', 'Sau "Xác nhận": quay về màn nhập mã với nút đang xoay, rồi sang /login (banner).'],
      ['register', 'Đăng ký tài khoản mới', 'Banner xanh "Mã lời mời hợp lệ", 6 ô (Email khoá, mờ), "Kích hoạt tài khoản" ở thanh dưới.'],
      ['register-errors', 'Đăng ký · Lỗi', 'Lỗi dưới từng ô; nhãn "Xác nhận mật khẩu" (đăng ký cửa hàng ghi "Nhập lại mật khẩu").'],
      ['register-filled', 'Đăng ký · Đã điền', 'Đủ thông tin.'],
      ['register-submitting', 'Đăng ký · Đang gửi', 'Mọi ô mờ, nút có vòng xoay.'],
      ['register-failed', 'Đăng ký · Lỗi máy chủ', 'Toast đỏ (chỉ câu message); hai ô mật khẩu bị xoá trắng.'],
      ['declined', 'Đã từ chối', 'Màn kết quả nền trắng, không app bar, không nút quay lại: tiêu đề, câu, "Nhập mã khác".'],
      ['blocked', 'Không thể tiếp tục', 'Lỗi khi tiếp nhận (ví dụ bị thu hồi giữa chừng): câu lỗi từ máy chủ.'],
    ],
  },
];

export const CASES = Object.fromEntries(SCREENS.map((s) => [s.id, s.states.map(([id]) => id)]));
