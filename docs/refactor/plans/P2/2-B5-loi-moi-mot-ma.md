# 2-B5 — Nhận lời mời bằng một mã (bỏ mã 6 số cho nhân viên mới)

> Phase: P2 · Bước (b) sửa · Trạng thái: Plan ✅ | Làm ✅ (chưa commit) | Review 🔄 (code đạt 2026-10-12; chờ deploy + kiểm tay)
> Quyết định 2026-10-12: nhân viên **chưa có tài khoản** chỉ nhập **mã lời mời 8 ký tự**. Mã đó được gửi tới đúng email được mời nên đã chứng minh chủ email; không bắt nhập thêm mã xác minh 6 số.
> Làm **trước** kiểm tay kịch bản 3 của đợt kiểm IAM (TH-01 9.3).
> Tài liệu liên quan: [LUONG-DANG-KY-XAC-MINH-EMAIL](../../../02-yeu-cau/LUONG-DANG-KY-XAC-MINH-EMAIL.md) mục 1, 3; TH-01 EP-03 (ID-06, ID-07); [2-B1](2-B1-dang-ky-cua-hang.md), [2-B2](2-B2-email-edge-function.md) (mẫu Edge Function).

## 1. Mục tiêu

| | Trước | Sau |
|---|---|---|
| Nhân viên **đã có** tài khoản | Mã 8 ký tự → đăng nhập → nhận lời mời | Giữ nguyên |
| Nhân viên **chưa có** tài khoản | Mã 8 ký tự → tạo tài khoản → **mã 6 số** → nhận lời mời | Mã 8 ký tự → tạo tài khoản → **xong** |

Không đổi: đăng ký cửa hàng (`/signup`) vẫn cần mã 6 số; công tắc Confirm email vẫn bật.

## 2. Hiện trạng (đo 2026-10-12)

| Thứ | Ở đâu | Ghi chú |
|---|---|---|
| Kiểm mã lời mời | `iam.inspect_invitation_token(text)` (`20260826003`), cấp cho `anon` | Trả `invitee_email`, `account_exists`, tên tổ chức, vai trò |
| Nhận lời mời | `iam.accept_invitation(text, text)` (`20260916006`), cấp cho `anon` | `auth.uid()` null → tự tìm user theo `invitee_email`. Tạo hồ sơ nếu chưa có (giữ tên đã có), tạo / kích hoạt lại membership, audit, idempotency |
| Trigger khi user đã xác minh | `_on_auth_user_confirmed` (`20261009002`), `after insert … when email_confirmed_at is not null` | Không có `signup_tenant` → chỉ tạo hồ sơ từ `first_name`, `last_name`, `phone` |
| App: tạo tài khoản | `AuthRepository.signUpFromInvitation` (`auth.signUp`) | Confirm email bật → không có session → `needsVerification` |
| App: luồng | `InvitationAcceptanceCubit.registerNewAccount` (≈ dòng 185–265) → `awaitingVerification` → `VerifyEmailView` → `completeVerifiedRegistration` → `_finishRegistration` (`updateMyAccount`, `accept`, `signOut`) → `accepted` | |
| Màn | `invitation_token_page.dart:256` (`case awaitingVerification` dùng `VerifyEmailView`), `:192` (`_isEntryStep`) | |
| Edge Function mẫu | `supabase/functions/send-email` (Deno, `npm:@supabase/supabase-js@2`, `SUPABASE_URL` / `SUPABASE_SERVICE_ROLE_KEY` có sẵn) | |

Vì sao app không tự làm được: `auth.signUp` khi Confirm email bật luôn tạo user **chưa xác minh** và gửi mã 6 số; chỉ quyền admin (`service_role`) tạo được user đã xác minh. Khoá admin không được xuống app → cần Edge Function.

## 3. Thay đổi

