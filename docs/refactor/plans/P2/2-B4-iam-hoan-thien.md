# 2-B4 — Hoàn thiện IAM sau rà soát

> Phase: P2 · Bước (b) sửa · Trạng thái: Plan ✅ | Làm ✅ | Review ✅
> Nguồn: rà soát chức năng TH-01 ngày 2026-10-10, bạn duyệt từng mục (3, 4, 5, 8, 9). Mục 1, 2 bỏ qua (TH-01 đã sửa mục 2); mục 6, 7 Claude đã sửa tài liệu.
> Đặc tả: [TH-01](../../../02-yeu-cau/TH-01-to-chuc-va-nguoi-dung.md) US-01.3, US-03.1, US-04.2, US-08.3; [LUONG-DANG-KY-XAC-MINH-EMAIL](../../../02-yeu-cau/LUONG-DANG-KY-XAC-MINH-EMAIL.md) A3, A4.

## 1. Phạm vi

| # | Việc | TH-01 | Ước lượng |
|---|---|---|---|
| 1 | Bị loại / tạm ngừng khỏi tổ chức khi đang dùng → tải lại phiên | US-04.2 FR-03 | 1 giờ |
| 2 | Đổi mật khẩu khi đang đăng nhập → đăng xuất, `/login` có banner | US-08.3 FR-02 | 30 phút |
| 3 | Câu lỗi lời mời của tổ chức đang tạm ngừng | US-03.1 FR-03 | 10 phút |
| 4 | Đăng ký lại cùng email khi lần đầu chưa xác minh (A3) | US-01.3, US-01.5 | 1 giờ |
| 5 | Gửi lại mã trước 60 giây → đếm ngược thay vì "gửi quá nhiều yêu cầu" (A4) | BR-05, BR-66 | 1 giờ |

Không đổi DB.

## 2. Các bước

### Bước 1 — Mất quyền khi đang dùng (US-04.2 FR-03)

**Hiện trạng.** Thành viên bị loại / tạm ngừng: `iam.has_permission` trả `false` (không ném mã riêng) → mỗi RPC báo lỗi không có quyền (`PERMISSION_DENIED`). `TenantAccessRevokedSignal` (gọi từ cả `SupabaseRpc` mới và `SupabaseSchemaRpcClient` cũ) chỉ phát `TENANT_SUSPENDED`, `TENANT_CLOSED`, `PLATFORM_USER_SUSPENDED` → app không tải lại phiên.

**Khó:** nhân viên thường bấm vào chức năng chỉ dành cho Owner cũng nhận đúng lỗi này. Không được bootstrap mỗi lần thấy "không có quyền".

1. `packages/vet45_shared/application/lib/src/access/tenant_access_revoked_signal.dart`: thêm `static const permissionDenied = 'PERMISSION_DENIED';`; `notifyFromError` phát mã này khi chuỗi lỗi chứa `PERMISSION_DENIED` (đặt **sau** 3 nhánh hiện có để mã cụ thể thắng). Gói này bị xoá ở P9 — ghi `TODO(P9): chuyển vào core/session`.
2. `SessionController._onTenantAccessRevoked`: nhánh `permissionDenied` → `_recheckMembership()`:
   - Bỏ qua nếu `state.status != ready`, `tenantId == null`, hoặc lần kiểm trước chưa quá **30 giây** (giữ `DateTime? _lastRecheckAt`, cho phép tiêm `clock` để test).
   - `final ctx = await _repository.getTenantContext(tenantId)`; lỗi → bỏ qua (không làm gì).
   - `ctx.status == valid` → không làm gì (đây là lỗi quyền bình thường, vd nhân viên chạm chức năng của Owner).
   - Khác `valid` → `bootstrap()` (còn tổ chức khác → vào tổ chức đó; hết → `/no-organization` qua guard G5).
