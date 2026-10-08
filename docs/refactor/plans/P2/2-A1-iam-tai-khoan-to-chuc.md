# 2-A1 — Chuyển IAM: tài khoản của tôi, hồ sơ tổ chức, hồ sơ pháp lý, đặt lại mật khẩu

> Phase: P2 · Bước (a) chuyển kiến trúc · Trạng thái: Plan ✅ | Làm ✅ | Review ✅
> Gồm việc: 2B.6 (một phần: tài khoản của tôi, hồ sơ tổ chức, hồ sơ pháp lý, quên mật khẩu)
> Tài liệu liên quan: [PLAN.md](../../PLAN.md) P2 + "Cách chuyển MỘT feature"; [TH-01](../../../02-yeu-cau/TH-01-to-chuc-va-nguoi-dung.md) ID-04, ID-11, ID-12, ID-13, ID-21, ID-22, ID-23; mẫu: [1-A](../P1/1-A-app-exception-feature-mau.md)

## 1. Mục tiêu

4 cubit và 7 route của nhóm "tài khoản & tổ chức" chạy theo luồng `Page → Cubit (logic/) → Repository (data/) → RPC / Supabase Auth`, **không còn `IIamModule` / `IExecutionContext`**:

| Màn (TH-01) | Route | Cubit |
|---|---|---|
| ID-21 Tài khoản của tôi | `/more/my-account` | `MyAccountCubit` |
| ID-22 Sửa tài khoản | `/more/my-account/edit` | `MyAccountEditCubit` |
| ID-23 Đặt lại mật khẩu (đã đăng nhập) | `/more/my-account/reset-password` | `PasswordResetCubit` |
| ID-04 Quên mật khẩu | `/login/reset-password` | `PasswordResetCubit` (chế độ theo email) |
| ID-11 Hồ sơ tổ chức | `/more/organization-profile` | `OrganizationProfileCubit` |
| ID-12 Sửa thông tin tổ chức | `/more/organization-profile/edit` | `OrganizationProfileCubit` |
| ID-13 Hồ sơ pháp lý | `/more/organization-profile/legal` | `OrganizationProfileCubit` |

Thêm: luật MST và chính sách mật khẩu thành hàm thuần ở `core/validation/` (P4 dùng lại cho đối tác); `IamUiFailure` hiểu `AppException` để **giữ nguyên câu báo lỗi** trên các màn IAM.

**Không đổi hành vi**. Không làm các sửa của TH-01 (KI-05 bỏ "Kích hoạt tổ chức", KI-12 đếm 60 giây, KI-14…) — để **2-B2**.

## 2. Hiện trạng: Command/Query → RPC

| Cubit | Command / Query | Handler → adapter | Gọi gì |
|---|---|---|---|
| `MyAccountCubit` | `GetMyIdentityProfileQuery` | `IPlatformIdentitySelfServicePort.getMyAccount` → `SupabasePlatformIdentitySelfServiceAdapter` | RPC `get_my_platform_user_profile` + email / trạng thái xác minh lấy từ `auth.currentUser` |
| | `ListAccessibleTenantsQuery` | `IIamAccessGateway.listAccessibleTenants` | RPC `list_accessible_tenants` (đã có trong `SessionController`) |
| `MyAccountEditCubit` | `GetMyIdentityProfileQuery`, `UpdateMyIdentityProfileCommand` (+ validator) | `updateMyAccount` | RPC `update_my_platform_user_profile(p_avatar_reference, p_given_name, p_family_name, p_phone)` |
| `PasswordResetCubit` — đã đăng nhập | `RequestMyPasswordResetCommand`, `ResendMyPasswordResetCommand`, `VerifyMyPasswordResetCommand`, `CompleteMyPasswordResetCommand` (+ validator `PasswordPolicy`) | adapter self-service + `PasswordResetOperationStore` + `SupabaseAuthAccountClient` | RPC `begin_password_reset_operation`, `get_password_reset_operation`, (resend), (verify), (mark completed); `auth.updateUser(password)`; `auth.signOut(scope: others)` |
| `PasswordResetCubit` — quên mật khẩu | `RequestPasswordResetByEmailCommand`, `Resend…ByEmail`, `Verify…ByEmail`, `Complete…ByEmail` (+ validator) | `SupabasePasswordResetPublicAdapter` | RPC `begin_password_reset_operation_by_email(p_email)`, `resend_password_reset_operation_by_email(p_operation_id)`, `verify_password_reset_code_by_email(p_operation_id, p_code)`, `complete_password_reset_operation_by_email(p_operation_id, p_new_password)` |
| `OrganizationProfileCubit` | `GetTenantQuery` | `SupabaseTenantProfileReadGateway.getTenant` | RPC `get_tenant(p_tenant_id)`; không có dòng → `RESOURCE_NOT_FOUND` |
| | `UpdateTenantProfileCommand` | `…CommandGateway.updateProfile` | RPC `update_tenant_profile(p_tenant_id, p_display_name, p_contact_email, p_contact_phone, p_contact_address_text, p_province_code, p_commune_code, p_expected_version)` |
| | `UpsertLegalProfileCommand` | `…CommandGateway.upsertLegalProfile` | RPC `upsert_legal_profile(p_tenant_id, p_legal_entity_type, p_legal_name, p_tax_code, p_registered_address_text, p_province_code, p_commune_code, p_expected_version, p_allow_duplicate_tax_code)` |

