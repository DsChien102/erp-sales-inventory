# Bảng 7 — `iam.role_definitions`

> Trạng thái: ✅ Đã chốt (2026-09-17) — **giữ nguyên, không có plan**
> Nguyên tắc chung: [README.md](README.md)

## 1. Bối cảnh

Danh mục vai trò hệ thống **cố định (seed data)**: tạo và điền bằng migration; không có tính năng/command cho người dùng thêm/sửa/xoá. Muốn thay đổi (thêm role, đổi nhãn, ngừng dùng) → dev viết migration/RPC seed.

| `id` | `code` | `label` |
|---|---|---|
| `a0000000-0000-4000-8000-000000000001` | `staff` | Nhân viên bán hàng |
| `a0000000-0000-4000-8000-000000000002` | `warehouse` | Thủ kho |
| `a0000000-0000-4000-8000-000000000003` | `accountant` | Kế toán |
| `a0000000-0000-4000-8000-000000000004` | `store_owner` | Chủ cửa hàng |

## 2. Quyết định

**Giữ nguyên toàn bộ** cột và constraint:

| Cột | Ghi chú |
|---|---|
| `id` uuid PK | Cố định; `tenant_invitations.initial_role_id` tham chiếu; app gửi khi tạo lời mời |
| `code` text unique | `memberships.role` (FK theo bảng 3), `role_permissions.role` |
| `label` | JSON `role_label` |
| `status` `active\|inactive\|deprecated` | Giữ 3 giá trị (chỉ dev đổi qua migration); `inactive` hiện không dùng |
| `created_at`, `updated_at` | Giữ |

Hai mã định danh (`id` cho lời mời, `code` cho membership) được chấp nhận vì danh mục cố định.

## 3. Chuyển sang bảng 8

Lỗ hổng role `store_owner` được coi như quyền chủ ở RPC (danh sách role gán được có `store_owner`; `assign_member_role` / `get_session_context` kiểm tra `role = 'store_owner'`; chuyển quyền sở hữu không đổi role) **không phải lỗi cấu trúc bảng này** → thảo luận ở [bảng 8 `role_permissions`](08-role-permissions.md).