3. Test (`session_controller_test.dart`): (a) `PERMISSION_DENIED` + context vẫn `valid` → không bootstrap; (b) context `invalidated` (`membershipRemoved`) → bootstrap, tổ chức khác được chọn / `hasNoOrganization`; (c) 2 tín hiệu trong 30 giây → chỉ 1 lần gọi `getTenantContext`. Test cho `notifyFromError`: chuỗi `PERMISSION_DENIED` → phát mã mới; chuỗi `TENANT_SUSPENDED` vẫn phát mã cũ.

### Bước 2 — Đổi mật khẩu khi đang đăng nhập (US-08.3 FR-02)

1. `my_account_page.dart` (2 chỗ đang hiện toast "Đã đặt lại mật khẩu."): thay bằng `await session.signOut();` rồi `context.go('/login', extra: {'passwordResetSuccess': true})`.
2. `app_router.dart` route `/login`: đọc `extra['passwordResetSuccess']` → `LoginPage(passwordResetSuccess: …)`.
3. `LoginPage`: khi `passwordResetSuccess` → `VBanner` success "Cập nhật mật khẩu thành công — Mật khẩu đã được đặt lại. Vui lòng đăng nhập lại." (cùng chỗ với banner "Tham gia tổ chức thành công"; TH-01 US-02.1 FR-05, A-04).
4. Luồng "Quên mật khẩu" từ `/login` giữ như cũ (toast).
5. Test: widget `my_account_page` hoặc cubit — sau khi đặt lại thành công gọi `signOut` và điều hướng `/login` với extra; `LoginPage` có banner khi cờ bật.

### Bước 3 — Lời mời của tổ chức đang tạm ngừng (US-03.1 FR-03)

`InvitationAcceptanceCubit` (chỗ xử lý `IamBlockedCodes.tenantSuspended`, ~dòng 461): dùng thông điệp riêng "Tổ chức đang tạm ngừng, chưa thể tham gia." cho luồng lời mời. **Không** đổi câu chung của `tenantSuspended` trong `IamUiFailureMapper` (nơi khác dùng). Sửa test chuỗi tương ứng.

### Bước 4 — Đăng ký lại cùng email khi chưa xác minh (A3)

**Vấn đề** (ví dụ ở LUONG-DANG-KY-XAC-MINH-EMAIL 2.4): lần đăng ký thứ hai Supabase không cập nhật metadata (tên cửa hàng lần đầu) và có thể giữ mật khẩu lần đầu.

1. `AuthRepository.updatePassword(String password)` — `auth.updateUser(UserAttributes(password: …))`; nếu đã có hàm tương tự (luồng đặt lại mật khẩu 2-A1) thì dùng lại.
2. `SignupCubit` thêm `completeAfterVerification()` gọi khi bước 3 xác minh xong (thay cho việc trang tự hiện toast từ dữ liệu form):
   1. `await _auth.updatePassword(state.account.password)`; lỗi → **không chặn** (đã đăng nhập), ghi `passwordSyncFailed = true`.
   2. `await _session.bootstrap()`; lấy `tenantName = _session.state.current?.tenantName`.
   3. Emit `completed(tenantName, nameDiffers: tenantName != null && tenantName.trim() != state.store.name.trim())`.
3. `SignupPage`: khi `completed` → `context.go('/')` + toast "Chào mừng đến VET45! Cửa hàng `<tenantName từ DB>` đã sẵn sàng."; nếu `nameDiffers` → thêm toast info "Cửa hàng được tạo theo thông tin lần đăng ký trước. Bạn có thể sửa trong Hồ sơ tổ chức."
4. Guard G2 đưa `/signup` → `/` ngay khi `signedIn`: để không mất bước này, `SignupCubit.completeAfterVerification` chạy **trước** khi `applySignedInUser` làm guard chạy lại — cách gọn: `VerifyEmailView` nhận cờ `deferSignedIn` (dùng ở `/signup`), cubit gọi `applySignedInUser` ở cuối `completeAfterVerification`. Nếu cách này phức tạp, chấp nhận điều hướng sớm và làm bước 2.1–2.2 trong `DashboardPage` qua một cờ `pendingSignupCompletion` trong `SessionController` — ghi lựa chọn vào Review.
5. Test `signup_cubit_test`: gọi `updatePassword` với mật khẩu vừa nhập; tên DB khác → `nameDiffers`; `updatePassword` lỗi → vẫn `completed`.
6. **Kiểm trên Dev** (đợt kiểm IAM): đăng ký → thoát ở bước 3 → đăng ký lại cùng email với tên và mật khẩu khác → nhập mã → tổ chức tên gì, đăng nhập lại bằng mật khẩu mới được không.