Ghi chú quan trọng (phải giữ):

- `completePasswordReset` (đã đăng nhập): đọc lại operation, **status khác `verified` → `STATE_CHANGED`**; `auth.updateUser` lỗi `weak_password` / `password_too_weak` / chữ chứa "password … short/policy" → `PASSWORD_POLICY_VIOLATION`; sau đó `signOut(scope: others)`; rồi đánh dấu completed. Xem `supabase_platform_identity_self_service_adapter.dart` dòng 101–212.
- Email bị che khi trả về cho UI: `lan@gmail.com` → `l***@gmail.com` (`_maskEmail`).
- `MyAccountDto` ghép: `user_id`, `given_name`, `family_middle_name`, `phone_number`, `avatar_reference` từ RPC + `email`, `emailVerified` từ `auth.currentUser`.
- Schema: các RPC trên ở schema `iam` — xác nhận lại tên schema trong gateway (`SchemaRpcClient` được tạo với schema nào) khi viết repository.
- Validator: `UpdateMyIdentityProfileCommandValidator`, `Complete…PasswordReset…Validator` (dùng `PasswordPolicy`); `TaxCodeFormatRule` (domain) được **UI** gọi trực tiếp ở `organization_legal_profile_form_page.dart` và cubit.

Test liên quan: `test/features/iam/presentation_module/organization_profile/organization_profile_cubit_test.dart`, `…/widgets/{profile_phone_validation, organization_legal_profile_form_page, organization_edit_profile_page, reset_password_page}_test.dart`, `test/features/tenant_admin/e2e_e02_u01_u03_u07_test.dart`.

## 3. Thay đổi

| File | Hành động | Nội dung |
|---|---|---|
| `lib/core/validation/tax_code.dart` | Tạo | Hàm thuần từ `TaxCodeFormatRule` (10 / 12 / 10-3 số) |
| `lib/core/validation/password_policy.dart` | Tạo | Hàm thuần từ `PasswordPolicy` (domain IAM) |
| `lib/features/iam/data/models/*.dart` | Tạo | `MyAccount`, `TenantProfile` (từ DTO của `GetTenantQuery`), `UpsertLegalProfileResult`, `PasswordResetRequestResult`, `PasswordResetVerifyResult`, `PasswordResetCompletionResult` — giữ tên field DTO cũ |
| `lib/features/iam/data/account_repository.dart` | Tạo | `getMyAccount()`, `updateMyAccount(...)` |
| `lib/features/iam/data/organization_repository.dart` | Tạo | `getTenant()`, `updateProfile(...)`, `upsertLegalProfile(...)` (P2-A2/B dùng tiếp) |
| `lib/features/auth/data/auth_repository.dart` | Tạo | Đặt lại mật khẩu 2 chế độ (2-B1 thêm `signIn`, `signUp`, `verifyOtp`…) |
| `lib/features/iam/logic/` | Chuyển (`git mv`) từ `presentation/users/bloc/` và `presentation/organization_profile/bloc/` | 4 cubit + state + `organization_profile_form_input.dart` |
| `lib/features/iam/logic/iam_ui_failure.dart`, `iam_ui_failure_mapper.dart` | Chuyển từ `presentation/shared/` | Cubit (logic) cần, R2 cấm logic → presentation. Thêm nhánh `AppException` |
| Các page / widget của 7 route | Sửa | Nhận repository, import cubit từ `logic/` |
| `lib/features/iam/presentation.dart`, `lib/features/auth/...` barrel | Sửa | Export đường mới |
| `lib/core/router/app_router.dart`, `lib/core/di/injection.dart` | Sửa | Truyền / đăng ký repository |
| Test liên quan | Chuyển + viết lại | Fake repository thay `FakeIamModule` |