| File | Hành động | Nội dung |
|---|---|---|
| `supabase/functions/invitation-signup/index.ts` | Tạo | Edge Function (mục 4.1) |
| `supabase/functions/invitation-signup/logic.ts` + `logic_test.ts` | Tạo | Hàm thuần kiểm đầu vào / ánh xạ lỗi, test Deno |
| `supabase/config.toml` | Sửa | `[functions.invitation-signup]` (mục 4.2) |
| `apps/erp/lib/features/auth/data/invitation_acceptance_repository.dart` | Sửa | Thêm `registerAndAccept(...)` gọi function; nhận thêm `FunctionsClient` |
| `apps/erp/lib/core/di/injection.dart` | Sửa | Truyền `supabaseModule.client.functions` cho repository trên |
| `apps/erp/lib/features/auth/logic/invitation_acceptance_cubit.dart` (+ state) | Sửa | `registerNewAccount` gọi `registerAndAccept`; bỏ bước `awaitingVerification` |
| `apps/erp/lib/features/auth/presentation/pages/invitation_token_page.dart` | Sửa | Bỏ `case awaitingVerification` / `VerifyEmailView` |
| `apps/erp/lib/features/auth/data/auth_repository.dart` | Sửa | Xoá `signUpFromInvitation` (+ `_mapInvitationAuthException` nếu không còn ai dùng — `signUpStore` đang dùng thì giữ) |
| Test app | Sửa | `invitation_acceptance_cubit_test.dart`, `invitation_token_page_test.dart`, `invitation_registration_phone_test.dart`, fake / scripted repository liên quan |
| Tài liệu | Claude sửa sau khi xong | TH-01 (EP-03, ID-07, mục 6.2), LUONG-DANG-KY-XAC-MINH-EMAIL (mục 1 dòng "Nhân viên", mục 3, bảng gửi lại ở mục 4), CHECKLIST ID-07, RUNBOOK-email (deploy thêm function) |

**Không cần migration.** Nếu muốn khoá `accept_invitation` khỏi `anon` sau này thì làm riêng (ngoài phạm vi).

## 4. Các bước

### 4.1 Edge Function `invitation-signup`

Request (POST, JSON):

```json
{ "token": "K7P29XQM", "password": "…", "given_name": "Minh", "family_name": "Tran", "phone": "0900000000", "idempotency_key": "register-from-invitation-…" }
```

Xử lý (client `service_role`, `auth: { persistSession: false, autoRefreshToken: false }`):

1. Kiểm đầu vào (hàm thuần trong `logic.ts`): `token` 8 ký tự sau khi `trim().toUpperCase()`; `given_name`, `family_name` không rỗng; `password` theo cùng luật `PasswordPolicy` của app (`core/validation/password_policy.dart`: ≥ 8 ký tự, có 1 số, 1 ký tự đặc biệt); `idempotency_key` không rỗng. Sai → `400 { "code": "VALIDATION_ERROR" }`.
2. `rpc('inspect_invitation_token', { p_token })` trên schema `iam` → lỗi DB (`INVITATION_TOKEN_INVALID`, `INVITATION_EXPIRED`, `INVITATION_REVOKED`, `INVITATION_ALREADY_USED`…) → `400 { "code": <mã> }` (lấy mã từ `error.message`, cùng cách app đang đọc).
3. `account_exists = true` → `409 { "code": "ACCOUNT_EXISTS" }` (không tạo gì).
4. `auth.admin.createUser({ email: invitee_email, password, email_confirm: true, user_metadata: { first_name, last_name, phone } })`.
   - Lỗi trùng email (`email_exists` / status 422) → `409 ACCOUNT_EXISTS`.
   - Lỗi mật khẩu yếu (`weak_password`) → `400 WEAK_PASSWORD`.
   - Trigger `_on_auth_user_confirmed` tự tạo hồ sơ (insert đã có `email_confirmed_at`).
5. `rpc('accept_invitation', { p_token, p_idempotency_key })` (không có `auth.uid()` → hàm tìm user theo email lời mời).
   - Lỗi → **xoá user vừa tạo** (`auth.admin.deleteUser(id)`) để người dùng thử lại được từ đầu, rồi trả mã lỗi như bước 2.
6. Thành công → `200 { "membership": <kết quả accept_invitation> }`.

Ghi log một dòng JSON mỗi lần (`result`, mã lỗi) — **không** log mật khẩu, mã lời mời, email đầy đủ.

### 4.2 Cấu hình

```toml
[functions.invitation-signup]
verify_jwt = false
```

