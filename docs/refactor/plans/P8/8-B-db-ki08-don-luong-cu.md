# 8-B — DB: chặn chuyển Owner sai (KI-08), dọn luồng onboarding cũ, FK thành viên (KI-03)

> Phase: P8 · Trạng thái: Plan 📝 (chi tiết, 2026-10-11) | Làm 🔄 (mục 1, 2 xong; S2–S4 chưa) | Review ⬜
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
3. **Đợt kiểm IAM** (Claude chạy khi bạn đồng ý từng bước):
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
