# 8-B — DB: chặn chuyển Owner sai (KI-08), dọn luồng onboarding cũ, FK thành viên (KI-03)

> Phase: P8 · Trạng thái: Plan 📝 (chi tiết, 2026-10-11) | Làm 🔄 (mục 2 xong; mục 1 phải làm lại) | Review ⬜
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

## 2. Các migration

### M1 — `20261011001_iam_transfer_owner_ki08.sql` (KI-08, làm lại)

1. `git checkout HEAD -- supabase/migrations/20260811012_iam_platform_transfer_ownership.sql` (trả file đã áp về nguyên bản).
2. Migration mới: `create or replace function iam.transfer_platform_tenant_ownership(...)` = thân hàm **bản đã sửa** (hiện trong working tree trước khi checkout — chép ra trước bước 1), gồm 2 kiểm sau kiểm thành viên:
   - người nhận phải đang hoạt động (`is_active` và `removed_at is null`) → `OWNER_TARGET_INVALID`;
   - người nhận không là Owner tổ chức khác (`is_owner` và `removed_at is null`, `tenant_id <> p_tenant_id`) → `OWNER_TARGET_ALREADY_OWNER`.
3. Giữ quyền như bản gốc (`revoke … from public, anon; grant … to authenticated`).
4. Giữ `supabase/tests/iam_transfer_ownership_other_owner.sql` (sửa phần đầu nếu nó giả định file `20260811012`).
5. App: `ChangeOwnerCubit` đã map `OWNER_TARGET_ALREADY_OWNER` (vào cùng commit 8-C) — không đổi.

### M2 — `20261011002_iam_drop_legacy_onboarding.sql` (KI-05 DB)

Thứ tự trong một migration:

1. **Viết lại hàm đang dùng, bỏ nhánh cũ** (chép bản mới nhất, chỉ bỏ nhánh):
   - `accept_invitation` (bản mới nhất: `20261009005`): bỏ nhánh `v_inv.is_owner` / tổ chức `provisioning` / gọi `_unwind_provisioning_owner_membership`; giữ nhánh nhân viên (`target_membership_id`, `_unwind_staff_precreate_membership`, kích hoạt lại thành viên đã loại).
   - `decline_invitation`, `revoke_tenant_invitation`, `inspect_invitation_token` (bản mới nhất: tìm theo `grep -l "function iam.<tên>(" supabase/migrations | tail -1`): bỏ nhánh Owner / `provisioning`.
   - `get_platform_tenant` (`20260911003`): bỏ trường lời mời Owner / readiness (8-A đã không đọc chúng).
   - `get_my_platform_user_profile`, `update_my_platform_user_profile`, `_platform_user_effective_status`: bỏ nhánh `pending_activation`.
2. **Dữ liệu cũ** (an toàn khi có dữ liệu; Dev = 0 dòng):
   - `update iam.tenants set status = 'closed', status_reason = 'legacy provisioning (8-B)', status_changed_at = now() where status = 'provisioning';` (đóng, không xoá — giữ lịch sử).
   - Lời mời Owner còn chờ: `update iam.tenant_invitations set status = 'revoked' … where is_owner and status = 'pending';`
   - Hồ sơ giữ chỗ: `delete from iam.platform_user_profiles p where p.status = 'pending_activation' and not exists (select 1 from auth.users u where u.id = p.user_id);` còn lại `pending_activation` có user thật → `active`.
   - Thành viên giữ chỗ (user không tồn tại): `delete from iam.memberships m where not exists (select 1 from auth.users u where u.id = m.user_id);` (Dev = 0).
3. **Xoá** trigger `trg_cleanup_pending_profile` + hàm `_cleanup_pending_profile_on_auth_user`; 10 hàm cũ còn lại ở mục 1 (`drop function if exists iam.<tên>(<kiểu tham số>)` — lấy chữ ký bằng `\df` / `pg_get_function_identity_arguments`); `drop table if exists` 2 bảng (đã không còn, giữ cho Prod).
4. **Ràng buộc trạng thái tổ chức**: thay check thành `status in ('active','suspended','closed')`.
5. **Enum `pending_activation`**: Postgres không xoá được giá trị enum. **Giữ giá trị trong enum** (không còn hàm nào tạo ra nó) + thêm `check (status <> 'pending_activation')` trên `platform_user_profiles`. (Dựng lại kiểu enum để làm ở P9 nếu muốn — không cần cho hành vi.)
6. `search_platform_tenants`: tham số `p_readiness_state`, `p_warning_code` **giữ** (8-A gửi `null`; đổi chữ ký sẽ phải sửa app) — chỉ bỏ nhánh xử lý readiness trong thân nếu có.