## 4. Các bước

### Bước 1 — Hàm thuần dùng chung

1. `core/validation/tax_code.dart`: chép logic `modules/iam/domain/lib/src/tenant/rules/tax_code_format_rule.dart` thành `bool isValidTaxCode(String raw)` (+ hàm chuẩn hoá nếu rule có). Test: chép ca kiểm của test domain cũ (nếu có trong `modules/iam/domain/test`) sang `test/core/validation/tax_code_test.dart`.
2. `core/validation/password_policy.dart`: chép `modules/iam/domain/lib/src/password_policy.dart` (độ dài tối thiểu, loại ký tự…). Giữ nguyên câu báo lỗi đang dùng ở `reset_password_create_password_step.dart`.
3. Sửa 4 chỗ dùng (`organization_legal_profile_form_page.dart`, `organization_profile_cubit.dart`, `reset_password_page.dart`, `reset_password_create_password_step.dart`) sang hàm mới. `invitation_registration_form.dart` (auth, plan 2-A2) đổi luôn cho đồng bộ.

### Bước 2 — Lỗi IAM hiểu `AppException`

1. `git mv` `presentation/shared/iam_ui_failure.dart`, `iam_ui_failure_mapper.dart` → `lib/features/iam/logic/`; sửa barrel `presentation.dart` export đường mới (để `core/session` và phần cũ vẫn dùng được).
2. `IamUiFailureMapper.from`: thêm nhánh đầu
   ```dart
   if (error is AppException) {
     final code = switch (error.code) {
       AppErrorCode.noPermission => IamBlockedCodes.permissionDenied,     // màn IAM đang dùng mã cũ
       AppErrorCode.notFound => IamBlockedCodes.resourceNotFound,
       AppErrorCode.network => IamBlockedCodes.systemError,               // + câu "Không thể kết nối…" như nhánh mạng hiện có
       _ => error.code,
     };
     return _fromCode(code, fallbackMessage: null);
   }
   ```
   Câu tiếng Việt vẫn lấy từ `_localizedMessages` hiện có → màn hình hiện y như cũ. Riêng `NETWORK_ERROR` trả đúng `IamUiFailure` nhánh mạng đang có ("Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại mạng.", `retryable: true`).
   - Nếu `IamBlockedCodes` còn import từ `vet45_iam_application`: tạm giữ (P9 chép hằng số sang `logic/iam_error_codes.dart`).
3. Test: thêm 3 ca vào test mapper (hoặc tạo `test/features/iam/logic/iam_ui_failure_mapper_test.dart`): `AppException('NO_PERMISSION')` → code `PERMISSION_DENIED` + câu cũ; `AppException('STATE_CHANGED')` → `requiresReload`; `AppException('NETWORK_ERROR')` → câu mạng.

### Bước 3 — Model

Tạo trong `lib/features/iam/data/models/` (fromJson theo đúng mapper cũ — mở file mapper trong `modules/iam/infrastructure/lib/src/domain/tenant/` và `domain/platform_user/` để chép tên cột):

- `MyAccount { userId, email, givenName, familyName, phone, emailVerified, avatarReference }`.
- `TenantProfile` — đúng các field của DTO `GetTenantQuery` đang trả (tên, liên hệ, địa chỉ, tỉnh / xã, hồ sơ pháp lý, `version`, …). Mở `get_tenant_query.dart` / DTO để chép.
- `UpsertLegalProfileResult` (có cờ trùng MST nếu DTO cũ có — dùng cho `tax_code_duplicate_warning_bottom_sheet`).
- `PasswordResetRequestResult { operationId, maskedEmail, expiresAt, resendAvailableAt }`, `PasswordResetVerifyResult { verified }`, `PasswordResetCompletionResult { currentSessionRotated, otherSessionsRevoked }`.

Giữ tên class / field gần DTO cũ để đổi cubit ít nhất (có thể dùng `typedef` tạm nếu UI tham chiếu tên DTO cũ).

### Bước 4 — Repository

**`AccountRepository`** (`features/iam/data`): `SupabaseRpc` + `GoTrueClient`.

```dart
Future<MyAccount> getMyAccount();   // rpc firstRow('iam','get_my_platform_user_profile') + auth.currentUser email / emailConfirmedAt
Future<MyAccount> updateMyAccount({String? avatarReference, required String givenName, required String familyName, String? phone});
```
Chưa đăng nhập (`auth.currentUser == null`) → `AppException(AUTHENTICATION_REQUIRED)` (thay `_requireAuthenticated`).

