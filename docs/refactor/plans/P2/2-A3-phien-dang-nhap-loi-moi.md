# 2-A3 — Phiên, đăng nhập, nhận lời mời

> Phase: P2 · Bước (a) chuyển kiến trúc · Trạng thái: Plan 📝 | Làm ⬜ | Review ⬜
> Gồm việc: 2B.5; góp ý review 1-B (1, 2, 3); góp ý review 2-A2 (2)
> Tài liệu liên quan: [PLAN.md](../../PLAN.md) P2; [TH-01](../../../02-yeu-cau/TH-01-to-chuc-va-nguoi-dung.md) ID-01 (đăng nhập), ID-06/07 (mã lời mời, kích hoạt theo lời mời), ID-08 (chọn tổ chức), ID-09 (tổ chức không thể truy cập); mẫu: [1-B](../P1/1-B-session-controller-guard.md), [2-A2](2-A2-iam-thanh-vien-loi-moi-nhat-ky.md)

## 1. Mục tiêu

Sau plan này, app **không còn gọi `IIamModule`** ở phần phiên và đăng nhập:

| Chỗ | Hiện tại | Sau 2-A3 |
|---|---|---|
| `SessionController.bootstrap / loadAccessibleTenants / switchTo` | `GetTenantContextQuery`, `ListAccessibleTenantsQuery`, `SwitchTenantContextCommand` | `SessionRepository` (core) gọi RPC |
| `SessionController.signOut` | `SignOutCommand` | `GoTrueClient.signOut()` + xoá phiên cục bộ |
| `LoginCubit` (`/login`) | `SignInTenantUserCommand`, `GetCurrentSessionQuery` | `AuthRepository.signIn` + `SessionController` |
| `InvitationAcceptanceCubit` (`/invitation`) | 7 command/query | `InvitationAcceptanceRepository` + `AuthRepository` + `AccountRepository` |
| `core/session/*` | import `features/iam/presentation.dart`, `features/tenant_context/...` | **không import `features/`** |

`IamSession` (in-memory, các module catalog / sales / inventory… đọc tenant + store qua `ICurrentTenant`, `IActiveStoreContext`) **vẫn giữ** đến P9. `SessionController` là nơi duy nhất ghi vào nó (`apply` / `applyAuthenticatedUser` / `clear`).

**Không đổi hành vi**, trừ một sửa đã hẹn ở review 1-B: đổi người dùng thì reset state tổ chức (mục 4, Bước 4).

## 2. Hiện trạng: Command/Query → RPC (tất cả schema `iam`)

| Command / Query | Handler / adapter cũ (chép logic từ đây) | RPC / Auth |
|---|---|---|
| `GetTenantContextQuery(bootstrapFromLastSelected: true)` | `application/.../get_tenant_context_query_handler.dart` + `bind_session_from_access_context` | `get_last_selected_tenant`, `get_tenant_context(p_tenant_id)`, `get_session_context(p_tenant_id)`, `set_last_selected_tenant(p_tenant_id)` |
| `ListAccessibleTenantsQuery` | `list_accessible_tenants_query_handler.dart` (gắn `isCurrent`) | `list_accessible_tenants` |
| `SwitchTenantContextCommand` | `switch_tenant_context_command_handler.dart` (rule khác tổ chức hiện tại, map lỗi, rollback) | `switch_tenant_context(p_target_tenant_id)`, `get_session_context`, `set_last_selected_tenant` |
| `SignInTenantUserCommand` | `sign_in_tenant_user_command_handler.dart` + `infrastructure/.../domain/auth/login_audit_authenticator.dart` + `supabase_authenticator.dart` | `auth.signInWithPassword`, `assert_my_platform_access`, `record_my_platform_login` |
| `SignOutCommand` | `sign_out_command_handler.dart` | `auth.signOut()` |
| `GetCurrentSessionQuery` | `get_current_session_query_handler.dart` | (đọc phiên) — đã có `SessionController.readSession()` từ 2-A2 |
| `InspectInvitationTokenQuery` | `inspect_invitation_token_query_handler.dart` + `domain/invitation/supabase_tenant_invitation_acceptance_port.dart` | `inspect_invitation_token(p_token)` |
| `AcceptInvitationCommand` / `DeclineInvitationCommand` | `accept_/decline_invitation_command_handler.dart` + acceptance port | `accept_invitation`, `decline_invitation` (`p_token`, `p_idempotency_key`) |
| `RegisterFromInvitationCommand` | `register_from_invitation_command_handler.dart` + `adapters/invitation/supabase_invitation_identity_adapter.dart` + `invitation_auth_client.dart` | `auth.signUp(data: first_name, last_name, phone)` → `update_my_platform_user_profile` → `accept_invitation` |

