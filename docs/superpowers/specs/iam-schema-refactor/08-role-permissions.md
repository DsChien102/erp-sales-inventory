# Bảng 8 — `iam.role_permissions`

> Trạng thái: ✅ Đã chốt (2026-09-17) — **bảng giữ nguyên**; sửa 4 hàm lệch quy tắc owner
> Nguyên tắc chung: [README.md](README.md) · Plan: [2026-09-17-iam-refactor-08-owner-flag-checks](../../plans/2026-09-17-iam-refactor-08-owner-flag-checks.md)

## 1. Quy tắc phân quyền hiện tại (chốt với user)

- **Mọi role** (`staff`, `accountant`, `warehouse`, `store_owner`) **có quyền như nhau** khi làm nghiệp vụ.
- Chỉ membership **`is_owner = true`** (chủ sở hữu tenant, tối đa 1) có quyền quản trị tổ chức: mời người, đổi role, gỡ/tạm ngưng thành viên, sửa thông tin tổ chức…
- **Role `store_owner` chỉ là một vai trò công việc**, không mang quyền chủ sở hữu; gán được qua lời mời như role khác. Chuyển quyền sở hữu **không** đổi role.

Quy tắc khớp `iam.has_permission` hiện tại (owner mọi quyền; non-owner bị chặn `tenant.*` / `iam.*`).

## 2. Bảng `role_permissions` — giữ nguyên làm khung nền

| Cột | Ghi chú |
|---|---|
| `role` text, `permission` text, PK `(role, permission)` | Không FK; không thêm FK |

- Không migration nào seed; chỉ `supabase/seed.sql` (dev) có 2 dòng cho `staff`.
- `has_permission` không đọc bảng; session context đọc bảng để điền mảng `permissions`; app `IamSession.hasPermission` bỏ qua mảng (`_role != null || …`).
- Khi làm tính năng phân quyền theo role: seed quyền, `has_permission` tra bảng, bỏ bypass ở `IamSession`, cân nhắc bảng `permission_definitions` (domain model).

## 3. Sửa 4 hàm coi role `store_owner` như chủ sở hữu

| Hàm | Lệch | Sửa |
|---|---|---|
| `assign_member_role` | Caller có role `store_owner` (không `is_owner`) được đổi role; chặn `LAST_OWNER_PROTECTED` theo role | Caller phải `is_owner`; **bỏ** khối `LAST_OWNER_PROTECTED` (đổi role không ảnh hưởng quyền sở hữu) |
| `get_session_context` | Role `store_owner` được tự tạo cửa hàng và nhận danh sách quyền kiểu chủ | Chỉ `is_owner` |
| `bootstrap_owner` | Chỉ cho role `store_owner` tạo cửa hàng mặc định | Chỉ `is_owner` |
| `activate_tenant` | Khoá dòng owner theo `is_owner` **hoặc** role `store_owner` | Chỉ `is_owner` |

Không đổi chữ ký RPC, output, Dart, UI.

## 4. Gộp thêm: bug "Tạm ngừng người dùng"

Plan bảng 8 gồm thêm Task 2–3 (SQL tại file owner + Dart) sửa bug tạm ngừng người dùng không có hiệu lực — chi tiết quyết định ở [bảng 10 §2](10-platform-admins.md).

## 5. Phụ thuộc

Chạy sau plan bảng 6 (sửa tiếp các file owner `20260914001`, `20260916007`, `20260820005` mà plan 3 và 6 đã sửa).