**`OrganizationRepository`** (`features/iam/data`): `SupabaseRpc` + `Future<String> Function() tenantId` (= `SessionController.requireTenantId`).

```dart
Future<TenantProfile> getTenant();                       // không có dòng → AppException(NOT_FOUND)
Future<TenantProfile> updateProfile({..., required int expectedVersion});
Future<UpsertLegalProfileResult> upsertLegalProfile({..., required int expectedVersion, bool allowDuplicateTaxCode = false});
```

**`AuthRepository`** (`features/auth/data`): `SupabaseRpc` + `GoTrueClient`. Hai nhóm hàm, đúng thứ tự xử lý cũ:

```dart
// Đã đăng nhập (màn ID-23)
Future<PasswordResetRequestResult> requestMyPasswordReset();
Future<PasswordResetRequestResult> resendMyPasswordReset(String operationId);
Future<PasswordResetVerifyResult> verifyMyPasswordReset(String operationId, String code);
Future<PasswordResetCompletionResult> completeMyPasswordReset(String operationId, String newPassword);
// Quên mật khẩu (màn ID-04)
Future<PasswordResetRequestResult> requestPasswordResetByEmail(String email);
Future<PasswordResetRequestResult> resendPasswordResetByEmail(String operationId);
Future<PasswordResetVerifyResult> verifyPasswordResetByEmail(String operationId, String code);
Future<PasswordResetCompletionResult> completePasswordResetByEmail(String operationId, String newPassword);
```

- Nhóm "đã đăng nhập": chép thứ tự từ `SupabasePlatformIdentitySelfServiceAdapter` + `PasswordResetOperationStore` (mở `password_reset_operation_store.dart` lấy đúng tên RPC cho `touchResend`, `verifyCode`, `markCompleted` và tham số). `completeMyPasswordReset`: `get_password_reset_operation` → status ≠ `verified` → `AppException(STATE_CHANGED)`; `auth.updateUser(UserAttributes(password: …))` (lỗi `weak_password` / `password_too_weak` / chữ "password…short|policy" → `AppException('PASSWORD_POLICY_VIOLATION')`); `auth.signOut(scope: SignOutScope.others)` (lỗi theo `_guardSignOutOtherSessions`); mark completed.
- Che email: chép `_maskEmail`.
- Nhóm "quên mật khẩu": chép `SupabasePasswordResetPublicAdapter` (88 dòng).
- Validator mật khẩu: gọi `password_policy.dart` **trong cubit** trước khi gọi repository (như validator cũ chạy trước handler).

### Bước 5 — Cubit sang `logic/`

`git mv` 4 cubit + state + `organization_profile_form_input.dart` vào `lib/features/iam/logic/`. Với từng cubit:

| Cubit | Constructor mới | Đổi lời gọi |
|---|---|---|
| `MyAccountCubit` | `AccountRepository`, `SessionController` | `getMyAccount()`; danh sách tổ chức: `await session.loadAccessibleTenants()` rồi đọc `session.state.tenants` (cùng RPC, bỏ gọi `ListAccessibleTenantsQuery` riêng). Nếu UI cần kiểu `AccessibleTenantDto` cũ, đọc `SessionState.tenants` (đã là UI model) — chỉnh mapper tương ứng |
| `MyAccountEditCubit` | `AccountRepository` | `getMyAccount()`, `updateMyAccount(...)`; chạy validator cũ (chép điều kiện từ `UpdateMyIdentityProfileCommandValidator`) trước khi gọi |
| `PasswordResetCubit` | `AuthRepository` | 8 command → 8 hàm repository; validator mật khẩu → `password_policy.dart` |
| `OrganizationProfileCubit` | `OrganizationRepository` | bỏ `IExecutionContext` (repository tự lấy tenant) |

`catch` giữ `IamUiFailureMapper.from(e)` như cũ (đã hiểu `AppException` ở bước 2).

### Bước 6 — Page, router, DI

1. Page / widget của 7 route: bỏ `IIamModule` / `IExecutionContext`, nhận repository (+ `SessionController` cho `MyAccountPage`), tạo cubit bằng `BlocProvider(create:)`.
2. `injection.dart`: `registerLazySingleton` `AccountRepository`, `OrganizationRepository` (tenant từ `SessionController`), `AuthRepository`.
3. `app_router.dart`: 7 route truyền `getIt<…Repository>()`. `onLogout` của `/more/my-account` giữ như 1-B.
4. Grep lại: `grep -rn "IIamModule\|IExecutionContext" lib/features/iam/logic lib/features/iam/data lib/features/auth/data` → rỗng.