Function công khai như `accept_invitation` hiện tại (người gọi chưa đăng nhập). Bảo vệ: mã lời mời băm trong DB, chỉ dùng được một lần, hết hạn 7 ngày; email lấy từ lời mời, người gọi không chọn được.

Deploy: `supabase functions deploy invitation-signup --project-ref pzlsjedtsntkarkivhve` (không cần secret mới — `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` Supabase cấp sẵn).

### 4.3 Repository (app)

```dart
/// Tạo tài khoản đã xác minh + nhận lời mời trong một lần (Edge Function `invitation-signup`).
Future<TenantMemberDetail> registerAndAccept({
  required String token,
  required String password,
  required String givenName,
  required String familyName,
  String? phone,
  required String idempotencyKey,
});
```

- Gọi `_functions.invoke('invitation-signup', body: {...})`.
- Lỗi (`FunctionException`): đọc `details['code']` → `throw AppException(code)`. `ACCOUNT_EXISTS` → `AppException('PLATFORM_USER_ALREADY_EXISTS')` để cubit dùng lại nhánh có sẵn. Lỗi mạng → `AppException.from(error)`.
- Thành công → `TenantMemberDetail.fromJson(response.data['membership'])`.

### 4.4 Cubit + màn

`registerNewAccount` sau khi kiểm đầu vào (giữ kiểm `PasswordPolicy`, tên không rỗng, `inspect` + `accountExists`):

```text
membership = await _invitations.registerAndAccept(token, password, given, family, phone, key)
emit(accepted, registrationResult: InvitationRegistrationResult(userId: membership.userId, membership), acceptedMembership: membership)
```

- Không đăng nhập, không `signOut` (chưa có phiên) — kết quả giống hiện tại: màn kết quả → `/login` + "Tham gia tổ chức thành công…". Người dùng đăng nhập bằng mật khẩu vừa đặt.
- `PLATFORM_USER_ALREADY_EXISTS` → giữ nhánh có sẵn: chuyển `existingAccountLogin` (mục "Email đã có tài khoản" đã bàn).
- Xoá: `InvitationAcceptanceStep.awaitingVerification`, `completeVerifiedRegistration`, `_pendingUserId`, `_pendingGivenName/_FamilyName/_Phone`, `state.verificationEmail` (nếu chỉ dùng ở đây), nhánh `needsVerification`. `_finishRegistration` chỉ còn dùng nếu nhánh khác gọi — không thì xoá.
- `invitation_token_page.dart`: bỏ `case awaitingVerification` ở `_isEntryStep` và ở `switch` dựng màn; bỏ import `VerifyEmailView` nếu thừa.
- `userId` lấy từ `membership.userId` (`TenantMemberDetail` có sẵn trường này).

### 4.5 Test

- Deno (`logic_test.ts`): kiểm đầu vào (token sai độ dài, tên rỗng, mật khẩu ngắn), ánh xạ lỗi Auth (`email_exists` → `ACCOUNT_EXISTS`, `weak_password` → `WEAK_PASSWORD`), lấy mã lỗi DB từ message.
- Cubit: (1) đăng ký mới thành công → `accepted`, **không** qua `awaitingVerification`; (2) `ACCOUNT_EXISTS` → `existingAccountLogin`; (3) `INVITATION_EXPIRED` → thông điệp hết hạn, ở lại màn đăng ký; (4) lỗi mạng → ở lại màn, bấm lại dùng cùng idempotency key.
- Page: bước đăng ký không còn hiện ô nhập 6 số.

## 5. Kiểm tra

- [x] `deno test supabase/functions/invitation-signup/` xanh (7 test); `deno check supabase/functions/invitation-signup/index.ts` sạch.
- [x] `apps/erp`: `dart analyze lib test` không error / warning mới; `flutter test` 1.405 pass / 59 fail (baseline 1.399 / 59; 59 fail nằm ở catalog, pricing, my_account, tenant_admin — không có auth / invitation).
- [x] `git grep -n "signUpFromInvitation\|awaitingVerification\|completeVerifiedRegistration" apps/erp` rỗng.
- [ ] Deploy lên Dev, kiểm tay (TH-01 9.3 kịch bản 3): Owner mời `…+nv1@gmail.com` → mail lời mời → "Kích hoạt tài khoản" → nhập mã 8 ký tự → đặt mật khẩu, họ tên → **không có bước mã 6 số** → màn thành công → đăng nhập bằng mật khẩu vừa đặt → vào đúng cửa hàng, đúng vai trò.
- [ ] Kiểm tay nhánh phụ: nhập lại mã đã dùng → "Lời mời đã được sử dụng…"; mời email đã có tài khoản → màn đăng nhập (1 mã).
- [ ] Supabase Dashboard ▸ Authentication ▸ Users: user mới có "Email confirmed"; Resend ▸ Emails **không** có mail "Mã xác minh" cho user đó.