Đường dẫn tính từ `modules/iam/{application,infrastructure}/lib/src/`. Mapper JSON: `domain/access/supabase_iam_access_gateway.dart` (`_mapTenantContext`, `_mapPrincipalAccess`, `listAccessibleTenants`, `_mapTenantStatus`).

## 3. Thay đổi

| File | Hành động | Nội dung |
|---|---|---|
| `lib/core/session/session_repository.dart` | Tạo | RPC phiên: `getTenantContext`, `getSessionContext`, `listAccessibleTenants`, `switchTenantContext`, `getLastSelectedTenantId`, `setLastSelectedTenantId` |
| `lib/core/session/models/tenant_context.dart` | Tạo | `TenantContext` + enum `TenantContextStatus`, `TenantContextInvalidationReason`, `TenantStatus` (thay `TenantContextDto`, `TenantLifecycleStatus`) |
| `lib/core/session/models/accessible_tenant.dart` | Tạo | `AccessibleTenant` (thay `SelectOrganizationItemUiModel` trong state) |
| `lib/core/session/models/session_principal.dart` | Tạo | `SessionPrincipal` (kết quả `get_session_context`) |
| `lib/core/session/models/sign_out_result.dart` | Tạo | `SignOutResult(localCleared, remoteSucceeded)` |
| `lib/core/session/session_state.dart` | Sửa | Dùng model core; `OrganizationEmptyStateType` chuyển vào đây; bỏ import `features/` |
| `lib/core/session/session_controller.dart` | Sửa | Bỏ `IIamModule`; nhận `SessionRepository`, `IamSession`; reset khi đổi user; `signOut` trực tiếp; bỏ import `features/` |
| `lib/features/auth/data/auth_repository.dart` | Sửa | Thêm `signIn`, `signUpFromInvitation` |
| `lib/features/auth/data/invitation_acceptance_repository.dart` | Tạo | `inspect`, `accept`, `decline` |
| `lib/features/auth/data/models/*.dart` | Tạo | `InvitationTokenInspection`, `AcceptedMembership` (đủ field cubit đọc), … |
| `lib/features/auth/logic/` | Chuyển từ `presentation/bloc/` | `LoginCubit` + state, `InvitationAcceptanceCubit` + state |
| `lib/features/tenant_context/...`, `lib/features/iam/presentation/organizations/...` | Sửa | Widget chọn tổ chức đọc `AccessibleTenant`; nhãn vai trò map ở widget |
| `lib/features/dashboard/presentation/dashboard_page.dart`, `more_page.dart`, `app_router.dart` | Sửa | `state.current` kiểu mới; `SignOutResult` |
| `lib/core/di/injection.dart` | Sửa | Đăng ký `SessionRepository`, `InvitationAcceptanceRepository`; `SessionController` không nhận `iamModule` |
| Test liên quan | Sửa / chuyển | xem Bước 8 |

## 4. Các bước

### Bước 1 — Model phiên (core)

Trong `lib/core/session/models/`, chép đúng mapper của `SupabaseIamAccessGateway`:

- `TenantContext`: `status` (`valid | invalidated | none`, mặc định `none`), `tenantId`, `tenantName`, `roleLabel` (= `role`), `isOwner`, `permissions`, `tenantStatus`, `invalidationReason` (9 giá trị camelCase như `_mapTenantContext`), `blockedErrorCode`. `TenantContext.none` = `const TenantContext(status: none)`.
- `TenantStatus`: `active | provisioning | suspended | closed` (giá trị lạ → `active`, như `_mapTenantStatus`).
- `AccessibleTenant`: `id`, `name`, `code` (`TEN-` + 6 ký tự đầu, chép `_codeFor` của `AccessibleTenantUiMapper`), `roleCode` (giá trị thô `role`), `status`, `isOwner`, `isCurrent`, `isSelectable`. Rule chọn được: `status == active` **hoặc** (`provisioning` và `isOwner`) — xem `AccessibleTenantDto.isSelectable` + `AccessibleTenantUiMapper.fromDto`.
- `SessionPrincipal`: `userId`, `tenantId`, `activeStoreId`, `activeStoreCode`, `activeStoreDisplayName`, `role`, `isOwner`, `permissions` (chép `_mapPrincipalAccess`, `_optionalId`).

