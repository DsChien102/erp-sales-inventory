# 8-C — App không còn phụ thuộc IAM cũ (`vet45_iam_*`)

> Phase: P8 (làm gọn IAM, chốt 2026-10-11 — kéo một phần P9 lên) · Trạng thái: Plan ✅ | Làm ✅ | Review ✅
> Thứ tự: **8-C → [8-D](8-D-xoa-iam-cu.md) → [8-B](8-B-db-ki08-don-luong-cu.md) + đợt kiểm IAM**.
> Mục tiêu đo được: `grep -rn "vet45_iam" apps/erp` **rỗng**; `apps/erp/pubspec.yaml` không còn 3 gói `vet45_iam_*`; app và test chạy như trước.

## 1. Hiện trạng (đo 2026-10-11)

| Nhóm | Số file | Dùng gì của IAM cũ |
|---|---|---|
| `lib` | 53 | Hằng số `IamBlockedCodes`, `IamPermissions`, `IamAuditEvents`; DTO (`TenantMemberDto`, `TenantMemberDetailDto`, `InvitationDetailDto`, `TenantAuditLogSummaryDto`, `SessionDto`, `PrincipalAccessDto`, `TenantLifecycleStatus`, `Platform*Dto`); `PasswordPolicy`; ngoại lệ `IamBlockedException`; `IIamModule`, `IamSession`, `IamStartup` |
| `lib/core/di/injection.dart` | 1 | `IamStartup.initialize` → `IamRuntime` cấp `IExecutionContext`, `IPermissionChecker`, `ITenantAccessChecker`, `IActiveStoreContext`, `IamSession` (= `ICurrentUser`, `ICurrentTenant`, `IPrincipalSnapshot`) cho **các module nghiệp vụ cũ** (catalog, partner, pricing, sales, einvoice, inventory — truyền qua tham số `*Startup.initialize`) |
| Sales (`features/sales/presentation`) | 7 | `IIamModule` (2 query: `GetMyIdentityProfileQuery`, `GetActiveStoreContextQuery`), `IActiveStoreContext` |
| `core/router/app_router.dart` | 1 | `IamPermissions`, `getIt<IamSession>()` (`hasPermission`, `isOwner`) |
| `test` dựa trên `FakeIamModule` / `RecordingIamModule` / `iam_module_repositories.dart` | **27** | Phần tốn công nhất |
| `test` chỉ import hằng số / DTO | 32 | Đổi import |

Interface dùng chung (giữ, ở `packages/vet45_shared/application`): `IExecutionContext { requireUserId(); requireTenantId(); correlationId }`, `ICurrentUser { userId }`, `ICurrentTenant { tenantId }`, `IPermissionChecker { require(code) }`, `ITenantAccessChecker { ensureAccess(tenantId) }`. Hai interface **định nghĩa trong `modules/iam`** (sẽ bị xoá): `IPrincipalSnapshot { role; isOwner; hasPermission() }`, `IActiveStoreContext { activeStoreId; requireActiveStoreId() }` — chỉ Sales trong `erp` dùng.

## 2. Các bước

### Bước 1 — Hằng số, kiểu, ngoại lệ sang `core`

1. `lib/core/iam/iam_codes.dart`: chép **chỉ các mã đang dùng** của `IamBlockedCodes`, `IamPermissions`, `IamAuditEvents` (grep từng mã trong `apps/erp/lib`). Giữ tên lớp để sửa ít (`IamBlockedCodes.x`).
2. `PasswordPolicy`: dùng `core/validation/password_policy.dart` (có từ 2-A1); bỏ bản IAM.
3. `TenantLifecycleStatus` → `TenantStatus` (`core/session/models/tenant_context.dart`).
4. `IamUiFailureMapper`: bỏ nhánh `IamBlockedException`; giữ `ApplicationException` / `ValidationException` (của `vet45_shared`, module cũ vẫn ném).
5. DTO trong `features/iam`: thay bằng model 2-A2 (`TenantMember`, `TenantMemberDetail`, `TenantInvitationDetail`, `TenantAuditLog*`) — `member_ui_mapper`, `organization_member_detail_state`, `invitation_*`, `organization_audit_logs_page`. Chỗ còn gọi `GetTenantMemberQuery` / `GetInvitationQuery` / `GetTenantAuditLogQuery` (thường là nhánh test cũ trong page) → bỏ.

### Bước 2 — Thay `IamSession` / `IamRuntime` bằng `core/session`

