# 3-E — Bỏ Platform Admin; tổ chức và tài khoản chỉ còn trạng thái hoạt động

> Phase: P3 · Trạng thái: Plan ✅ | Làm ✅ | Review 🔄
> Quyết định 2026-10-12: bỏ hẳn vai trò Platform Admin (thay phương án A của 3-A). Tổ chức không còn `suspended` / `closed`, tài khoản không còn `suspended`, không còn chuyển Owner.
> Làm **trước khi tiếp tục đợt kiểm IAM** (đợt kiểm dừng ở kịch bản SQL vì lỗi trigger 2-B1, xem 2.4). Xong thì `db reset --linked` một lần cho cả 3-B và 3-E.
> Tài liệu liên quan: [3-A](3-A-quan-tri-to-chuc.md), [3-B](3-B-db-ki08-don-luong-cu.md) (KI-08), TH-01 EP-04, EP-09, ID-09, mục 9.3.

## 1. Mục tiêu

Hệ thống chỉ còn 2 vai: **Owner** và **thành viên**. Mọi tổ chức sinh ra (qua đăng ký) luôn hoạt động; mọi tài khoản luôn hoạt động. Xoá phần app, DB, công cụ, tài liệu chỉ phục vụ Platform Admin hoặc trạng thái bị chặn.

**Giữ nguyên** (không nhầm vì cùng chữ "platform" / "suspended"):

| Giữ | Vì sao |
|---|---|
| Bảng `iam.platform_user_profiles` (bỏ cột `status`) | Hồ sơ của **mọi** tài khoản (tên, SĐT, email đã xác minh) |
| `get_my_platform_user_profile`, `update_my_platform_user_profile`, `record_my_platform_login` | Màn "Tài khoản của tôi" và đăng nhập dùng |
| Trạng thái **thành viên** (`memberships.is_active`, `removed_at`), `deactivate_/reactivate_/remove_membership`, `LAST_OWNER_PROTECTED` | Owner tạm ngừng / loại nhân viên (TH-01 kịch bản 4) |
| `TenantAccessRevokedSignal`, `_recheckMembership`, lý do mất quyền do **membership** | 2-B4: bị loại khi đang dùng |
| Ràng buộc `memberships_one_owned_tenant_per_user_uidx` | Mỗi người 1 tổ chức sở hữu (đăng ký) |
| Trạng thái `active` của **cửa hàng** (`stores.status`), đơn, giá… | Không liên quan tổ chức |

## 2. Hiện trạng (đo 2026-10-12)

### 2.1 DB: chỉ Platform Admin dùng → xoá

Định nghĩa mới nhất theo `REGISTRY.yaml`:

| Đối tượng | Migration |
|---|---|
| Bảng `iam.platform_admins`, `has_platform_permission` | `20260811003_iam_platform_admin_authz` |
| `search_platform_users`, `get_platform_user` (+ bản cũ ở `20260811004`) | `20260911002` |
| `suspend_platform_user` | `20260820002` |
| `restore_platform_user`, `request_platform_password_reset` | `20260811005` |
| Bảng `iam.platform_audit_logs` (tạo ở `005`, `011`, `013`), `_platform_audit_redacted_payload`, `get_platform_audit_log`, `search_platform_audit_logs` | `20260811013`, `20260826004` |
| `search_platform_tenants`, `list_platform_tenant_members` | `20260811010` |
| `get_platform_tenant` | `20260911003` |
| `suspend_/restore_/close_platform_tenant` | `20260811011` |
| `transfer_platform_tenant_ownership` (+ KI-08 của 3-B) | `20260811012` |
| Enum `iam.platform_user_status`, `_is_platform_user_suspended`, `assert_my_platform_access` | `20260911001` |

### 2.2 DB: kiểm trạng thái tổ chức / tài khoản → sửa