## 6. Rủi ro / lưu ý

- **Nửa chừng:** tạo user xong mà nhận lời mời lỗi → function xoá user (bước 5). Nếu xoá cũng lỗi, user còn lại ở trạng thái đã xác minh, chưa thuộc tổ chức → người dùng đăng nhập được, vào `/no-organization` ▸ "Nhập mã lời mời" ▸ nhánh đã có tài khoản → vẫn nhận được. Không kẹt.
- **Khoá `service_role`** chỉ nằm trong Edge Function (biến môi trường Supabase cấp); không log, không trả về.
- **Dò mã lời mời:** function công khai nhưng chỉ làm được gì khi có mã đúng (8 ký tự, băm, một lần, 7 ngày) — mức bảo vệ như `accept_invitation` đang mở cho `anon`. Có thể thêm giới hạn tần suất sau nếu cần.
- **Tên hiển thị:** trigger tạo hồ sơ từ `first_name` / `last_name` người dùng nhập; `accept_invitation` chỉ điền tên từ lời mời khi hồ sơ còn trống → tên người dùng nhập được ưu tiên (giống hiện tại với `updateMyAccount`).
- Local (`supabase start`) cần `supabase functions serve invitation-signup --no-verify-jwt` khi chạy app với Supabase local.

## 7. Review

### Ghi chú khi làm (người làm, 2026-10-12)

Khác plan, theo thứ tự quan trọng:

1. **RPC gọi bằng khoá anon, không phải `service_role`.** `inspect_invitation_token` và `accept_invitation` chỉ `grant execute … to anon, authenticated` (migration `20260826003`, `20260916006`; có `revoke … from public`), `service_role` không có quyền → gọi bằng `service_role` sẽ `permission denied`. Function dùng `SUPABASE_ANON_KEY` cho hai RPC này, `SUPABASE_SERVICE_ROLE_KEY` chỉ cho `auth.admin.createUser` / `deleteUser` (đi qua GoTrue, không phụ thuộc grant). Vẫn **không cần migration**.
2. **CORS:** thêm xử lý `OPTIONS` và header `Access-Control-*` vì app có bản web (preflight khi `invoke` từ trình duyệt). `send-email` không cần vì chỉ gọi server-to-server.
3. **`ACCOUNT_EXISTS` chỉ dựa vào `error.code`** (`email_exists`, `user_already_exists`), không dùng status 422: `weak_password` cũng trả 422.
4. **Lời mời hết hạn giữa chừng → màn "blocked"** (cùng `_handleAcceptError` với `acceptExistingAccount`), không "ở lại màn đăng ký": thử lại với mã hết hạn không bao giờ thành công. Test cubit (3) kiểm theo hành vi này.
5. **Bỏ `AccountRepository` khỏi cubit, `InvitationTokenPage` và `app_router`** — chỉ `_finishRegistration` dùng, đã xoá. `_InvitationTokenView` cũng không còn cần `auth` / `session`.
6. Tên hàm cubit thực tế là `registerAndAccept` (plan ghi `registerNewAccount`); giữ nguyên để không đụng `invitation_registration_page.dart`.
7. Thêm ngoài plan: `test/features/auth/data/invitation_acceptance_repository_test.dart` (ánh xạ mã lỗi function → `AppException`, lỗi mạng). Xoá `ScriptedAccountRepository` trùng tên ở `auth/support/scripted_auth.dart` (không còn ai dùng).
8. Biết trước: nếu function chạy xong nhưng phản hồi không về app (mất mạng), bấm lại sẽ ra "Lời mời đã được sử dụng…" dù tài khoản đã tạo; người dùng đăng nhập bằng mật khẩu vừa đặt. Không xử lý thêm.

