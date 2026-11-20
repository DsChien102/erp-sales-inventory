# 2-B1 — Đăng ký cửa hàng mới, xác minh email, định tuyến sau đăng nhập

> Phase: P2 · Bước (b) sửa / tính năng mới · Trạng thái: Plan ✅ | Làm ✅ | Review 🔄 (DB ✅ 2026-10-12; Confirm email + mẫu mã 6 số + rate limit 30 + SMTP Resend đã bật trên Dev — người dùng xác nhận 2026-10-28; chờ kiểm tay trên app)
> Gồm việc: 2A.1, 2A.2, 2A.3, 2B.1, 2B.2, 2B.3, 2B.4, 2B.7
> Đặc tả: [TH-01](../../../02-yeu-cau/TH-01-to-chuc-va-nguoi-dung.md) 2.2, 2.3, BR-01…BR-14, BR-62…BR-65; EP-01 (US-01.1…01.5), US-02.1, US-02.2, US-02.4, US-05.4; màn 5.2, 5.3, 5.4; kiểm thử 9.3 (kịch bản 1, 2)

## 1. Mục tiêu

Người mới tự mở cửa hàng mà không cần Platform Admin:

```text
/login ─"Đăng ký cửa hàng mới"─▶ /signup (1 Tài khoản → 2 Cửa hàng → 3 Xác minh email)
   auth.signUp(data: {profile, signup_tenant})        ← chưa có tổ chức
   auth.verifyOtp(type: signup)  ─▶ trigger iam._on_auth_user_confirmed (cùng transaction)
        → hồ sơ người dùng active
        → iam._create_tenant_for_owner: tổ chức active + Owner + cửa hàng mặc định + tổ chức chọn gần nhất + audit
   ─▶ đã đăng nhập ─▶ bootstrap ─▶ "/" + toast "Chào mừng đến Mosaic Retail! …"
```

Kèm theo:
- `/verify-email`: đăng nhập khi email chưa xác minh (đăng ký dở) → nhập mã.
- `/no-organization`: người không còn tổ chức nào.
- Bootstrap chọn **tổ chức hoạt động đầu tiên** khi tổ chức chọn gần nhất không còn hợp lệ.
- Banner "Bổ sung hồ sơ pháp lý" (chỉ Owner).
- Bật xác minh email bằng **OTP 6 số** trên Dev (2A.3), và sửa luồng **đăng ký từ lời mời** để chạy được khi đã bật xác minh.

**Ngoài phạm vi** (để 2-B2 / P3): `email_jobs` + Edge Function `send-email` (2A.4); sửa `accept_invitation` (KI-02), FK `memberships.user_id` (KI-03), xoá `provisioning` / `pending_activation` / `create_tenant_onboarding` / `owner_activation` / màn readiness (KI-05); các KI giao diện (KI-06, 10–14); khu `/admin` và "Chuyển không gian" (P3). Cấu hình Auth trên **Prod để P10**.

## 2. Hiện trạng liên quan

| Thứ | Ở đâu | Ghi chú |
|---|---|---|
| Tạo tổ chức + Owner + cửa hàng (luồng cũ) | `iam.create_tenant_onboarding` (bản mới nhất `20260911004`, `20260916004`) | Tổ chức `provisioning`, cần Platform Admin + lời mời Owner. **Chép** phần insert `iam.tenants`, `iam.memberships` (`store_owner`, `is_owner = true`), `iam._ensure_tenant_default_store(tenant_id)` |
| Kích hoạt (luồng cũ) | `iam.activate_tenant` (`20260916007`) | Chép cách gọi `iam.append_audit_log(...)` |
| Tổ chức chọn gần nhất | `iam.user_preferences.last_selected_tenant_id`, `iam.set_last_selected_tenant` (`20260811008`) | Trigger ghi thẳng bảng (không có `auth.uid()` trong trigger) |
| Hồ sơ người dùng | `iam.platform_user_profiles` (`user_id`, `status`, `email_verified`, `email`, `given_name`, `family_middle_name`, `phone_number`, …) | Hiện tạo ở `accept_invitation` / luồng Owner cũ |
| Trigger có sẵn trên `auth.users` | `trg_cleanup_pending_profile` (after insert, `20260826003`) | Giữ nguyên |
| Cặp cửa hàng – kho mặc định | App: `DefaultPairGateCubit` ở trang chủ tự đảm bảo | Trigger **không** cần tạo kho |
| Bộ chọn Tỉnh / Xã | `features/iam/presentation/organization_profile/{data/vn_administrative_units_loader.dart, widgets/administrative_units_form_section.dart, widgets/vn_administrative_unit_picker_sheet.dart}` | `features/partner` có bản chép riêng (để P4) |
| Guard | `core/router/route_guard.dart` (đã có chỗ chờ 2-B1), `session_refresh.dart` (chỉ nghe `authStatus`) | |
| Lỗi Auth | `AppException._fromAuth`: `email_not_confirmed` → `IDENTITY_EMAIL_NOT_VERIFIED` | |
| Auth config | `supabase/config.toml`: `enable_confirmations = false`, `max_frequency = "1s"`, `otp_length = 6`, `otp_expiry = 3600`; chưa có template email | |

