# Bảng 3 — `iam.memberships`

> Trạng thái: ✅ Đã chốt (2026-09-17, cập nhật cùng ngày: đổi mô hình trạng thái sang `is_active` + `removed_at` theo tech lead)
> Nguyên tắc chung: [README.md](README.md) · Plan: [2026-09-17-iam-refactor-03-memberships](../../plans/2026-09-17-iam-refactor-03-memberships.md)

## 1. Bảng có cần giữ không

**Giữ** — aggregate `TenantMembership`; đầu vào `has_permission`, session context, store scope. Module Partner/Catalog/Pricing chỉ đọc `tenant_id` + `user_id` (không đổi). Không policy/view nào phụ thuộc `status`.

## 2. Mô hình trạng thái (quyết định ② — thay thế ②a cũ)

Bỏ cột `status` (`active|inactive|removed`). Trạng thái lưu bằng 2 cột:

```sql
is_active   boolean     not null default true,
removed_at  timestamptz null,
constraint memberships_removed_inactive_chk check (removed_at is null or is_active = false)
```

| `removed_at` | `is_active` | Nghĩa | Mã trạng thái cho app (`status` JSON) |
|---|---|---|---|
| `null` | `true` | Đang làm | `active` |
| `null` | `false` | Tạm ngưng | `inactive` |
| có giá trị | `false` | Đã loại (ngày gỡ = `removed_at`) | `removed` |

- **Giữ tính năng tạm ngưng / kích hoạt lại / gỡ.** Contract JSON không đổi: key `status` vẫn trả `active|inactive|removed`, tính bằng helper `iam._membership_status_code(is_active, removed_at)`. Dart/UI không sửa.
- **Kiểm tra "có quyền vào tổ chức" = `is_active`** (CHECK bảo đảm người đã gỡ luôn `is_active = false`).
- "Còn trong tổ chức" (active hoặc tạm ngưng) = `removed_at is null`.
- `status_changed_at`: **giữ** — mốc lần đổi trạng thái gần nhất (tạm ngưng / kích hoạt lại / gỡ / khôi phục qua lời mời).
- `removed_at`: **giữ** (đảo quyết định ②a cũ) — vừa là cờ "đã gỡ" vừa là ngày gỡ.
- Hai hàm unwind (`_unwind_staff_precreate_membership`, `_unwind_provisioning_owner_membership`) phải ghi `is_active = false`, `removed_at`, `status_changed_at`, `version + 1`.
- Người đã gỡ quay lại qua lời mời: dùng lại dòng cũ (`removed_at = null`, `is_active = true`) — thuộc plan bảng 4 (⑥).

### Quy tắc viết lại SQL

| Cũ | Mới |
|---|---|
| `X.status = 'active'`, `coalesce(X.status, 'active') = 'active'` | `X.is_active` |
| `X.status in ('active', 'inactive')`, `X.status <> 'removed'` | `X.removed_at is null` |
| `X.status = 'removed'` | `X.removed_at is not null` |
| `X.status = 'inactive'` | `X.removed_at is null and not X.is_active` |
| Đọc `X.status` làm giá trị (JSON, biến, lọc) | `iam._membership_status_code(X.is_active, X.removed_at)` |
| `insert … (…, status, …) values (…, 'active', …)` | bỏ cột `status` và giá trị (default `is_active = true`) |

## 3. Cột → quyết định

| Cột | Quyết định |
|---|---|
| `id` PK, `tenant_id` | Giữ |
| `user_id` | Giữ. FK → `auth.users` **🔒 để giai đoạn hybrid** |
| `role` text | Giữ; **thêm FK `role → role_definitions(code)`** (④a) |
| `is_owner` | Giữ; **unique 1 owner / tenant** (⑤a) |
| `status` | **Bỏ** → `is_active` + `removed_at` (②) |
| `is_active` | **Mới** |
| `removed_at` | Giữ (ý nghĩa: đã gỡ + ngày gỡ) |
| `status_changed_at`, `version`, `created_at`, `updated_at` | Giữ |

## 4. Index / constraint

| Đối tượng | Quyết định |
|---|---|
| `memberships_pkey (id)` | Giữ |
| `memberships_tenant_user_unique (tenant_id, user_id)` | Giữ |
| `memberships_tenant_user_active_uidx` (partial theo `status`) | **Xoá** (③a) |
| `memberships_user_id_idx` | Giữ |
| `memberships_status_chk` | Mất cùng cột `status` |
| Mới `memberships_removed_inactive_chk` | `check (removed_at is null or is_active = false)` |
| Mới `memberships_role_fkey` | `foreign key (role) references iam.role_definitions (code)` |
| Mới `memberships_one_owner_per_tenant_uidx` | `unique (tenant_id) where is_owner and removed_at is null` |

## 5. Quy tắc khác đã chốt

- **④ Role:** xoá kiểm tra role `'owner'` còn sót — `(is_owner is true or role = 'owner')` → `is_owner is true`; `role in ('owner', 'store_owner')` → `role = 'store_owner'`. Giữ output `'initial_role_id' = 'owner'` của `inspect_invitation_token`.
- **⑤ Một owner:** owner tạm ngưng vẫn tính, owner đã gỡ không tính. `transfer_platform_tenant_ownership` tách thành 2 câu `update` (gỡ owner cũ trước, gán owner mới sau). Index tạo ngay tại `20260811014` (DB reset rỗng nên không cần guard dữ liệu).

## 6. Phát hiện ghi nhận (ngoài phạm vi)

- `has_permission` không dùng `role` → bảng 8.
- `get_tenant_context` / `switch_tenant_context` không kiểm tra trạng thái membership (member đã gỡ vẫn chuyển được context; bị chặn sau đó ở `has_permission`/session context) → ghi nhận, không sửa đợt này.
- Module khác chặn truy cập theo `tenant_id + user_id`, không xét trạng thái.

## 7. Phụ thuộc

Chạy sau plan bảng 1 & 2 (sửa tiếp các file owner mà plan 1–2 đã sửa). Plan bảng 4 chạy sau plan này.