**Chưa làm (cần bạn):** `supabase functions deploy invitation-signup --project-ref pzlsjedtsntkarkivhve` và các mục kiểm tay còn ☐ ở mục 5. Chưa commit.

### Review

<!-- Claude ghi sau khi review -->

### Review của Claude (2026-10-12)

- Phạm vi: working tree (chưa commit) — `supabase/functions/invitation-signup/{index,logic,logic_test}.ts`, `config.toml`, `invitation_acceptance_repository.dart`, cubit / state / page, `auth_repository.dart`, DI, router, 4 file test + 1 test mới, tài liệu.
- Kết quả: **Code đạt** → Review 🔄 tới khi deploy và kiểm tay kịch bản 3.
  - **Lệch plan đều hợp lý.** Quan trọng nhất là (1): đã kiểm `accept_invitation` / `inspect_invitation_token` chỉ `grant … to anon, authenticated` — theo plan (gọi bằng `service_role`) sẽ lỗi quyền. Khoá `service_role` chỉ dùng cho `auth.admin.createUser` / `deleteUser`. Dùng khoá anon → `auth.uid()` null → `accept_invitation` tìm user theo email lời mời như thiết kế.
  - Function: email lấy từ lời mời; `account_exists` → 409 trước khi tạo; tạo user `email_confirm: true` + metadata `first_name` / `last_name` / `phone` (trigger `_on_auth_user_confirmed` đọc đúng các khoá này); nhận lời mời lỗi → `deleteUser` (hồ sơ xoá theo `on delete cascade`), log có `rolled_back` / `rolled_back_failed`; log không chứa mật khẩu, mã, email. `deno test`: 7/7; `deno check index.ts` sạch.
  - App: cubit không còn `AccountRepository`, đăng nhập tạm, `updateMyAccount`, `signOut`; `ACCOUNT_EXISTS` → `PLATFORM_USER_ALREADY_EXISTS` → nhánh `existingAccountLogin` có sẵn; `WEAK_PASSWORD` → `PASSWORD_POLICY_VIOLATION`; lỗi mạng giữ idempotency key. `git grep signUpFromInvitation|awaitingVerification|completeVerifiedRegistration` rỗng.
  - `dart analyze lib test`: không error (1 warning có sẵn ở test sales). `flutter test`: **1.405 pass / 59 fail** — +6 test mới so với 1.399; 59 ca fail đều trong TEST-BASELINE (catalog, pricing, `my_account` e2e_e06_u02, `tenant_admin` e2e_e02_u07). `test/features/auth`: 77/77.
  - Tài liệu: LUONG-DANG-KY-XAC-MINH-EMAIL (mục 1, 3, bảng gửi lại), TH-01 (US nhận lời mời FR-05, bảng RPC), CHECKLIST ID-07, RUNBOOK (deploy, test, serve local) đã cập nhật.
- Góp ý (không chặn):
  1. **Mất phản hồi sau khi đã nhận lời mời** (mạng rớt đúng lúc function trả về): bấm lại → `inspect_invitation_token` báo `INVITATION_ALREADY_USED` → người dùng thấy "Lời mời đã được sử dụng" dù đã là thành viên. Đăng nhập bình thường vẫn vào được cửa hàng, nên chỉ là câu chữ gây hoang mang. Có thể để thông điệp của mã này gợi ý "Nếu bạn vừa tạo tài khoản, hãy đăng nhập".
  2. `normalizeToken` chỉ `trim().toUpperCase()` rồi đòi đúng 8 ký tự, còn DB (`_invitation_token_hash`) bỏ mọi ký tự không phải chữ / số. Form của app đã chặn đúng 8 ký tự `[0-9A-Z]` nên chưa gây lỗi; nếu sau này cho dán mã kiểu `K7P2-9XQM` thì nên bỏ ký tự lạ trong `normalizeToken` cho khớp DB.
- Việc còn lại để đóng: `supabase functions deploy invitation-signup --project-ref pzlsjedtsntkarkivhve`; kiểm tay mục 5 (Owner mời → nhập mã 8 ký tự → đặt mật khẩu → không có mã 6 số → đăng nhập vào đúng cửa hàng; mã đã dùng; email đã có tài khoản).