## 3. Thay đổi

| File | Hành động | Nội dung |
|---|---|---|
| `supabase/migrations/20261009001_iam_create_tenant_for_owner.sql` | Tạo | `iam._create_tenant_for_owner(p_user_id uuid, p_payload jsonb) returns uuid` |
| `supabase/migrations/20261009002_iam_on_auth_user_confirmed.sql` | Tạo | `iam._on_auth_user_confirmed()` + 2 trigger trên `auth.users` |
| `supabase/migrations/REGISTRY.yaml` | Sửa | Thêm 2 migration |
| `supabase/tests/iam_signup_trigger.sql` | Tạo | Kịch bản SQL kiểm trigger (`begin … rollback`) |
| `supabase/config.toml`, `supabase/templates/confirmation.html` | Sửa / tạo | OTP 6 số, bật xác minh, `max_frequency = "1m0s"` |
| `lib/core/widgets/address/` | Chuyển từ `features/iam/presentation/organization_profile/` | loader + form section + picker sheet (re-export chỗ cũ) |
| `lib/features/auth/data/auth_repository.dart` | Sửa | `signUpStore`, `verifySignupOtp`, `resendSignupOtp`; `signUpFromInvitation` hết bắt buộc có session |
| `lib/features/auth/data/models/signup_input.dart` | Tạo | `SignupAccountInput`, `SignupStoreInput` + `toMetadata()` |
| `lib/features/auth/logic/signup_cubit.dart` (+ state) | Tạo | Wizard 3 bước |
| `lib/features/auth/logic/verify_email_cubit.dart` (+ state) | Tạo | Nhập mã / gửi lại (dùng cho `/signup` bước 3, `/verify-email`, đăng ký từ lời mời) |
| `lib/features/auth/presentation/pages/signup_page.dart`, `verify_email_page.dart`, `no_organization_page.dart` | Tạo | 3 màn mới |
| `lib/features/auth/presentation/widgets/otp_code_field.dart`, `resend_countdown.dart` | Tạo | Ô 6 số, "Gửi lại mã sau 00:ss" (60 giây) |
| `lib/features/auth/presentation/pages/login_page.dart`, `logic/login_cubit.dart` | Sửa | Nút "Đăng ký cửa hàng mới"; `IDENTITY_EMAIL_NOT_VERIFIED` → `/verify-email` |
| `lib/features/auth/logic/invitation_acceptance_cubit.dart` + page | Sửa | Đăng ký từ lời mời: thêm bước nhập mã khi `signUp` chưa có session |
| `lib/core/session/session_controller.dart`, `session_state.dart` | Sửa | Bootstrap fallback tổ chức đầu tiên; getter `hasNoOrganization` |
| `lib/core/router/route_guard.dart`, `session_refresh.dart`, `app_router.dart` | Sửa | Route mới + nhánh guard |
| `lib/features/dashboard/...`, `lib/features/iam/presentation/organization_profile/views/organization_profile_page.dart` | Sửa | Banner hồ sơ pháp lý |
| Test | Tạo / sửa | xem Bước 10 |

## 4. Các bước

### Bước 1 — `iam._create_tenant_for_owner` (2A.1)