Nhãn vai trò (`IamRoleLabelMapper`) thuộc `features/iam/logic` nên **không** map trong core: widget chọn tổ chức gọi `IamRoleLabelMapper.toDisplayLabel(item.roleCode)`.

### Bước 2 — `SessionRepository` (core)

```dart
class SessionRepository {
  SessionRepository({required SupabaseRpc rpc});

  Future<TenantContext> getTenantContext(String? tenantId);      // map rỗng → TenantContext.none
  Future<SessionPrincipal?> getSessionContext(String tenantId);   // map rỗng → null
  Future<List<AccessibleTenant>> listAccessibleTenants({String? currentTenantId}); // gắn isCurrent
  Future<TenantContext> switchTenantContext(String targetTenantId);
  Future<String?> getLastSelectedTenantId();
  Future<void> setLastSelectedTenantId(String? tenantId);
}
```

- Không nhận `tenantId` callback như các repository khác (chính nó cung cấp tenant).
- Gửi tham số `null` đúng như gateway cũ (`get_tenant_context` khi `tenantId == null` gọi **không** tham số).
- `get_last_selected_tenant` trả scalar (`String?`), `set_last_selected_tenant` trả void → dùng `_rpc.call`.

### Bước 3 — `SessionController` dùng repository

Constructor: `SessionController({required SessionRepository repository, GoTrueClient? auth, IamSession? iamSession, ...})` — bỏ `iamModule`, `sessionPort` (dùng thẳng `iamSession`, vốn implement `IIamSessionPort`).

1. **`bootstrap()`** — chép `GetTenantContextQueryHandler` nhánh `bootstrapFromLastSelected`:
   1. `lastSelected = trim(getLastSelectedTenantId())`; `bootstrapId = lastSelected ?? trim(tenantId hiện tại)`; null → `TenantContext.none`.
   2. `context = getTenantContext(bootstrapId)`.
   3. `invalidated` vì `tenantSuspended` / `tenantClosed` → trả `context` (không bind).
   4. Không `valid` hoặc `tenantId == null` → `TenantContext.none`.
   5. `_bindSession(context.tenantId!)`; nếu `lastSelected == null` → `setLastSelectedTenantId(context.tenantId)`.
   6. Sau đó như hiện tại: `loadAccessibleTenants()` rồi `_emitResolvedContext(context)`.
2. **`_bindSession(tenantId)`** — chép `bindSessionFromAccessContext`: `getSessionContext(tenantId)`; null hoặc thiếu `activeStoreId` → ném lỗi (giữ thông điệp cũ “Active store context is required.” dưới dạng `AppException`); thành công → `iamSession.apply(PrincipalAccessDto(...))`.
3. **`loadAccessibleTenants()`** → `listAccessibleTenants(currentTenantId: tenantId)`.
4. **`switchTo(id)`** — chép `SwitchTenantContextCommandHandler`:
   1. `id == tenantId` hiện tại → lỗi validation (rule `TargetTenantMustDifferFromCurrentRule`; chép message).
   2. `switchTenantContext(id)`; không `valid` / `tenantId == null` → lỗi mã `blockedErrorCode ?? 'TENANT_ACCESS_DENIED'`.
   3. `_bindSession` — lỗi thì map như `_mapSwitchSessionError` (mã đã biết giữ nguyên, còn lại `SYSTEM_ERROR`).
   4. `setLastSelectedTenantId` lỗi → bind lại tổ chức cũ (bỏ qua lỗi) rồi ném `SYSTEM_ERROR`.
   5. Phần emit / reload sau khi lỗi giữ như hiện tại (`_mapFailure`, `_shouldReloadTenantsAfterSwitchFailure`).
   6. `_applyTenantContextPermissions` hiện có: giữ (nó ghi đè `role`/`permissions` theo `TenantContext` sau khi bind).