### Bước 7 — Test

1. Chuyển `organization_profile_cubit_test.dart` sang `test/features/iam/logic/`, thay `FakeIamModule` bằng mock repository (mocktail), giữ toàn bộ kịch bản cũ.
2. Widget test (`organization_legal_profile_form_page_test`, `organization_edit_profile_page_test`, `reset_password_page_test`, `profile_phone_validation_test`): đổi cách dựng page (truyền mock repository); không đổi kỳ vọng UI.
3. `test/features/tenant_admin/e2e_e02_u01_u03_u07_test.dart`: nếu dựng router / module, cập nhật đăng ký getIt.
4. Test mới:
   - `test/features/auth/data/auth_repository_test.dart`: `completeMyPasswordReset` khi operation chưa `verified` → `STATE_CHANGED`; `auth.updateUser` ném `AuthException(code: 'weak_password')` → `PASSWORD_POLICY_VIOLATION`; che email.
   - `test/features/iam/data/*_test.dart`: `fromJson` của `MyAccount`, `TenantProfile`.
   - `test/core/validation/*_test.dart`: MST, mật khẩu.

### Bước 8 — Commit

Gợi ý 3 commit: (1) `core/validation` + `IamUiFailureMapper` hiểu `AppException`; (2) tài khoản + đặt lại mật khẩu (`AccountRepository`, `AuthRepository`, 3 cubit, 4 route); (3) hồ sơ tổ chức (`OrganizationRepository`, cubit, 3 route).

## 5. Kiểm tra

- [ ] `dart analyze lib test tool`: không issue mới (so với trước khi làm).
- [ ] `dart run tool/check_feature_imports.dart`: 0 vi phạm.
- [ ] Grep bước 6.4 rỗng; `grep -rn "TaxCodeFormatRule\|PasswordPolicy" lib` chỉ còn trong `core/validation` (hoặc rỗng nếu đổi tên).
- [ ] `flutter test test/core test/features/iam test/features/auth test/features/tenant_admin`: đạt.
- [ ] `flutter test` toàn bộ `apps/erp`: không lỗi mới so với 61 lỗi của [TEST-BASELINE.md](../../TEST-BASELINE.md) (lưu ý: `e2e_e06_u02_fr01_01: edit profile save` đã có trong baseline).
- [ ] Kiểm tay trên Dev:
  - [ ] Tài khoản của tôi: hiện tên, email (đã xác minh / chưa), danh sách tổ chức; sửa tên + SĐT, lưu, quay lại thấy giá trị mới.
  - [ ] Đặt lại mật khẩu khi đã đăng nhập: nhận mã (Dev đang tắt xác nhận email — mã đi qua luồng email hiện có của RPC; nếu chưa có cấu hình email trên Dev thì đọc mã trong bảng operation / log để thử), nhập mã, đặt mật khẩu mới, đăng nhập lại bằng mật khẩu mới.
  - [ ] Quên mật khẩu từ màn đăng nhập: như trên theo email.
  - [ ] Hồ sơ tổ chức: xem, sửa thông tin liên hệ + địa chỉ; hồ sơ pháp lý: nhập MST sai định dạng → báo lỗi như cũ; MST trùng → sheet cảnh báo trùng; lưu được.
- [ ] CHECKLIST: tick cột "Mới" các dòng **ID-04, ID-11, ID-12, ID-13, ID-21, ID-22, ID-23**.

## 6. Rủi ro / lưu ý