Migration theo header ở `supabase/migrations/README.md` (`Kind: patch`, `Intent: iam_signup_create_tenant_for_owner`, `Context: TH-01 BR-06, BR-07`).

```sql
create or replace function iam._create_tenant_for_owner(p_user_id uuid, p_payload jsonb)
returns uuid
language plpgsql security definer set search_path = iam, pg_temp
```

1. Đọc và trim: `name`, `contact_phone`, `contact_email`, `province_code`, `commune_code`, `address_text`. Thiếu một trong `name`, `contact_phone`, `province_code`, `commune_code`, `address_text` → `raise exception 'VALIDATION_ERROR: signup_tenant'` (BR-10).
2. **BR-07**: đã có membership `is_owner = true` và `removed_at is null` của `p_user_id` → `return null` (không tạo, không lỗi — để xác minh lần hai không hỏng).
3. `insert into iam.tenants (display_name, contact_email, contact_phone, contact_address_text, province_code, commune_code, status, status_changed_at, updated_at)` với `display_name = name`, `status = 'active'` (cột `activated_at` nếu có: `now()`). Múi giờ / tiền tệ: để default của bảng (BR-11) — kiểm cột.
4. `insert into iam.memberships (tenant_id, user_id, role, is_owner, version, created_at, updated_at) values (…, 'store_owner', true, 1, now(), now())`.
5. `perform iam._ensure_tenant_default_store(v_tenant_id)`. Nếu migration `20260916005` / `006` còn bước gán phạm vi cửa hàng cho membership (store scope), gọi y như `accept_invitation` đang gọi.
6. `insert into iam.user_preferences (user_id, last_selected_tenant_id, updated_at) values (p_user_id, v_tenant_id, now()) on conflict (user_id) do update set last_selected_tenant_id = excluded.last_selected_tenant_id, updated_at = now()`.
7. `perform iam.append_audit_log(p_scope => 'tenant', p_tenant_id => v_tenant_id, p_actor_user_id => p_user_id, p_event_code => 'iam.tenant.created', p_subject_type => 'tenant', p_subject_id => v_tenant_id::text, p_result => 'success', p_source => 'iam', p_tracking_id => 'signup:' || p_user_id::text, p_after => jsonb_build_object('status', 'active', 'display_name', name))` (chữ ký ở `20260826004_iam_audit_logs_v2_rebuild.sql`; `p_tracking_id` bắt buộc). **Không** gọi `enqueue_outbox_message`.
8. `revoke all … from public, anon, authenticated` — chỉ trigger gọi (BR-01: không có RPC client tạo tổ chức).

### Bước 2 — Trigger `iam._on_auth_user_confirmed` (2A.2)

```sql
create or replace function iam._on_auth_user_confirmed() returns trigger
language plpgsql security definer set search_path = iam, pg_temp
```

1. Chỉ chạy khi `new.email_confirmed_at is not null` **và** (`tg_op = 'INSERT'` **hoặc** `old.email_confirmed_at is null`).
2. `meta := coalesce(new.raw_user_meta_data, '{}')`. Tên: ưu tiên `meta->'profile'->>'given_name' / 'family_name' / 'phone'`, nếu không có thì `meta->>'first_name' / 'last_name' / 'phone'` (luồng lời mời 2-A3 gửi kiểu này).
3. Hồ sơ: `insert into iam.platform_user_profiles (user_id, status, email_verified, email, given_name, family_middle_name, phone_number, updated_at) values (new.id, 'active', true, lower(new.email), …) on conflict (user_id) do update set status = case when platform_user_profiles.status = 'suspended' then 'suspended' else 'active' end, email_verified = true, email = excluded.email, given_name = coalesce(platform_user_profiles.given_name, excluded.given_name), …`. (Không mở khoá người đang bị tạm ngừng.)
4. Có `meta ? 'signup_tenant'` → `perform iam._create_tenant_for_owner(new.id, meta->'signup_tenant')`; rồi `update auth.users set raw_user_meta_data = raw_user_meta_data - 'signup_tenant' where id = new.id` (lần update này không chạy lại nhánh tạo vì `old.email_confirmed_at` đã có giá trị).
5. Lỗi trong hàm → để nổi lên (cả `verifyOtp` thất bại, không có tổ chức nửa vời — AC-03 US-01.3).
6. Trigger:
   ```sql
   create trigger trg_on_auth_user_confirmed_ins after insert on auth.users
     for each row when (new.email_confirmed_at is not null) execute function iam._on_auth_user_confirmed();
   create trigger trg_on_auth_user_confirmed_upd after update of email_confirmed_at on auth.users
     for each row when (old.email_confirmed_at is null and new.email_confirmed_at is not null)
     execute function iam._on_auth_user_confirmed();
   ```