### Bước 5 — Gửi lại trước 60 giây (A4)

**Hiện trạng:** `AppException._fromAuth` gom mọi 429 / `over_email_send_rate_limit` thành `RATE_LIMITED` → "Bạn đã gửi quá nhiều yêu cầu…".

1. `AppException._fromAuth`: lỗi 429 mà `message` khớp `after (\d+) seconds?` (Supabase: "For security purposes, you can only request this after N seconds") → mã mới `RESEND_COOLDOWN`, `details: {'seconds': N}`. Còn lại giữ `RATE_LIMITED`. Thêm `AppErrorCode.resendCooldown`.
2. `VerifyEmailCubit.resend`: bắt `RESEND_COOLDOWN` → không hiện lỗi; đặt `resendAvailableAt = now + seconds` (nút hiện "Gửi lại mã sau 00:ss").
3. `SignupCubit.createStore`: `RESEND_COOLDOWN` khi `signUp` (gặp ở A3: đăng ký lại trong vòng 60 giây) → chuyển sang bước 3 với đếm ngược `seconds` (mã lần trước vẫn dùng được).
4. `IamUiFailureMapper`: `RESEND_COOLDOWN` → "Vui lòng đợi `<N>` giây rồi gửi lại." (dự phòng nơi khác gặp).
5. Test: `app_exception_test` (chuỗi Supabase thật → `RESEND_COOLDOWN` + seconds; 429 không có số giây → `RATE_LIMITED`); `verify_email_cubit_test`; `signup_cubit_test`.

### Bước 6 — Commit

Gợi ý: (1) mất quyền; (2) đổi mật khẩu + câu lời mời; (3) đăng ký lại + đếm ngược.

## 3. Kiểm tra

- [x] `dart analyze` các file đã sửa: không issue mới. `check_feature_imports`: 0 vi phạm.
- [x] `flutter test` toàn `apps/erp`: 1.417 đạt / 61 lỗi (mốc 2-B3 là 1.404 / 61; 13 test mới đều đạt). Test tín hiệu `vet45_shared`: 3 đạt.
- [ ] Kiểm tay: gom vào đợt kiểm IAM (thêm kịch bản Bước 1: Owner loại nhân viên đang mở app → nhân viên thao tác bất kỳ → về `/no-organization` trong vài giây; Bước 4.6).

## 4. Rủi ro / lưu ý

- Bước 1: chuỗi `PERMISSION_DENIED` có thể đến từ lỗi Postgres (`42501`) chứ không chỉ RPC — vẫn an toàn vì chỉ dẫn tới một lần `get_tenant_context` có giới hạn 30 giây.
- Bước 4: `updateUser(password)` có thể bị Supabase từ chối nếu mật khẩu trùng mật khẩu hiện tại ("New password should be different") → coi như thành công.
- Bước 5: dựa vào câu chữ tiếng Anh của Supabase; nếu Supabase đổi câu, rơi về `RATE_LIMITED` (vẫn hiển thị được).

## 5. Review

- Lựa chọn Bước 4: `VerifyEmailView.deferSignedIn` và `SessionController.holdSignedInApply()`. `start()` nghe `onAuthStateChange`, nên OTP thành công gắn `signedIn` trước khi kịp `updatePassword`; guard G2 khi đó đưa `/signup` về `/`. Hold giữ trạng thái đến `applySignedInUser` ở cuối `completeAfterVerification`. OTP lỗi thì `releaseSignedInHold()`.
- Ngày, commit được review:
- Kết quả:
- Góp ý:

### Review của Claude

- Ngày, commit được review: 2026-10-11, working tree trên `2dca20e02` (chưa commit).
- Kết quả: **Đạt.**
  - Bước 1: `TenantAccessRevokedSignal` phát `PERMISSION_DENIED` sau 3 mã cụ thể (test 3/3 ở `vet45_shared`); `_recheckMembership` chỉ chạy khi `ready`, có tổ chức, cách lần trước ≥ 30 giây; context còn `valid` thì bỏ qua, lỗi mạng bỏ qua.
  - Bước 2: đổi mật khẩu xong → `signOut` → `/login` với `passwordResetSuccess` → banner "Cập nhật mật khẩu thành công"; router truyền `SessionController` cho `MyAccountPage`.
  - Bước 3: câu "Tổ chức đang tạm ngừng, chưa thể tham gia." chỉ ở luồng lời mời.
  - Bước 4: chọn hoãn `signedIn` (`holdSignedInApply` / `deferSignedIn`); `completeAfterVerification` ghi lại mật khẩu (trùng mật khẩu cũ coi như thành công), bootstrap, toast lấy tên tổ chức từ DB, báo khi tên khác.
  - Bước 5: `RESEND_COOLDOWN` (+ số giây) tách khỏi `RATE_LIMITED`; xác minh và `/signup` chuyển thành đếm ngược.
  - `dart analyze lib test`: không error; warning duy nhất có từ trước. `check_feature_imports`: 0 vi phạm.
  - `flutter test` toàn `apps/erp`: **1.417 pass / 61 fail**, danh sách fail trùng khớp 2-B3.
- Góp ý:
  1. **Nên sửa (nhỏ):** `completeAfterVerification` gọi `bootstrap()` **trước** `applySignedInUser`. Trong `_apply`, `state.userId` vẫn null (đang giữ) nên gọi `_iamSession.applyAuthenticatedUser(userId)` → **xoá `tenantId` / `activeStoreId`** vừa bootstrap, trong khi state vẫn `ready` + `current`. Hiện tự lành vì trang chủ bootstrap lại khi mở, nhưng bootstrap 2 lần và có khoảng ngắn `requireTenantId()` ném lỗi. Sửa 1 dòng trong `_apply`: chỉ gọi `applyAuthenticatedUser` khi `_iamSession?.userId != trimmed`; thêm test "bootstrap khi đang giữ rồi applySignedInUser → tenantId còn nguyên".
  2. Trường hợp hiếm: trang `/signup` bị đóng sau khi mã đúng nhưng trước cuối `completeAfterVerification` (`isClosed` → return) → cờ giữ không được tắt, phiên Supabase có mà app vẫn `signedOut` tới khi đăng nhập lại / mở lại app. Có thể gọi `_session.applySignedInUser(userId)` ở các nhánh `if (isClosed) return;` của `completeAfterVerification`.
  3. Bước 1 chỉ phủ RPC đi qua `SupabaseRpc` / `SupabaseSchemaRpcClient` (cả hai gọi `notifyFromError`) — đủ cho app hiện tại.
- Kiểm tay: gom vào đợt kiểm IAM (kịch bản bị loại khi đang dùng; đăng ký lại cùng email; đếm ngược).
- **Đã sửa góp ý 1, 2** (Claude, theo yêu cầu, 2026-10-11): `_apply` chỉ gọi `applyAuthenticatedUser` khi `IamSession.userId` khác user mới; `completeAfterVerification` gắn phiên ở cả 3 lối thoát khi cubit đã đóng. Thêm 2 test (`session_controller_test`: giữ phiên → bootstrap → gắn phiên vẫn còn tenant / cửa hàng; `signup_cubit_test`: trang đã đóng vẫn tắt cờ giữ). `flutter test`: 1.419 pass / 61 fail, không lỗi mới.