| Hàm | Migration mới nhất | Bỏ |
|---|---|---|
| Cột `iam.tenants.status` | `20260630000001_iam_foundation` (tạo), `20260811002` (`tenants_status_chk`) | Cột + ràng buộc |
| `has_permission`, `get_tenant_context`, `switch_tenant_context` | `20260811024` | Nhánh `TENANT_SUSPENDED` / `TENANT_CLOSED`, `_is_platform_user_suspended` (3 chỗ) |
| `get_session_context` | `20260914001` | `_is_platform_user_suspended`, trường `status` tổ chức |
| `list_accessible_tenants`, `list_user_tenants` | `20260811014` | Cột `status` trả về |
| `accept_invitation` | `20260916006` | Kiểm tổ chức tạm ngừng (2-B4), `status = case …` của hồ sơ |
| `can_access_store` | `20260830001` (dòng 89) | `t.status not in ('suspended','closed')` |
| `_tenant_json` / `get_tenant` | `20260811015` | Trường `status` |
| `_create_tenant_for_owner` | `20261009001` | Gán `status = 'active'` khi insert tổ chức |
| `_on_auth_user_confirmed` | `20261009002` | Cột `status` trong insert / `on conflict` hồ sơ — **đồng thời hết lỗi 2.4** |
| Các migration cũ còn nhắc `status` tổ chức trong thân hàm đã bị thay | `20260630000001`, `20260811006/007/009/014`, `20260911001` | Chỉ sửa nếu Postgres báo lỗi khi `db reset` (thân hàm plpgsql cũ không được kiểm cột lúc tạo) |

Kiểm lại sau khi sửa: `git grep -nE "TENANT_SUSPENDED|TENANT_CLOSED|platform_user_status|_is_platform_user_suspended|tenants_status_chk|platform_admins|platform_audit_logs" supabase/` rỗng (trừ `iam_legacy_cleanup.sql` nếu dùng để kiểm "đã xoá").

Chữ `'suspended'` / `'closed'` ở schema `pricing`, `sales` là trạng thái riêng của bảng đó, **không** đụng.

### 2.3 App

| Nhóm | File |
|---|---|
| Feature xoá hẳn | `lib/features/platform_admin/**`, `test/features/platform_admin/**` |
| Lối vào / guard | `core/router/app_router.dart` (3 route `/more/platform/**`), `route_guard.dart` (G7, ngoại lệ G5 cho admin), `session_refresh.dart`, `core/di/injection.dart`, `more_page.dart` (mục "Quản trị nền tảng"), `no_organization_page.dart` (nút admin), `dashboard_page.dart:294` |
| Session | `session_state.dart` (`isPlatformAdmin`, `suspendedOrgName`), `session_controller.dart` (`_resolvePlatformAdmin`, nhánh `TenantStatus` 344–363, 567–568, 600–601, 643–658), `session_repository.dart` (`has_platform_permission`), `session_contracts.dart:48` (`platform.*`) |
| Mô hình trạng thái | `core/session/models/tenant_context.dart` (`TenantStatus`, `tenantSuspended`, `tenantClosed` của `TenantContextInvalidationReason`), `accessible_tenant.dart` (`status`, `isSelectable` → luôn chọn được), `features/iam/data/models/tenant_profile.dart` |
| Mã lỗi | `core/errors/app_exception.dart`, `app_error_messages.dart`, `core/iam/iam_codes.dart` (`tenantSuspended`, `tenantClosed`, `platformUserSuspended`; audit `iam.tenant.suspended/restored/closed/ownership_transferred`), `iam_ui_failure_mapper.dart` |
| Đăng nhập | `features/auth/data/auth_repository.dart:31-35, 347` (`assert_my_platform_access`, `PLATFORM_USER_SUSPENDED`) |
| Lời mời | `invitation_acceptance_cubit.dart:461`, `invitation_token_page.dart:278` (câu "tổ chức tạm ngừng" của 2-B4) |
| Màn chặn ID-09 | `dashboard_page.dart:251-261, 322-329`, `organization_empty_view.dart` (`suspendedOrgName`), `select_organization_bottom_sheet.dart` (nhãn " · Tạm ngừng / Đã đóng", `suspendedOrgName`), `tenant_context/presentation/tenant_context_selector.dart` |
| Hồ sơ tổ chức | `organization_profile_ui_mapper.dart` (`_statusLabel`, `_statusDescription`) → bỏ dòng trạng thái |
| Nhật ký | `tenant_audit_event_catalog.dart:94` (sự kiện tổ chức tạm ngừng…), `tenant_audit_ui_mapper.dart:186` (nguồn "Platform Admin App") |
| Test sửa | `route_guard_test`, `fake_session_repository`, `session_controller_test`, `session_repository_test`, `session_revoked_signal_test`, `auth_repository_sign_in_test`, `invitation_acceptance_cubit_test`, `scripted_invitations`, `no_organization_page_test`, `account_models_test`, `iam_ui_failure_mapper_test`, `organization_empty_view_test`, `select_organization_bottom_sheet_test`, `scripted_iam_repositories`, `iam_feature_access_test`, `tenant_context_blocked_ui_test`, `wgt_e05_tenant_context_test`, `session_contracts_test` |

Lưu ý: chỉ bỏ phần ID-09 của **tổ chức / tài khoản bị chặn**. Trạng thái rỗng "chưa có tổ chức" và "bị loại khỏi tổ chức" của `organization_empty_view` / `SessionController` giữ nguyên.

### 2.4 Lỗi trigger 2-B1 (phát hiện khi kiểm 2026-10-12)

`_on_auth_user_confirmed` (`20261009002:43-46`): `set status = case … then 'suspended' else 'active' end` ra kiểu `text`, cột là enum → mọi lần xác minh email đều lỗi `42804`. Bỏ cột `status` (bước 2) làm lỗi này biến mất; không cần sửa riêng.

### 2.5 Công cụ, seed, test SQL

- `tools/vet45_env`: lệnh `admin create|grant|list` (`bin/vet45_env.dart` 139–150, 765…), `lib/platform_admin_service.dart`, `lib/platform_admin_command_args.dart`, `test/platform_admin_service_test.dart`; `lib/supabase_admin_client.dart` chỉ còn `platform_admin_service` dùng → xoá nếu đúng vậy (kiểm `lib/vet45_env.dart` export).
- `supabase/seed.sql`: khối tạo admin mẫu (insert `auth.users` + `iam.platform_admins`).
- `supabase/tests/iam_transfer_ownership_other_owner.sql`: xoá.
- `supabase/tests/iam_legacy_cleanup.sql`: dòng 59 (`insert … status 'provisioning'`), 66 (`platform_user_status`), 102, 116 → đổi thành kiểm "cột `iam.tenants.status` không còn" và bỏ phần enum.
- `supabase/tests/iam_signup_trigger.sql`: dòng 54, 91, 194 bỏ điều kiện `status`.

## 3. Thay đổi (tóm tắt)

| Nơi | Hành động |
|---|---|
| ~20 migration IAM | Sửa tại chỗ / xoá đối tượng (quy tắc migration); xoá file nếu chỉ còn rỗng + dòng `REGISTRY.yaml` |
| `apps/erp/lib/features/platform_admin`, test tương ứng | Xoá |
| ~25 file app ngoài feature, ~18 file test | Sửa theo 2.3 |
| `tools/vet45_env` | Xoá lệnh `admin` |
| `supabase/seed.sql`, `supabase/tests/*` | Sửa / xoá theo 2.5 |
| Tài liệu | Claude sửa sau khi plan được duyệt (bước 6) |

## 4. Các bước

### Bước 1 — DB: xoá đối tượng của Platform Admin (2.1)

Trong từng migration ở 2.1: xoá `create table` / `create or replace function` / `grant` / `revoke` / `comment` của đối tượng. Migration nào chỉ còn rỗng (vd `20260811010`, `20260811011`, `20260811012`, `20260811013`, `20260911003`, `20260820002`) → xoá file + dòng trong `REGISTRY.yaml`. `20260811004` giữ phần `create table iam.platform_user_profiles` (bỏ cột `status`).

### Bước 2 — DB: bỏ trạng thái (2.2)

1. `20260630000001`: bỏ cột `status` của `iam.tenants`. `20260811002`: bỏ `tenants_status_chk`.
2. `20260811004` / `20260911001`: bỏ cột `status` của `platform_user_profiles`, enum `platform_user_status`, `_is_platform_user_suspended`, `assert_my_platform_access` (cả file `20260911001` nếu chỉ còn những thứ này).
3. Sửa các hàm ở bảng 2.2 (bản mới nhất). Hàm trả `table (… status text …)`: bỏ cột khỏi `returns table` → cần `drop function` trước `create` nếu migration cũ đã tạo chữ ký khác (đã có mẫu trong repo: xem cách `20260914001` tạo lại `get_session_context`).
4. `20261009001` / `20261009002`: bỏ `status` khỏi insert tổ chức / hồ sơ.

Kiểm cú pháp cục bộ trước khi reset: `supabase db reset` (local) nếu có Docker, hoặc nhờ Claude chạy kiểm cú pháp (libpg_query).

### Bước 3 — App