7. Thứ tự với `trg_cleanup_pending_profile` (cũng after insert): tên trigger xếp theo alphabet (`trg_cleanup…` chạy trước) — đúng ý (dọn hồ sơ tạm rồi mới tạo hồ sơ thật).

### Bước 3 — Kịch bản SQL kiểm trigger

`supabase/tests/iam_signup_trigger.sql`, chạy trong `begin; … rollback;` (SQL editor của Dev hoặc `psql` local), dùng `raise exception` khi sai:

1. Insert `auth.users` (id ngẫu nhiên, email, `raw_user_meta_data` có `profile` + `signup_tenant`, `email_confirmed_at = null`) → **không** có tổ chức, không có hồ sơ.
2. `update auth.users set email_confirmed_at = now()` → đúng 1 tổ chức `active` tên đúng; 1 membership `store_owner` `is_owner`; 1 cửa hàng `default`; `user_preferences` trỏ tổ chức; 1 audit `iam.tenant.created`; hồ sơ `active`; metadata không còn `signup_tenant`.
3. Đặt lại `signup_tenant` vào metadata, `email_confirmed_at = null` rồi `= now()` lần nữa → vẫn 1 tổ chức (BR-07).
4. User khác có `signup_tenant` thiếu `address_text` → update xác minh **ném lỗi**; không có tổ chức.
5. Insert user đã xác minh sẵn, không có `signup_tenant` (giống người được mời) → chỉ có hồ sơ.
6. `select has_function_privilege('authenticated', 'iam._create_tenant_for_owner(uuid, jsonb)', 'execute')` → `false`.

### Bước 4 — Cấu hình Auth (2A.3, chỉ Dev)

1. `supabase/templates/confirmation.html`: tiêu đề "Mã xác minh Mosaic Retail", nội dung tiếng Việt có `{{ .Token }}` (không dùng `{{ .ConfirmationURL }}`), hạn 1 giờ.
2. `config.toml`:
   - `[auth.email] enable_confirmations = true`, `max_frequency = "1m0s"`, giữ `otp_length = 6`, `otp_expiry = 3600`.
   - `[auth.email.template.confirmation] subject = "Mã xác minh Mosaic Retail"`, `content_path = "./supabase/templates/confirmation.html"`.
3. Đẩy lên Dev: `supabase db push` (2 migration) rồi `supabase config push` — **báo Claude chạy** (cần xác nhận; `config push` áp ngay, nhớ giữ danh sách `api.schemas` hiện tại, chưa có `einvoice`). Sau đó mở Dashboard ▸ Auth ▸ Email Templates kiểm template đã lên.
4. **Email trên Dev**: dịch vụ email mặc định của Supabase chỉ gửi tới email thành viên của project và giới hạn rất thấp (vài email / giờ). Khi kiểm tay, đăng ký bằng email tài khoản Supabase của bạn; email khác phải chờ SMTP riêng (Resend, 2-B2).

### Bước 5 — Dời bộ chọn địa chỉ vào `core`

`git mv` 3 file (`vn_administrative_units_loader.dart`, `administrative_units_form_section.dart`, `vn_administrative_unit_picker_sheet.dart`) sang `lib/core/widgets/address/`; để file re-export ở chỗ cũ (`TODO(P9)`). Không gộp bản của `partner` ở plan này.

### Bước 6 — `AuthRepository` + model đăng ký

```dart
Future<void> signUpStore({required SignupAccountInput account, required SignupStoreInput store});
Future<void> verifySignupOtp({required String email, required String code}); // OtpType.signup
Future<void> resendSignupOtp(String email);                                   // auth.resend(type: OtpType.signup)
```

