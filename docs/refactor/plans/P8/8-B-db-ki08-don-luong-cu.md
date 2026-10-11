# 8-B — DB: chặn chuyển Owner sai (KI-08), dọn luồng onboarding cũ, FK thành viên (KI-03)

> Phase: P8 · Trạng thái: Plan 📝 (chi tiết, 2026-10-11) | Làm 🔄 (S1–S4 + app xong 2026-10-11; chờ kiểm trên DB sạch) | Review ⬜
> Gồm việc: 8.4, 8.6. Làm sau 8-C, 8-D (đã xong: không còn `apps/admin` / `modules/iam` gọi RPC cũ). **Push cùng đợt kiểm IAM.**
> Đặc tả: [TH-01](../../../02-yeu-cau/TH-01-to-chuc-va-nguoi-dung.md) BR-07, BR-13, BR-32, BR-35, KI-03, KI-05, KI-08, mục 8.
> Mọi migration mới đặt timestamp **sau `20261009005`** (5 migration P2 chưa push lên Dev).

## 1. Số liệu Dev (đọc 2026-10-11, chỉ `SELECT`)

| Hạng mục | Dev |
|---|---|
| Dữ liệu IAM | **trống**: 0 tổ chức, 0 thành viên, 0 hồ sơ, 0 Platform Admin |
| Thành viên mồ côi / hồ sơ mồ côi / người sở hữu > 1 tổ chức / tổ chức không có Owner | 0 / 0 / 0 / 0 |
| Bảng `onboarding_operations`, `owner_activations` | **không còn** (đã xoá từ trước) |
| Hàm cũ còn trong DB | `create_tenant_onboarding`, `reinvite_provisioning_owner`, `send_activation_invitation`, `resend_owner_activation`, `get_tenant_readiness`, `activate_tenant`, `bootstrap_owner`, `platform_identity_create_pending_user_for_onboarding`, `resolve_or_create_platform_user_for_onboarding`, `_unwind_provisioning_owner_membership`, `_cleanup_pending_profile_on_auth_user` |
| Trigger trên `auth.users` | `trg_cleanup_pending_profile` (cũ) — 2 trigger của 2-B1 chưa push |
| `iam.tenants.status` | `CHECK (status IN ('provisioning','active','suspended','closed'))` (text) |
| `iam.platform_user_profiles.status` | **enum** `iam.platform_user_status` = `pending_activation`, `active`, `suspended` |
| FK của `iam.memberships` | `role → role_definitions(code)`, `tenant_id → tenants(id)`; **không có** `user_id → auth.users` |

**Hàm đang dùng còn tham chiếu luồng cũ** (tìm theo nội dung hàm trên Dev):

| Thứ cũ | Hàm đang dùng tham chiếu |
|---|---|
| `_unwind_provisioning_owner_membership` | `accept_invitation`, `decline_invitation`, `inspect_invitation_token`, `revoke_tenant_invitation` |
| `'provisioning'` | các hàm trên + `get_platform_tenant`, `has_permission` (chú thích), `search_platform_tenants`? (kiểm) |
| `'pending_activation'` | `get_my_platform_user_profile`, `update_my_platform_user_profile`, `_platform_user_effective_status` |
| `_unwind_staff_precreate_membership` | `accept_invitation`, `decline_invitation`, `revoke_tenant_invitation` — **giữ** (luồng lời mời nhân viên, không thuộc onboarding cũ) |
| `activate_tenant`, `bootstrap_owner` | chỉ xuất hiện trong chú thích của `_mutate_membership_status`, `get_session_context` (kiểm lại khi chép) |

Dev trống nên dọn dữ liệu là thừa trên Dev, nhưng migration **vẫn phải an toàn** khi có dữ liệu (Prod, P10).

## 2. Sửa migration (theo [quy tắc migration](../../PLAN.md#quy-tắc-migration-chốt-2026-10-11): sửa thẳng file gốc, không tạo file ghi đè)

Sau khi sửa: **reset Dev** (`supabase db reset --linked`, hỏi trước) rồi push lại toàn bộ — Dev gần như trống nên không mất gì. Bước dọn dữ liệu cũ của bản plan trước **bỏ** (DB dựng lại từ đầu không có dữ liệu `provisioning` / giữ chỗ).

### S1 — KI-08 (giữ cách sửa tại chỗ của phiên trước)

- `20260811012_iam_platform_transfer_ownership.sql`: giữ bản đã sửa trong working tree (2 kiểm `OWNER_TARGET_INVALID`, `OWNER_TARGET_ALREADY_OWNER`). Thêm dòng `-- 8-B (2026-10-11): KI-08` vào header.
- Giữ `supabase/tests/iam_transfer_ownership_other_owner.sql`; app (`ChangeOwnerCubit`) đã có.