1. Xoá `lib/features/platform_admin`, `test/features/platform_admin`; gỡ import / route / DI.
2. `SessionState`: bỏ `isPlatformAdmin`, `suspendedOrgName`. `SessionController`: bỏ `_resolvePlatformAdmin`, nhánh chọn tổ chức theo `TenantStatus`, nhánh `TENANT_SUSPENDED/CLOSED`. `SessionRepository`: bỏ `hasPlatformPermission`.
3. Guard: bỏ G7, `_isPlatformArea`, ngoại lệ admin ở G5. `session_refresh.dart` chỉ nghe `authStatus`, `hasNoOrganization`.
4. Mô hình: xoá `TenantStatus`, `tenantStatusFromWire`, hai lý do `tenantSuspended/tenantClosed`, field `status` ở `AccessibleTenant`, `TenantProfile`, `TenantContext.tenantStatus`; `isSelectable` → bỏ (mọi tổ chức chọn được).
5. Mã lỗi, mapper, nhật ký: theo 2.3.
6. Đăng nhập: bỏ gọi `assert_my_platform_access` và nhánh `PLATFORM_USER_SUSPENDED`.
7. Màn: bỏ ID-09 (tổ chức / tài khoản bị chặn) ở dashboard, bottom sheet, empty view; bỏ dòng trạng thái ở Hồ sơ tổ chức; bỏ mục "Quản trị nền tảng" ở tab Thêm và nút admin ở `/no-organization`.
8. Sửa test ở 2.3.

### Bước 4 — Công cụ, seed, test SQL (2.5)

### Bước 5 — Kiểm tra

```bash
git grep -nE "isPlatformAdmin|platform_admin|TenantStatus|TENANT_SUSPENDED|TENANT_CLOSED|PLATFORM_USER_SUSPENDED|suspendedOrgName|has_platform_permission|assert_my_platform_access" -- apps tools supabase
# chỉ còn: iam_legacy_cleanup.sql (kiểm đã xoá)
cd apps/erp && dart analyze lib test && flutter test
dart test tools/vet45_env
```

### Bước 6 — Tài liệu (Claude)

TH-01 (EP-09, ID-09, US-04.2 phần tổ chức bị chặn, BR liên quan, mục 9.3 kịch bản 5–6, KI-08), `LUONG-UNG-DUNG.md` (G7, tab Thêm), `LUONG-DANG-KY-XAC-MINH-EMAIL.md`, `ADMIN-SCREENS.md` (ghi "bỏ toàn bộ, 2026-10-12"), `SCOPE.md`, `CHECKLIST.md`; 3-A ghi chú "phần app bị thay bởi 3-E"; 3-B bỏ mục KI-08; PLAN.md.

### Bước 7 — Commit

`refactor(iam): remove platform admin role and tenant/account blocked states (3-E)`. Rồi `supabase db reset --linked` và tiếp đợt kiểm IAM (kịch bản SQL còn 4 file).

## 5. Kiểm tra

- [x] Lệnh grep bước 5 sạch (trừ `iam_legacy_cleanup.sql` khẳng định đã xoá).
- [ ] `supabase db reset` (local hoặc `--linked`) chạy hết migration không lỗi. Máy này không có Docker; chưa chạy `--linked` (cần hỏi trước).
- [ ] 4 kịch bản SQL (`iam_signup_trigger`, `iam_email_jobs`, `iam_accept_invitation_reinvite`, `iam_legacy_cleanup`) không raise.
- [x] `apps/erp`: analyze không lỗi mới; `flutter test` **1.399 đạt / 59 lỗi** (mốc 3-D: 1.494 / 59). Số đạt giảm vì xoá test `platform_admin`; không có lỗi mới.
- [x] `tools/vet45_env`: chỉ còn fail có sẵn `config_init_test`.
- [ ] Tay: tab Thêm không còn "Quản trị nền tảng"; `/more/platform/organizations` về `/`; chọn tổ chức không còn nhãn trạng thái.

## 6. Rủi ro / lưu ý

- Mất khả năng chặn một cửa hàng hoặc chuyển Owner từ hệ thống; cần thì sửa thẳng DB. Ghi vào TH-01 phần "Ngoài phạm vi".
- Bỏ cột `status` làm đổi kiểu trả về của vài RPC: chạy hết test app và `db reset` để bắt chỗ sót.
- Hàm plpgsql cũ (bị thay sau) vẫn nhắc `t.status` thì Postgres không báo lỗi lúc tạo — chỉ bản **mới nhất** quan trọng. `language sql` thì có kiểm cột lúc tạo → sẽ báo khi reset.
- Việc lớn, nên commit riêng; tag `v-legacy-arch` vẫn còn bản cũ.

## 7. Review

Code đã làm theo plan (2026-10-12). Analyze không error mới. `flutter test`: 1.399 đạt / 59 lỗi (không lỗi mới so với 3-D). `dart test tools/vet45_env`: chỉ `config_init_test` có sẵn. GitNexus `detect_changes` không thấy diff (chỉ mục lệch so với working tree). Chưa `db reset` / kịch bản SQL vì không có Docker và chưa được phép `--linked`.