- `signUpStore`: `auth.signUp(email: lower(trim), password, data: {'profile': {given_name, family_name, phone?}, 'signup_tenant': {name, contact_phone, contact_email, province_code, commune_code, address_text}})`.
  - Supabase **không báo lỗi** khi email đã có tài khoản đã xác minh: trả `user` có `identities` rỗng. Coi là `PLATFORM_USER_ALREADY_EXISTS` (US-01.5). Lỗi `AuthException` dùng lại bảng map của `signUpFromInvitation`.
- `verifySignupOtp`: lỗi `otp_expired` / `invalid` → `AppException('OTP_INVALID')`; lỗi từ trigger (thường là `AuthException` 500 "Database error …") → `AppException('SIGNUP_TENANT_FAILED')`.
- `signUpFromInvitation` (2-A3): bỏ điều kiện "phải có session và `emailConfirmedAt`"; trả `({String userId, bool needsVerification})` với `needsVerification = response.session == null`.
- Thông điệp (thêm vào `IamUiFailureMapper` hoặc `app_error_messages.dart`): `OTP_INVALID` → "Mã xác minh không đúng hoặc đã hết hạn."; `SIGNUP_TENANT_FAILED` → "Không tạo được cửa hàng. Vui lòng kiểm tra thông tin và thử lại."; `PLATFORM_USER_ALREADY_EXISTS` → "Email đã được đăng ký".
- Thêm luôn góp ý review 2-A3 #1: `'RATE_LIMITED' => IamBlockedCodes.resetRateLimited` trong `IamUiFailureMapper` (gửi lại mã quá nhanh cũng ra mã này).

### Bước 7 — Màn `/signup`, `/verify-email`, `/no-organization`

Chuỗi UI lấy đúng TH-01 (US-01.1…01.4, US-02.4, màn 5.3, 5.4).

**`SignupCubit`** — state: `step (account | store | verify)`, dữ liệu 2 form, `submitting`, `failure`, `emailExists`.
- `continueToStore(account)`: kiểm theo US-01.1 FR-03 (`PasswordPolicy`, email, SĐT 9–11 số); không gọi server.
- `back()`: giữ dữ liệu bước 1 (AC-02).
- `createStore(store)`: kiểm US-01.2 (thiếu địa chỉ → "Vui lòng nhập địa chỉ cửa hàng", không gọi `signUp`); `contact_email` mặc định = email tài khoản; gọi `signUpStore` → `step = verify`. Email đã có → `emailExists = true` (hiện nút "Đăng nhập", "Quên mật khẩu").

**`VerifyEmailCubit(email)`** — `verify(code)`, `resend()` (đếm ngược 60 giây, nút khoá). `verify` thành công → `SessionController` nhận `signedIn` từ `onAuthStateChange` (Supabase trả session sau `verifyOtp`); gọi thêm `session.applySignedInUser(userId)` như 2-A3.

**Trang:**
- `SignupPage`: thanh 3 bước, bước 3 nhúng `VerifyEmailView` (cùng cubit với `/verify-email`). Thành công → `context.go('/')` + toast "Chào mừng đến Mosaic Retail! Cửa hàng `<tên>` đã sẵn sàng."
- `VerifyEmailPage` (`/verify-email`, nhận `email` qua `extra` hoặc query): "Xác minh email để tiếp tục", ô mã, "Xác minh", "Gửi lại mã", "Đăng xuất" (về `/login`). Email che dạng `l***@example.com` (dùng `maskEmail` của 2-A1).
- `NoOrganizationPage`: chữ US-02.4, "Nhập mã lời mời" → `/invitation`, "Đăng xuất". Không có nút tạo tổ chức.

**`/login`** (2B.1): thêm nút "Đăng ký cửa hàng mới" (→ `/signup`) giữa "Đăng nhập" và "Bạn đã nhận được lời mời?" theo 5.2. `LoginCubit`: lỗi `IDENTITY_EMAIL_NOT_VERIFIED` → state `needsVerification(email)`; page `context.go('/verify-email', extra: email)` (thay thông báo cũ). Phần "gộp `sign_in_platform_admin` và `sign_in_tenant_user`" đã xong ở 2-A3 (`AuthRepository.signIn` là đường duy nhất) — chỉ ghi chú.