### M3 — `20261011003_iam_memberships_user_fk.sql` (KI-03, BR-07 ở DB)

1. `alter table iam.memberships add constraint memberships_user_id_fkey foreign key (user_id) references auth.users(id) on delete cascade;` (M2 đã xoá mồ côi).
2. `create unique index if not exists memberships_one_owned_tenant_per_user on iam.memberships (user_id) where is_owner and removed_at is null;` (BR-07; đóng khe hai lần chuyển Owner song song). Trước khi tạo, migration kiểm và `raise exception` rõ ràng nếu còn người sở hữu > 1 tổ chức (Dev = 0).

### Kịch bản SQL

- `supabase/tests/iam_transfer_ownership_other_owner.sql` (có sẵn): chuyển cho người đã là Owner nơi khác → `OWNER_TARGET_ALREADY_OWNER`; cho người không hoạt động → `OWNER_TARGET_INVALID`; hợp lệ → đúng 1 Owner.
- `supabase/tests/iam_legacy_cleanup.sql` (mới, `begin … rollback`): sau M2 không còn 11 hàm cũ (`to_regprocedure` null); tạo tổ chức `provisioning` → bị check chặn; `accept_invitation` / `decline_invitation` / `revoke_tenant_invitation` nhân viên vẫn chạy (gọi lại kịch bản 2-B3 `iam_accept_invitation_reinvite.sql`); FK chặn membership với user không tồn tại; index chặn Owner thứ hai cho cùng user.

## 3. App (mục 6)

1. `core/session/models/tenant_context.dart`: bỏ `TenantStatus.provisioning` (giá trị lạ từ DB → `active` như hiện tại); `AccessibleTenant.isSelectable` = `status == active`.
2. `features/platform_admin`: bỏ nhãn "Đang thiết lập" và nhánh "không có Thao tác cho provisioning".
3. Test liên quan: bỏ ca `provisioning`.

## 4. Thứ tự làm và push

1. Chép thân hàm KI-08 đã sửa ra file tạm → checkout `20260811012` → viết M1.
2. Viết M2, M3, 2 kịch bản SQL, sửa app.
3. `dart analyze`, `flutter test` (`apps/erp`).
4. **Đợt kiểm IAM** (cùng 5 migration P2):
   1. Ghép `20261009001…005` + M1–M3 + các kịch bản SQL (`iam_signup_trigger`, `iam_email_jobs`, `iam_accept_invitation_reinvite`, `iam_transfer_ownership_other_owner`, `iam_legacy_cleanup`) trong `begin … rollback` → `supabase db query --linked -f` (Claude chạy khi bạn đồng ý).
   2. Đạt → `db push` (8 migration) → `config push` → secrets + Vault → `functions deploy send-email`.
   3. `vet45 admin create` trên Dev → kiểm tay P2 (TH-01 9.3 kịch bản 1–4) + 8-A (kịch bản 5–6).

## 5. Rủi ro / lưu ý

- **Chép hàm dài** (`accept_invitation` ~300 dòng): chỉ bỏ nhánh Owner / `provisioning`; Claude sẽ diff với bản gốc khi review.
- Tìm hàm tham chiếu bằng nội dung có thể dính **chú thích** (`has_permission`, `_mutate_membership_status`, `get_session_context`) — đọc thân hàm, chỉ sửa khi là code.
- `drop function` sai chữ ký sẽ báo lỗi ngay (không âm thầm) → lấy chữ ký từ DB.
- Prod (P10) có thể còn dữ liệu cũ: M2 đóng (không xoá) tổ chức `provisioning`, thu hồi lời mời Owner; xem lại số liệu Prod trước khi push ở P10.

## 6. Review

### Ghi chú triển khai trước đó (2026-10-11, phiên khác)

| # | Trạng thái | Chi tiết |
|---|---|---|
| 1 KI-08 | ⚠️ **làm lại theo M1** | Đã sửa thẳng `20260811012` (Dev đã áp → `db push` bỏ qua; Prod dựng mới sẽ khác Dev). Thân hàm và 2 kiểm dùng lại được; test SQL `iam_transfer_ownership_other_owner.sql` giữ; app (`ChangeOwnerCubit`) đã có trong commit 8-C |
| 2 Lý do khôi phục | ✅ chốt: bỏ yêu cầu | Giữ RPC không `p_reason`; TH-01 BR-13, US-09.3 FR-03 và `ADMIN-SCREENS` M6c đã sửa (working tree, chưa commit) |

<!-- Claude ghi phần dưới sau khi bạn code xong -->