1. `lib/core/session/session_store.dart` — chuyển `IamSession` vào core (≈100 dòng): `userId`, `tenantId`, `activeStoreId`, `activeStoreCode`, `activeStoreDisplayName`, `role`, `isOwner`, `permissions`; `apply(SessionPrincipal)` (thay `PrincipalAccessDto`), `applyAuthenticatedUser`, `clear`. **Giữ đúng** quy tắc tạm `hasPermission(code) => role != null || permissions.contains(code)` (TH-01 BR-52: thành viên hoạt động có mọi quyền nghiệp vụ).
2. `lib/core/session/session_contracts.dart`:
   - `CoreExecutionContext implements IExecutionContext, ICurrentUser, ICurrentTenant` (đọc `SessionStore`; `correlationId` = UUID tạo 1 lần; lỗi ném `ApplicationException('User is required')` / `('Tenant is required')` như cũ).
   - `CorePermissionChecker implements IPermissionChecker`: mã `platform.*` → RPC `has_platform_permission`; `isOwner` → qua; `store.hasPermission(code)` → qua; còn lại → RPC `iam.has_permission(p_tenant_id, p_permission)`; sai → `ApplicationException('Permission denied: <code>')` (giữ chuỗi để module cũ map lỗi như trước).
   - `CoreTenantAccessChecker implements ITenantAccessChecker`: `SessionRepository.getSessionContext(tenantId) == null` → `ApplicationException('Tenant access denied: <id>')`.
   - `SessionStore.requireActiveStoreId()` có **tự nạp lại** khi trống (chép `IamActiveStoreContext._refreshActiveStore`: một lần gọi `getSessionContext(tenantId)` dùng chung, thiếu tenant → `ApplicationException('Tenant context is required.')`).
3. `SessionController`: nhận `SessionStore` thay `IamSession`; `readSession()` trả `SessionSnapshot` (core, cùng field `SessionDto`) — sửa `LoginState`, `IamFeatureAccessState`; `_principalDto` bỏ.
4. `injection.dart`: bỏ `IamStartup.initialize`, `IIamModule`, `IamSession`; đăng ký `SessionStore`, `CoreExecutionContext` (cho `IExecutionContext`, `ICurrentUser`, `ICurrentTenant`), `CorePermissionChecker`, `CoreTenantAccessChecker`; truyền 3 cái này vào `CatalogStartup` … `InventoryStartup` (thay `iamRuntime.*`).
5. `app_router.dart`, `partner_list_page.dart`: `getIt<IamSession>()` → `getIt<SessionController>()` (`hasPermission`, `isOwner`); `IamPermissions` → `core/iam/iam_codes.dart`.

### Bước 3 — Sales

1. `sales_checkout_orchestrator.dart`: `GetActiveStoreContextQuery` → `SessionController` (mã / tên cửa hàng từ `SessionStore.activeStoreCode`, `activeStoreDisplayName`; thiếu thì `requireActiveStoreId()` để nạp lại); `GetMyIdentityProfileQuery` → `AccountRepository.getMyAccount()` (họ tên, email) — Sales được dùng `data/` của feature `iam` (R3 cho phép).
2. `sales_draft_list_scope.dart`: `GetMyIdentityProfileQuery` → `AccountRepository.getMyAccount()`.
3. Các file Sales dùng `IActiveStoreContext` → `SessionController.requireActiveStoreId()` / `activeStoreId`.
4. Giữ nguyên hành vi (chuỗi hiển thị người bán, cửa hàng); chỉ đổi nguồn.

### Bước 4 — Test

1. Thay `test/features/iam/support/iam_module_repositories.dart` bằng fake theo repository (`FakeMemberRepository`, `FakeInvitationRepository`, `FakeAuditLogRepository`, `FakeOrganizationRepository`, `FakeAccountRepository`) — chép kịch bản dữ liệu của `FakeIamModule` / `FakeIamScenario` mà 27 file đang dùng (đọc từng file để biết kịch bản nào thật sự cần).
2. `testSessionController` / `loginSession` dùng `SessionStore` thay `IamSession` + `PrincipalAccessDto`.
3. 32 file chỉ đổi import (`core/iam/iam_codes.dart`, model mới).
4. Test mới: `CorePermissionChecker` (platform / Owner / thành viên / RPC từ chối), `CoreTenantAccessChecker`, `SessionStore.requireActiveStoreId` tự nạp lại đúng 1 lần khi gọi song song.

### Bước 5 — Bỏ phụ thuộc

1. `apps/erp/pubspec.yaml` (và `apps/erp/example/pubspec.yaml`): xoá `vet45_iam_application`, `vet45_iam_domain`, `vet45_iam_infrastructure`; `flutter pub get`.
2. `grep -rn "vet45_iam" apps/erp` → rỗng.
3. Xoá code chết đã không còn route: `features/iam/presentation/widgets/platform_*`, `features/iam/presentation/testing/*` (sau khi test không còn dùng), `features/iam/testing.dart`, phần `readiness` / onboarding còn sót trong `presentation.dart`.