### Bước 8 — Đăng ký từ lời mời khi đã bật xác minh

`InvitationAcceptanceCubit.registerAndAccept`: sau `signUpFromInvitation`:
- `needsVerification == false` (giữ được trên môi trường tắt xác minh) → như cũ.
- `needsVerification == true` → state `awaitingVerification(email)`; trang lời mời hiện `VerifyEmailView`; xác minh xong → `applySignedInUser` → `updateMyAccount` → `accept(token, key)` → `signOut` như cũ. Giữ token + idempotency key trong cubit suốt bước này.

### Bước 9 — Định tuyến sau đăng nhập, bootstrap, banner

1. **Bootstrap** (`_bootstrapFromLastSelected`): khi kết quả là `TenantContext.none` (không có tổ chức chọn gần nhất hoặc không còn hợp lệ), lấy `listAccessibleTenants()`; tổ chức `isSelectable` đầu tiên → `getTenantContext(id)` rồi đi tiếp như nhánh hợp lệ (bind, `setLastSelected`). Không có tổ chức chọn được nhưng danh sách khác rỗng → lấy tổ chức đầu tiên và để nhánh `invalidated` hiện ID-09. Danh sách rỗng → `none`.
2. `SessionState.hasNoOrganization` = `status == blocked && emptyStateType == noAuthorizedOrganizations`.
3. `session_refresh.dart`: nghe `(authStatus, hasNoOrganization)` (`distinct`), không nghe cả state.
4. `routeGuard`:
   - Public: thêm `/signup`, `/verify-email`.
   - `signedIn` ở `/login`, `/signup`, `/verify-email` → `/` (BR-62).
   - `signedIn` + `hasNoOrganization` → `/no-organization`, trừ khi đang ở `/no-organization` hoặc `/invitation…`.
   - `signedIn` + không `hasNoOrganization` mà đang ở `/no-organization` → `/`.
   - `signedOut` ở `/no-organization` → `/login`.
   - Màn "Tổ chức không thể truy cập" (ID-09) giữ như hiện tại ở trang chủ.
5. **Banner hồ sơ pháp lý** (2B.7, US-05.4): trang chủ (chỉ `session.isOwner`) và Hồ sơ tổ chức: tổ chức chưa có hồ sơ pháp lý → "Bổ sung hồ sơ pháp lý để xuất hoá đơn điện tử." + "Bổ sung" (→ form hồ sơ pháp lý). Đọc qua `OrganizationRepository` (field hồ sơ pháp lý đã có trong `TenantProfile` — kiểm). Đóng ở trang chủ → ẩn đến hết phiên (biến trong `SessionController` hoặc cubit trang chủ, reset khi đổi user / tổ chức).

### Bước 10 — Test

- `test/core/router/route_guard_test.dart`: bảng 2.3 (trừ dòng Platform Admin — P3): chưa đăng nhập ở `/signup`, `/verify-email` → ở lại; đã đăng nhập ở `/signup` → `/`; `hasNoOrganization` ở `/` → `/no-organization`; ở `/invitation` → ở lại; hết `hasNoOrganization` ở `/no-organization` → `/`.
- `test/core/session/session_controller_test.dart`: fallback tổ chức đầu tiên (chọn được / chỉ có tổ chức bị tạm ngừng / rỗng).
- `test/features/auth/logic/signup_cubit_test.dart`: mật khẩu 7 ký tự không qua bước 2; quay lại giữ dữ liệu; thiếu địa chỉ không gọi `signUpStore`; email đã có → `emailExists`.
- `test/features/auth/logic/verify_email_cubit_test.dart`: mã sai → "Mã xác minh không đúng hoặc đã hết hạn."; gửi lại khoá 60 giây.
- `test/features/auth/data/auth_repository_signup_test.dart`: metadata đúng khoá; `identities` rỗng → `PLATFORM_USER_ALREADY_EXISTS`.
- Widget: `signup_page_test.dart` (3 bước, chuỗi UI), `no_organization_page_test.dart` (không có nút tạo tổ chức), `login_page` có nút "Đăng ký cửa hàng mới".
- `invitation_acceptance_cubit_test.dart`: thêm nhánh `needsVerification`.

### Bước 11 — Commit