- **Email đặt lại mật khẩu**: RPC đặt lại mật khẩu đang ghi việc gửi email vào outbox để `messaging_worker` gửi (TH-01 KI-07). Worker không còn chạy → **mã không tới hộp thư** trên Dev. Plan này không sửa (2-B2 làm `email_jobs` + Edge Function). Kiểm tay bằng cách đọc mã trong DB, hoặc ghi rõ "chưa kiểm được gửi mail" ở mục Review.
- `MyAccountCubit` đổi nguồn danh sách tổ chức sang `SessionController` — cùng RPC `list_accessible_tenants`, nhưng cờ `isCurrent` trước do handler tính theo `ICurrentTenant`; kiểm tra UI model trong `SessionState.tenants` đã có cờ này (mapper `AccessibleTenantUiMapper`).
- `IamUiFailureMapper` dời sang `logic/` nhưng `core/session` đang import qua barrel `features/iam/presentation.dart` (góp ý 1 review 1-B) — vẫn chạy; xử lý dứt điểm ở 2-A2.
- `organization_profile_actions_bottom_sheet.dart` / `confirm_activate_organization_bottom_sheet.dart` (luồng kích hoạt cũ) giữ nguyên ở bước (a); 2-B2 bỏ theo KI-05. Nếu các sheet này gọi module (kích hoạt tổ chức), **để nguyên lời gọi module** và ghi chú `TODO(2-B2)`.
- Không có GitNexus; phạm vi theo grep: 4 cubit, 7 route, ~6 file test, 35 file dùng `IamUiFailure*` / rule (phần lớn chỉ đổi import).

## 7. Review

- Ngày: 2026-10-08 · Review trên thư mục làm việc (chưa commit) của branch `refactor/simple-arch`
- Kết quả: ✅ **đạt**
- Đối chiếu plan:
  - `core/validation/tax_code.dart`, `password_policy.dart` (giữ tên lớp `PasswordPolicy`); mọi chỗ dùng (kể cả `invitation_registration_form.dart`) đã trỏ sang `core/`.
  - `IamUiFailureMapper` dời sang `logic/`, nhánh `AppException` đúng bước 2 (mạng → câu mạng cũ; `NO_PERMISSION` / `NOT_FOUND` → mã IAM cũ) — câu trên màn giữ nguyên. Có file `presentation/shared/*.dart` chỉ `export` sang `logic/` để importer cũ không phải sửa — hợp lý.
  - `AuthRepository`: 8 hàm đúng tên RPC của `PasswordResetOperationStore` / adapter public (đã đối chiếu migration `20260811021`, `20260811025`); `completeMyPasswordReset` giữ đúng thứ tự (kiểm `verified` → `STATE_CHANGED`, `updateUser` + map mật khẩu yếu → `PASSWORD_POLICY_VIOLATION`, `signOut(others)`, mark completed); che email `l***@…`.
  - `AccountRepository`, `OrganizationRepository`: tham số RPC khớp gateway cũ; `UpsertLegalProfileResult.fromJson` chép đúng nhánh `warning` / `profile`.
  - 4 cubit + state + form input sang `logic/`; `logic/`, `data/` không còn `IIamModule` / `IExecutionContext`.
  - Đã kiểm định dạng lỗi các RPC trong phạm vi: mã ở đầu chuỗi (`STATE_CHANGED`, `RESET_CODE_INVALID`, `PERMISSION_DENIED`…). Vài câu chữ thường (`'authentication required'`, `'platform user not found'`, `'invalid avatar reference'`) ra `SYSTEM_ERROR` — **giống** mapper cũ, không đổi hành vi.
- Claude chạy lại:
  - `dart analyze` toàn bộ file đổi / mới: không issue.
  - `dart run tool/check_feature_imports.dart`: thoát 0.
  - Test core + iam + auth + tenant_admin + my_account: 361 đạt / 4 lỗi — cả 4 thuộc test đã có trong TEST-BASELINE.
  - **Toàn bộ `apps/erp`: 1.391 đạt / 61 lỗi**; danh sách test lỗi trùng khớp lần review 1-B (không lỗi mới); +19 test.
- Góp ý (không chặn):
  1. **CHECKLIST**: 7 dòng ID-04, ID-11…13, ID-21…23 đã tick cột "Mới" kèm ghi chú "chưa kiểm tay". Theo quy ước CHECKLIST, "Mới" chỉ tick khi màn **đã kiểm và đạt tài liệu TH (kể cả sửa 🔧)** — các mục 🔧 của TH-01 cho nhóm này làm ở 2-B2. Đề xuất để ☐ + ghi chú "(a) xong 2-A1", tick sau khi kiểm tay và xong 2-B2.
  2. `MyAccountCubit` gọi `session.loadAccessibleTenants()` → cập nhật danh sách tổ chức chung của phiên (cờ `tenantsLoading`, `selectorFailure`). Không sai (cùng dữ liệu), chỉ lưu ý khi sheet chọn tổ chức đang mở cùng lúc.
- Còn lại cho bạn: commit (gợi ý 3 commit bước 8); kiểm tay trên Dev mục 5 (đặt lại mật khẩu: mã **không tới email** vì worker đã bỏ — đọc mã trong DB hoặc để 2-B2).