5. **`signOut()`** — chép `SignOutCommandHandler`: `try { await auth.signOut(); remote = true } catch { remote = false } finally { iamSession.clear() }`, emit `SessionState(authStatus: signedOut)`, trả `SignOutResult(localCleared: true, remoteSucceeded: remote)`.
6. **Lỗi**: các chỗ đang `throw ApplicationException(...)` / `IamBlockedException(...)` đổi thành `AppException('<MÃ>')`; `IamUiFailureMapper.from` đã hiểu `AppException` (2-A1). Kiểm `_mapFailure`: hiện đọc `ApplicationException.message` để lấy mã dạng `ABC_DEF` — đổi sang `AppException.code`.

### Bước 4 — Đăng nhập / đổi người dùng (góp ý 1-B #2)

- Thêm `void applySignedInUser(String userId)` (public, gọi `_apply`) — xem Bước 5.
- Trong `_apply(userId)`: nếu `state.userId != null && state.userId != userId` → **emit state mới hoàn toàn** `SessionState(authStatus: signedIn, userId: userId, userDisplayName: …)` (bỏ `current`, `tenants`, failure… của người trước), sau `iamSession.applyAuthenticatedUser(userId)`.
- Test: đăng nhập A → bootstrap có tổ chức → `signedIn` của B → state không còn `current` / `tenants` của A, `tenantId == null`.

### Bước 5 — `AuthRepository.signIn` + `LoginCubit`

```dart
Future<String> signIn({required String email, required String password});
```

Chép `SupabaseAuthenticator.signIn` + `LoginAuditAuthenticator.signIn`:
1. `auth.signInWithPassword` (lỗi `AuthException` để `AppException.from` xử lý — so `login_error_mapping_test.dart` để chắc các thông báo sai mật khẩu / chưa xác nhận… không đổi).
2. `assert_my_platform_access`: lỗi chứa `PLATFORM_USER_SUSPENDED` → `auth.signOut()` rồi ném `AppException('PLATFORM_USER_SUSPENDED')`; lỗi khác **bỏ qua**.
3. `record_my_platform_login`: lỗi **bỏ qua**.
4. `userId = auth.currentUser?.id`; rỗng → ném `AppException(AppErrorCode.authRequired)`. Trả `userId`.

`LoginCubit` (chuyển sang `features/auth/logic/`): nhận `AuthRepository` + `SessionController`.
- `final userId = await auth.signIn(...)`; **`session.applySignedInUser(userId)`** ngay (handler cũ gọi `sessionPort.applyAuthenticatedUser` đồng bộ; nếu chỉ chờ `onAuthStateChange` thì `readSession()` ngay sau có thể chưa thấy user → báo “Phiên đăng nhập không hợp lệ”).
- `final s = session.readSession()`; phần emit giữ nguyên.

### Bước 6 — Nhận lời mời (`/invitation`)

`InvitationAcceptanceRepository` (`features/auth/data/`), nhận `SupabaseRpc` (không cần tenant):

```dart
Future<InvitationTokenInspection> inspect(String token);   // inspect_invitation_token
Future<AcceptedMembership> accept(String token, {required String idempotencyKey});  // accept_invitation
Future<DeclinedInvitation> decline(String token, {required String idempotencyKey}); // decline_invitation
```

Model chép từ `supabase_tenant_invitation_acceptance_port.dart`; chỉ giữ field mà cubit / page đọc (grep `InvitationTokenInspectionDto`, `TenantMemberDetailDto`, `InvitationDetailDto` trong `invitation_acceptance_cubit.dart`, `invitation_token_page.dart`). Có thể dùng lại `TenantMemberDetail` (2-A2) cho kết quả `accept` nếu JSON trùng.

`AuthRepository.signUpFromInvitation({email, password, givenName, familyName, phone})` — chép `SupabaseInvitationAuthClient.createAccount` + kiểm của `SupabaseInvitationIdentityAdapter`:
- `auth.signUp(email: email.trim().toLowerCase(), password, data: {first_name, last_name, phone?})`.
- `user == null`, không có session, chưa `emailConfirmedAt`, hoặc email trả về khác email mời → `AppException('SYSTEM_ERROR')`.
- `AuthException`: chép `mapInvitationAuthException` (`email_exists`, `user_already_exists` → `PLATFORM_USER_ALREADY_EXISTS`; `weak_password`, `validation_failed`… → `VALIDATION_ERROR`; còn lại → `SYSTEM_ERROR`).
- Trả `userId`.