Gợi ý: (1) migration + test SQL + config; (2) bộ chọn địa chỉ sang core; (3) đăng ký + xác minh + lời mời; (4) guard + bootstrap + `/no-organization`; (5) banner.

## 5. Kiểm tra

- [ ] Kịch bản SQL Bước 3 chạy hết, không `raise`.
- [ ] `dart analyze lib test`: không error / warning mới. `check_feature_imports`: 0 vi phạm.
- [ ] `flutter test` toàn `apps/erp`: không lỗi mới so với 2-A3 (1.404 pass / 61 fail).
- [ ] Kiểm tay trên Dev (email của bạn — xem Bước 4.4):
  - [ ] **Kịch bản 1** (TH-01 9.3): `/login` ▸ "Đăng ký cửa hàng mới" → 3 bước → nhận mã → vào `/` với toast; tổ chức `active`, bạn là Owner "Chủ cửa hàng", có cửa hàng mặc định; banner hồ sơ pháp lý hiện → bổ sung → banner mất.
  - [ ] Trước khi nhập mã: Table Editor `iam.tenants` không có tổ chức mới (SC-02).
  - [ ] **Kịch bản 2**: đăng ký đến bước 3 rồi thoát → đăng nhập → `/verify-email` → nhập mã → vào `/` có cửa hàng.
  - [ ] Đăng ký lại cùng email → "Email đã được đăng ký" + "Đăng nhập" / "Quên mật khẩu".
  - [ ] Owner mời một email khác → người đó đăng ký từ lời mời → nhập mã → tham gia (cần email nhận được; nếu chưa có SMTP, ghi "chưa kiểm" và kiểm lại ở 2-B2).
  - [ ] Owner loại một thành viên → thành viên đăng nhập → `/no-organization`.
  - [ ] Gửi lại mã: nút khoá 60 giây.
- [ ] CHECKLIST: tick "Mới" ID-01, ID-02, ID-03, ID-05 và dòng banner (nếu có) sau khi kiểm tay.

## 6. Rủi ro / lưu ý

- **Trigger trên `auth.users` lỗi = không ai xác minh được email** (kể cả người được mời). Chạy kịch bản SQL trước khi `db push`; trong trigger chỉ `raise` khi có `signup_tenant` sai, phần hồ sơ không được ném lỗi vì dữ liệu tên thiếu.
- `security definer` + `search_path = iam, pg_temp`: mọi bảng ngoài `iam` (vd `auth.users`) phải viết đầy đủ schema.
- **Bật xác minh email ảnh hưởng luồng lời mời** (2-A3 đang yêu cầu có session ngay sau `signUp`). Bước 8 phải xong cùng lúc với `config push`, nếu không người được mời mới sẽ gặp "SYSTEM_ERROR".
- Supabase trả "thành công giả" khi đăng ký email đã tồn tại (chống dò email): dựa vào `user.identities` rỗng, không dựa vào lỗi.
- `max_frequency = "1m0s"` + giới hạn email mặc định: kiểm tay chậm, đừng bấm gửi lại liên tục.
- Plan lớn (≈ 2 ngày). Nếu muốn tách: Bước 1–4 (DB + config) làm và kiểm trước, rồi mới tới app.

## 7. Review