### S2 — Gộp các bản ghi đè mới của P2 (chưa áp ở đâu)

| File ghi đè | Gộp vào | Sau đó |
|---|---|---|
| `20261009005_iam_accept_invitation_reactivate_removed.sql` (KI-02) | Thân `accept_invitation` trong `20260916006_iam_patch_accept_invitation_default_store_scope.sql` | Xoá file `…005` + dòng REGISTRY |
| Đoạn `iam._audit_event_category` trong `20261009001_iam_create_tenant_for_owner.sql` | Thêm `'iam.tenant.created'` vào hàm gốc ở `20260826004_iam_audit_logs_v2_rebuild.sql` | Xoá đoạn đó khỏi `…001` (giữ `_create_tenant_for_owner`) |
| `iam.enqueue_outbox_message` trong `20261009003_iam_email_jobs.sql` | **Ngoại lệ, giữ nguyên**: hàm gốc sinh bằng `format()` cho mọi schema trong `20260623000001`; tách riêng cho `iam` ở đó phức tạp hơn lợi. Ghi chú lý do trong header `…003` | — |

### S3 — Bỏ luồng onboarding cũ (KI-05)

1. **Xoá định nghĩa** (câu `create function` + `grant` / `revoke` đi kèm) ở **mọi** migration có chúng (`grep -l "function iam.<tên>(" supabase/migrations/*.sql`): `create_tenant_onboarding`, `reinvite_provisioning_owner`, `send_activation_invitation`, `resend_owner_activation`, `get_tenant_readiness`, `activate_tenant`, `bootstrap_owner`, `platform_identity_create_pending_user_for_onboarding`, `resolve_or_create_platform_user_for_onboarding`, `_unwind_provisioning_owner_membership`, `_cleanup_pending_profile_on_auth_user` + trigger `trg_cleanup_pending_profile` (`20260826003`). Migration nào chỉ còn rỗng → xoá file + REGISTRY.
2. **Sửa bản mới nhất** của hàm đang dùng, bỏ nhánh Owner cũ / `provisioning` / `pending_activation`:
   - `accept_invitation` (sau S2: `20260916006`), `decline_invitation`, `revoke_tenant_invitation`, `inspect_invitation_token` — bỏ gọi `_unwind_provisioning_owner_membership`, nhánh `is_owner`; **giữ** `_unwind_staff_precreate_membership`.
   - `get_platform_tenant` (`20260911003`): bỏ trường lời mời Owner / readiness.
   - `get_my_platform_user_profile`, `update_my_platform_user_profile`, `_platform_user_effective_status`: bỏ nhánh `pending_activation`.
   - `search_platform_tenants`: **giữ chữ ký** (app gửi `p_readiness_state`, `p_warning_code` = null), chỉ bỏ xử lý readiness trong thân.
3. **Ràng buộc**: `iam.tenants.status` — sửa câu tạo check gốc thành `('active','suspended','closed')` và default `'active'` (hiện `20260811006` đặt default `'provisioning'`). Bảng `onboarding_operations`, `owner_activations`: xoá câu `create table` gốc (Dev đã không còn).
4. **Enum `iam.platform_user_status`**: sửa câu `create type` gốc (`20260911001`) bỏ `pending_activation` — được vì DB dựng lại từ đầu; sửa luôn các migration cũ có dùng giá trị này (`20260811004` check cũ, `20260826003` index `platform_user_profiles_pending_email_uidx`, cột `email` cho hồ sơ giữ chỗ nếu chỉ phục vụ luồng cũ).

### S4 — FK thành viên + BR-07 ở DB (KI-03)

1. `20260911004_iam_onboarding_owner_membership_with_invitation.sql`: **xoá** câu `alter table iam.memberships drop constraint if exists memberships_user_id_fkey` (FK gốc ở `20260630000001` sẽ còn nguyên). Tương tự kiểm `20260826003` (gỡ FK `platform_user_profiles.user_id`) — xoá câu gỡ FK.
2. Index `memberships_one_owned_tenant_per_user on iam.memberships (user_id) where is_owner and removed_at is null`: thêm vào migration tạo cột `is_owner` / `removed_at` của memberships (`20260811014_iam_tenant_membership_lifecycle.sql`).

### Kịch bản SQL

- `iam_transfer_ownership_other_owner.sql` (có sẵn).
- `iam_legacy_cleanup.sql` (mới, `begin … rollback`): 11 hàm cũ không tồn tại (`to_regprocedure` null); không tạo được tổ chức `provisioning`; FK chặn membership với user không tồn tại; index chặn Owner thứ hai cho cùng user; lời mời nhân viên vẫn chạy (gọi kịch bản 2-B3).
- Kiểm toàn bộ bộ migration trên DB **sạch**: chạy được trên Supabase local (`supabase db reset`) hoặc, nếu chưa có Docker, ngay trên Dev bằng `db reset --linked` (đợt kiểm IAM).