`InvitationAcceptanceCubit` (chuyển sang `features/auth/logic/`): nhận `InvitationAcceptanceRepository`, `AuthRepository`, `AccountRepository`, `SessionController`.
- Kiểm đầu vào như handler cũ (token rỗng → `INVITATION_TOKEN_INVALID`; key rỗng → `VALIDATION_ERROR`).
- **Đăng ký** (chép `RegisterFromInvitationCommandHandler`): kiểm `PasswordPolicy.isValid` (core/validation) và họ / tên không rỗng → `inspect(token)` → `accountExists` thì `PLATFORM_USER_ALREADY_EXISTS` → `signUpFromInvitation` → `AccountRepository.updateMyAccount(avatarReference: null, givenName, familyName, phone)` (cùng RPC `update_my_platform_user_profile` mà `SupabasePlatformUserProfileGateway` dùng — kiểm lại) → `accept(token, key)`.
- **Đăng nhập rồi nhận**: `auth.signIn` → `session.applySignedInUser` → `session.readSession()` → `accept`.
- **Đăng xuất** (đổi tài khoản): `session.signOut()`.
- Thứ tự emit, xử lý `idempotencyKey` giữ nguyên.

### Bước 7 — Bỏ import `features/` khỏi `core/session` (góp ý 1-B #1, 2-A2 #2)