- Ngày, commit được review: 2026-10-09, working tree trên `b79c50ff8` (chưa commit).
- Kết quả: **App đạt; DB chưa kiểm được** → Review 🔄 đến khi chạy kịch bản SQL.
  - **DB (đọc code):** `_create_tenant_for_owner` và trigger đúng thiết kế (kiểm đủ trường, BR-07, tổ chức `active`, Owner `store_owner`, cửa hàng `default`, `user_preferences`, audit, `revoke` khỏi client). Bắt đúng lỗi plan bỏ sót: `iam.tenant.created` chưa có trong `_audit_event_category` → `append_audit_log` sẽ ném `AUDIT_EVENT_UNREGISTERED`; bản định nghĩa lại khác bản `20260826004` **đúng 1 dòng**, quyền giữ nguyên. Owner mới có cửa hàng hoạt động: `get_session_context` lấy cửa hàng `default` qua `can_access_store` (chỉ cần `memberships.is_active`, mặc định `true`), không cần store scope.
  - **DB (chạy thật):** chưa. `supabase migration list`: `20261009001`, `20261009002` **chưa có trên Dev**; Docker không chạy nên không có Supabase local. Kịch bản `supabase/tests/iam_signup_trigger.sql` đủ 6 trường hợp nhưng chưa được chạy.
  - **App:** `signUpStore` / `verifySignupOtp` / `resendSignupOtp` đúng; email đã tồn tại nhận qua `identities` rỗng; lỗi trigger (500 / "Database error") → `SIGNUP_TENANT_FAILED`. Guard, `session_refresh` (chỉ nghe `authStatus` + `hasNoOrganization`), bootstrap fallback, `/no-organization`, banner (chỉ Owner, đóng theo phiên, reset khi đổi tổ chức) đúng plan. Bước 8 lời mời: giữ token / key, xác minh xong mới `updateMyAccount` → `accept` → `signOut`. Góp ý 429 của 2-A3 đã sửa trong mapper.
  - `dart analyze lib test`: không error; warning duy nhất có từ trước. `check_feature_imports`: 0 vi phạm.
  - `flutter test` toàn `apps/erp`: **1.424 pass / 61 fail**, danh sách fail trùng khớp 2-A3, không lỗi mới.
  - `config.toml`: bật xác minh, `max_frequency = "1m0s"`, template OTP — **chưa push**.
- Việc còn lại để đóng review (theo thứ tự):
  1. Chạy kịch bản SQL trên Dev (cần migration có mặt; xem cách làm Claude đề xuất trong hội thoại).
  2. `supabase db push` 2 migration lên Dev.
  3. `supabase config push` (bật xác minh + template). Phải sau bước 2.
  4. Kiểm tay mục 5 (email của bạn; giới hạn 2 email/giờ khi chưa có SMTP riêng).
- Góp ý (không chặn):
  1. **`/verify-email` từ màn đăng nhập**: đăng nhập lỗi `email_not_confirmed` thì Supabase **không** gửi mã mới, nhưng `VerifyEmailCubit` khoá "Gửi lại mã" 60 giây ngay từ đầu → người dùng chờ vô ích, mã cũ có thể đã hết hạn. Khi vào từ đăng nhập, cho gửi lại ngay (`resendAvailableAt = now`).
  2. **Toast "Chào mừng…"**: `verifyOtp` xong là `signedIn` → guard đẩy `/signup` → `/` gần như cùng lúc với `VToast.show` của trang đăng ký. Nhiều khả năng vẫn hiện (toast nằm ở overlay), nhưng kiểm tay; nếu mất thì chuyển toast sang trang chủ (cờ trong `SessionState` hoặc `extra`).
  3. Bootstrap: tổ chức không chọn được mà cũng không tạm ngừng / đóng (vd `provisioning` của người không phải Owner) bị dựng thành ngữ cảnh "tạm ngừng". Hết khi 2-B2 bỏ `provisioning`.
  4. Khi thêm SMTP riêng: sửa `config.toml` (`email_sent`, `[auth.email.smtp]`) **trước** lần `config push` kế tiếp.

### Cập nhật 2026-10-12 — đợt kiểm IAM

- `db reset --linked` trên Dev (sau bản sửa `activated_at`) rồi chạy 4 kịch bản trong SQL Editor — `iam_signup_trigger`, `iam_email_jobs`, `iam_accept_invitation_reinvite`, `iam_legacy_cleanup`: **cả 4 không raise** (người dùng chạy, 2026-10-12).
- `iam_signup_trigger.sql` đạt sau 2 lần sửa: lỗi `42804` (trigger gán `text` vào cột enum `status`) hết khi 3-E bỏ cột; lỗi `42703 activated_at` (do 3-E xoá migration tạo cột) đã sửa ở 3-E.
- Email trên Dev: Resend `mail.dschienerp.me` verified; SMTP Auth đã cài trên Dashboard (sender "DSC ERP").
- **Còn lại để đóng:** bật Confirm email + mẫu "Confirm signup" (mã 6 số) + rate limit 30 (Dashboard hoặc `config push`); kiểm tay TH-01 9.3 kịch bản 1–2 trên app với email thật. Review giữ 🔄 tới lúc đó.