### Bước 6 — Commit

Gợi ý: (1) hằng số / DTO; (2) session core + DI; (3) Sales; (4) test; (5) pubspec + xoá code chết.

## 3. Kiểm tra

- [ ] `grep -rn "vet45_iam" apps/erp` rỗng; `apps/erp/pubspec.yaml` không còn `vet45_iam_*`.
- [ ] `dart analyze lib test`: không error / warning mới. `check_feature_imports`: 0 vi phạm.
- [ ] `flutter test` toàn `apps/erp`: không lỗi mới so với 8-A (1.481 pass / 61 fail; số pass có thể đổi do viết lại test — so theo danh sách fail).
- [ ] Chạy app trên Dev (kiểm tay ngắn): đăng nhập → trang chủ → mở một màn catalog, một màn partner, tạo một đơn nháp Sales (cần cửa hàng + tên người bán) → không lỗi "Tenant is required" / "Active store context is required".

## 4. Rủi ro / lưu ý

- **Module nghiệp vụ cũ phụ thuộc chuỗi lỗi**: giữ nguyên câu `ApplicationException` (`Permission denied: …`, `Tenant is required`…) để mapper của chúng không đổi hành vi.
- `CorePermissionChecker` gọi RPC khi không có trong bộ nhớ — giống bản cũ; không thêm cache mới.
- 27 test viết lại: giữ **kịch bản và kỳ vọng**, chỉ thay nguồn dữ liệu giả. Không xoá test để "cho qua".
- `TenantAccessRevokedSignal` vẫn ở `vet45_shared` (xoá ở P9).

## 5. Review

- Ngày, commit được review: 2026-10-11, working tree trên `124c84aab`. Code do một phiên Claude khác viết theo yêu cầu "implement" của bạn; review độc lập.
- Kết quả: **Đạt.**
  - Mục tiêu đo được: `grep -rn "vet45_iam" apps/erp/lib apps/erp/test apps/erp/pubspec.yaml apps/erp/example/pubspec.yaml` **rỗng**.
  - `SessionStore` giữ đúng quy tắc tạm `role != null || permissions.contains(code)`; `requireActiveStoreId` tự nạp lại một lần dùng chung; `_applyTenantContextPermissions` giữ cả `activeStoreCode` / `activeStoreDisplayName` (Sales cần).
  - `CoreExecutionContext`, `CorePermissionChecker`, `CoreTenantAccessChecker` giữ nguyên chuỗi `ApplicationException` cũ (`User is required`, `Permission denied: …`, `Tenant access denied: …`); DI truyền vào cả 6 `*Startup.initialize`.
  - Sales: cửa hàng từ phiên, người bán từ `AccountRepository.getMyAccount()`; kiểm "cửa hàng của query khác phiên" cũ bỏ (giờ cùng một nguồn) — thay bằng 2 test mới: thiếu mã cửa hàng / hồ sơ người bán của người khác → dừng, không điều hướng.
  - Test: 21 test pass ở 8-A không còn tên cũ — đều là **đổi tên** theo kiểu mới (`SessionSnapshot`, "session store", "via repositories") hoặc test của widget đã xoá (onboarding, người dùng nền tảng, `RecordingIamModule`). Test mapper đổi từ `IamBlockedException` sang `AppException`; hành vi nhánh `AppException` không đổi từ 2-A1.
  - `check_feature_imports`: 0 vi phạm. `flutter test` toàn `apps/erp`: **1.494 pass / 59 fail**; không lỗi mới; 2 lỗi cũ biến mất cùng file test bị xoá.
- Góp ý:
  1. 3 warning mới `unused_import` (`../../support/iam_fixtures.dart`) trong `organization_member_detail_cubit_test`, `organization_users_cubit_test`, `organization_member_detail_page_test` — xoá 3 dòng import.
  2. Working tree đang lẫn thay đổi 8-B chưa xong (sửa tại chỗ `20260811012`, `supabase/tests/iam_transfer_ownership_other_owner.sql`, TH-01 / `ADMIN-SCREENS` bỏ lý do khôi phục). Commit 8-C **không** gồm các file `supabase/` và tài liệu đó; xử lý ở 8-B.
  3. Kiểm tay ngắn trên Dev (mục 3): đăng nhập → màn catalog / partner → tạo đơn nháp Sales — gom vào đợt kiểm IAM.