## 3. App (mục 6)

1. `core/session/models/tenant_context.dart`: bỏ `TenantStatus.provisioning` (giá trị lạ từ DB → `active` như hiện tại); `AccessibleTenant.isSelectable` = `status == active`.
2. `features/platform_admin`: bỏ nhãn "Đang thiết lập" và nhánh "không có Thao tác cho provisioning".
3. Test liên quan: bỏ ca `provisioning`.

## 4. Thứ tự làm và push

1. S1 (giữ), S2 (gộp), S3, S4, 2 kịch bản SQL, sửa app (mục 3).
2. `dart analyze`, `flutter test` (`apps/erp`); `grep` 11 tên hàm cũ trong `supabase/migrations` → chỉ còn trong chú thích / `_drafts` / `docs/_legacy`.
3. **Đợt kiểm IAM** (bạn tự làm — reset / push DB không thuộc việc của Claude):
   1. `supabase db reset --linked` trên Dev (xoá sạch, chạy lại toàn bộ migration + `seed.sql`) — kiểm cả bộ migration đã sửa trên DB sạch.
   2. Chạy các kịch bản SQL (`iam_signup_trigger`, `iam_email_jobs`, `iam_accept_invitation_reinvite`, `iam_transfer_ownership_other_owner`, `iam_legacy_cleanup`) bằng `supabase db query --linked -f` (mỗi kịch bản tự `rollback`).
   3. `config push` → secrets + Vault (bạn) → `functions deploy send-email` → `vet45 admin create`.
   4. Kiểm tay TH-01 9.3 kịch bản 1–6.

## 5. Rủi ro / lưu ý

- **Sửa lịch sử migration**: chỉ hợp lệ khi chưa có Prod chạy thật. Prod (`xodvjcaaxtubnkibmrmn`) chưa đụng tới; ở P10 dựng từ bộ migration cuối — **nếu Prod đã có dữ liệu thật** thì phải đổi cách (so lệch schema), kiểm trước P10.
- **Chép hàm dài** (`accept_invitation` ~300 dòng): chỉ bỏ nhánh Owner / `provisioning`; Claude sẽ diff với bản gốc khi review.
- Tìm hàm tham chiếu bằng nội dung có thể dính **chú thích** (`has_permission`, `_mutate_membership_status`, `get_session_context`) — đọc thân hàm, chỉ sửa khi là code.
- `drop function` sai chữ ký sẽ báo lỗi ngay (không âm thầm) → lấy chữ ký từ DB.

## 6. Review

### Ghi chú triển khai trước đó (2026-10-11, phiên khác)

| # | Trạng thái | Chi tiết |
|---|---|---|
| 1 KI-08 | ✅ đúng quy tắc mới (S1) | Đã sửa thẳng `20260811012` — từ 2026-10-11 đây là cách chuẩn; Dev nhận qua `db reset --linked`. Thân hàm và 2 kiểm giữ nguyên; test SQL `iam_transfer_ownership_other_owner.sql` giữ; app (`ChangeOwnerCubit`) đã có trong commit 8-C |
| 2 Lý do khôi phục | ✅ chốt: bỏ yêu cầu | Giữ RPC không `p_reason`; TH-01 BR-13, US-09.3 FR-03 và `ADMIN-SCREENS` M6c đã sửa (working tree, chưa commit) |

<!-- Claude ghi phần dưới sau khi bạn code xong -->

### Ghi chú triển khai (2026-10-11, S1–S4 + app)

Làm đúng plan, trừ các điểm lệch dưới đây (đều chọn hướng gọn hơn, cần bạn duyệt khi review).

| # | Hạng mục | Làm gì | Lệch plan? |
|---|---|---|---|
| S1 | KI-08 | `20260811012`: thêm dòng header; thân hàm giữ | không |
| S2 | Gộp ghi đè P2 | `accept_invitation` KI-02 gộp vào `20260916006`, xoá `20261009005`; `iam.tenant.created` thêm vào `_audit_event_category` ở `20260826004`, bỏ đoạn đó khỏi `20261009001`; `enqueue_outbox_message` giữ nguyên, ghi lý do ở header `20261009003` | không |
| S3.1 | Xoá 11 hàm + trigger | **Xoá hẳn 8 file**: `20260811023`, `20260820003`, `20260820006`, `20260911004`, `20260911005`, `20260911006`, `20260916004`, `20260916007` (+ `20261009005` ở S2). Cắt hàm khỏi `20260811005/006/016`, `20260826003`, `20260830001`, `20260914001`. REGISTRY cập nhật | **Có**: xoá thêm các bản **bị thay thế** của `accept/decline/revoke/inspect_invitation_token`, `get_platform_user`, `search_platform_users`, `get_my_platform_user_profile`, `get_session_context` để `grep` 11 tên cũ sạch |
| S3.2 | Sửa bản mới nhất | `accept_invitation` (`20260916006`), `decline` / `revoke` (`20260916005`): bỏ nhánh Owner / `provisioning`, giữ `_unwind_staff_precreate_membership`. `inspect_invitation_token` **chuyển bản cuối vào `20260826003`** (vì `20260911005` bị xoá). `get_platform_tenant` (`20260911003`) bỏ `owner_invitation_*`. `search_platform_tenants` (`20260811010`) bỏ nhánh lời mời Owner, giữ chữ ký | **Có** (vị trí `inspect_invitation_token`) |
| S3.2 | `_platform_user_effective_status` | **Xoá hàm** thay vì sửa. `get_platform_user` / `search_platform_users` (`20260911002`) dùng `p.status` và `join` hồ sơ (người chưa xác minh email chưa có hồ sơ nên không hiện). Bỏ khoá `activation_expires_at` | **Có** (màn người dùng nền tảng đã bỏ ở TH-01 US-09.5) |
| S3.2 | `get_session_context` | Bỏ đoạn tự gọi `bootstrap_owner` khi chưa có cửa hàng. Tổ chức nào cũng có cửa hàng mặc định từ `_create_tenant_for_owner`; thiếu thì trả `CONTEXT_INVALID` | **Có** (plan ghi "chỉ trong chú thích", thực tế là code) |
| S3.2 | `accept_invitation` | Bỏ luôn `v_should_be_owner` ("chưa có Owner thì người nhận thành Owner") để không vỡ index một Owner / người | **Có** |
| S3.3 | `tenants.status` | Check ở `20260811002` và `20260811006` còn `active/suspended/closed`, default `active`. `onboarding_operations` chưa từng có `create table`; `owner_activations` hết cùng `20260811023` | không |
| S3.4 | Enum | `20260911001` bỏ `pending_activation`; check ở `20260811004` bỏ; index `platform_user_profiles_pending_email_uidx` bỏ; cột `email` **giữ** (accept / trigger đăng ký dùng) | không |
| S4.1 | FK | Không còn câu gỡ FK `memberships_user_id_fkey` (file `20260911004` xoá) và `platform_user_profiles_user_id_fkey` (cắt khỏi `20260826003`) | không |
| S4.2 | Index | `memberships_one_owned_tenant_per_user_uidx` ở `20260811014` (thêm hậu tố `_uidx` theo quy ước của index bên cạnh) | tên khác chút |
| Test SQL | | `supabase/tests/iam_legacy_cleanup.sql` mới; `iam_transfer_ownership_other_owner.sql` giữ | không |
| App | | `TenantStatus.provisioning` bỏ; `isSelectable` = `active`; nhãn "Đang thiết lập" bỏ; 4 test + `FakeSessionRepository` + `FakeIamScenario.tenantsProvisioning` sửa | không |

**Giữ nguyên, ngoài danh sách của plan** (xem lại ở review): cột `tenant_invitations.is_owner` / `given_name` / `family_name` / `phone` và ràng buộc `tenant_invitations_owner_inviter_chk`; hàm `iam.get_auth_user_snapshot` (chỉ còn tài liệu nhắc, file `20260811016`); nhãn `'provisioning'` trong `tenant_audit_field_catalog.dart` (hiển thị audit lịch sử); mẫu email `activation_invitation`.

**Đã kiểm:** cú pháp toàn bộ file đổi (libpg_query: SQL + PL/pgSQL), mọi `grant` / `revoke` trỏ tới hàm đã định nghĩa trước, `grep` 11 tên cũ + `provisioning` / `pending_activation` / `owner_activations` trong `supabase/migrations` chỉ còn chú thích; `dart analyze` không lỗi mới; `flutter test` toàn bộ `apps/erp`: 1492 pass, 60 fail — 59 đã nằm trong [TEST-BASELINE](../../TEST-BASELINE.md), 1 (`product_measurement_units_e2e_test` `e2e_e04_u02_fr01_01b`) là test catalog dao động, chạy lại riêng thì pass; không có ca IAM / session nào mới hỏng. `verify_migration_policy` còn 4 lỗi cũ ở `20261009003/004` (Touches nhiều dòng), không do đợt này.

**Chưa kiểm:** chạy thật trên DB sạch (bạn tự `db reset --linked` rồi chạy 5 kịch bản SQL, mục 4.3); `iam_legacy_cleanup.sql` chưa từng chạy nên có thể cần chỉnh.