1. `session_state.dart`: `current` → `TenantContext?`; `tenants` → `List<AccessibleTenant>`; `IamUiFailure` import từ `core/iam/` (đã có từ 2-A2 — **giữ `core/iam/`**, vì state phiên cần nó; góp ý 2-A2 #1 coi như đã giải quyết bằng lý do này); `OrganizationEmptyStateType` chuyển định nghĩa vào `session_state.dart` và re-export ở chỗ cũ.
2. `session_controller.dart`: bỏ `features/iam/presentation.dart`, `AccessibleTenantUiMapper`; `selectorEmptyStateType`, `retryLoadAccessibleTenants` trả kiểu mới.
3. Widget dùng `SelectOrganizationItemUiModel` (4 file) → `AccessibleTenant` (hoặc giữ `typedef SelectOrganizationItemUiModel = AccessibleTenant;` ở chỗ cũ, `TODO(P9)`), hiển thị `roleLabel` qua `IamRoleLabelMapper`. `AccessibleTenantUiMapper` xoá nếu không còn ai dùng.
4. `dashboard_page.dart`, `tenant_readiness_cubit.dart`: đọc `state.current` kiểu `TenantContext`. `tenant_readiness_cubit` còn gọi `GetTenantContextQuery(bootstrapFromLastSelected: false)` — **để nguyên** (2-B2 xoá readiness).
5. `SessionController.readSession()` vẫn trả `SessionDto` (package cũ) — `TODO(P9)`; `IamSession.apply` vẫn cần `PrincipalAccessDto`. Hai import `vet45_iam_*` còn lại ở `core/session` là chủ ý, ghi chú trong file.
6. Kiểm: `grep -rn "features/" lib/core/session` → rỗng.

### Bước 8 — DI, router, test

1. `injection.dart`: `registerLazySingleton<SessionRepository>`, `<InvitationAcceptanceRepository>`; `SessionController(repository:, auth:, iamSession: iamRuntime.session, …)`.
2. `app_router.dart`, `more_page.dart`, `dashboard_page.dart`: `SignOutResult` thay `SignOutResultDto`; `/login`, `/invitation` tạo cubit với repository mới.
3. Test:
   - `test/core/session/session_controller_test.dart`, `session_revoked_signal_test.dart`: mock `SessionRepository` thay `FakeIamModule`; thêm test A → B (Bước 4), test `switchTo` cùng tổ chức (validation), test `setLastSelected` lỗi → rollback.
   - `test/core/session/session_repository_test.dart` (mới): `fromJson` `TenantContext` (đủ 3 status, 1–2 `invalidation_reason`), `AccessibleTenant.isSelectable` (provisioning + owner), `get_tenant_context` không tham số khi `tenantId == null`.
   - `login_error_mapping_test.dart`, `wgt_th01_s0_login_test.dart`, `invitation_acceptance_cubit_test.dart`, `e2e_e03_u01_u06_test.dart`, `tenant_context_blocked_ui_test.dart`, `wgt_e05_tenant_context_test.dart`, `e2e_e06_u01_fr01_01_my_account_test.dart`: chuyển sang mock repository, giữ kịch bản.
   - `test/features/auth/data/auth_repository_sign_in_test.dart` (mới): `assert_my_platform_access` trả `PLATFORM_USER_SUSPENDED` → gọi `signOut` và ném; lỗi khác → vẫn thành công; `record_my_platform_login` lỗi → vẫn thành công.
   - Góp ý 1-B #3: xoá 2 import thừa trong test session (analyzer báo `unnecessary_import`).

### Bước 9 — Commit

Gợi ý 3 commit: (1) `SessionRepository` + `SessionController` + state (kèm test core); (2) đăng nhập / đăng xuất; (3) nhận lời mời.

## 5. Kiểm tra

- [ ] `dart analyze lib test`: không error / warning mới.
- [ ] `dart run tool/check_feature_imports.dart`: 0 vi phạm.
- [ ] `grep -rn "features/" lib/core/session` → rỗng.
- [ ] `grep -rln "IIamModule" lib/core lib/features/auth lib/features/tenant_context` → rỗng.
- [ ] `flutter test` toàn `apps/erp`: không lỗi mới so với 2-A2 (1.395 pass / 61 fail).
- [ ] Kiểm tay trên Dev:
  - [ ] Đăng nhập đúng / sai mật khẩu: thông báo như cũ.
  - [ ] Mở lại app khi đã đăng nhập: vào thẳng tổ chức chọn lần trước.
  - [ ] Có ≥ 2 tổ chức: mở chọn tổ chức, đổi tổ chức → dữ liệu (vd danh sách sản phẩm) theo tổ chức mới; mở lại app vẫn ở tổ chức mới.
  - [ ] Đăng xuất → đăng nhập tài khoản khác: không thấy tên / danh sách tổ chức của tài khoản trước.
  - [ ] `/invitation`: dán mã lời mời (tạo ở 2-A2) → người chưa có tài khoản đăng ký + nhận; người đã có tài khoản đăng nhập + nhận; từ chối.
- [ ] CHECKLIST: ghi chú "(a) xong 2-A3" cho ID-01, ID-06, ID-07, ID-08, ID-09. (ID-02, ID-03, ID-05 là màn 🆕 — để 2-B.)

## 6. Rủi ro / lưu ý

- **Thứ tự sự kiện auth**: `onAuthStateChange` bắn sau `signInWithPassword` trả về (bất đồng bộ). Vì vậy `LoginCubit` / `InvitationAcceptanceCubit` phải gọi `applySignedInUser` ngay; `_apply` đã bỏ qua lần gọi trùng (cùng `userId`), nên không bị reset 2 lần.
- **`IamSession` là nguồn tenant / store của module cũ** (catalog, sales, inventory…). Quên `apply` sau bind / switch → các màn khác báo “Active store context is required.” hoặc đọc tenant cũ. Kiểm tay mục đổi tổ chức là bắt buộc.
- **Reset khi đổi user** (Bước 4) là thay đổi hành vi duy nhất; nếu có test cũ dựa vào việc giữ state, sửa test và ghi vào Review.
- **Mã lỗi đăng nhập**: `assert_my_platform_access` cũ so chuỗi chứa `PLATFORM_USER_SUSPENDED` (không chỉ ở đầu) — giữ cách so `contains`, đừng dựa vào `AppException.code`.
- **Đăng ký từ lời mời trên Dev** chạy được vì `enable_confirmations = false` (session có ngay, `emailConfirmedAt` có giá trị). Nếu bật xác nhận email (PLAN 2A.3), luồng này sẽ ném `SYSTEM_ERROR` — ghi nhận, xử lý ở 2-B.
- Phạm vi: ~440 dòng `SessionController` + 66 `LoginCubit` + 462 `InvitationAcceptanceCubit`, ~12 file test. Plan lớn (≈1,5 ngày); nếu cần tách, làm Bước 1–4 + 7 trước (phiên), Bước 5–6 sau.

## 7. Review

<!-- Claude ghi sau khi bạn code xong -->
- Ngày, commit được review:
- Kết quả:
- Góp ý:
