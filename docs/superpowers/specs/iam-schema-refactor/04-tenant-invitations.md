# Bảng 4 — `iam.tenant_invitations`

> Trạng thái: ✅ Đã chốt (2026-09-17)
> Nguyên tắc chung: [README.md](README.md) · Plan: [2026-09-17-iam-refactor-04-tenant-invitations](../../plans/2026-09-17-iam-refactor-04-tenant-invitations.md)

## 1. Bảng có cần giữ không

**Giữ** — aggregate `TenantInvitation`, dùng chung cho lời mời staff và lời mời owner (Design A). Chỉ IAM dùng.

## 2. Cột → quyết định

| Cột | Quyết định |
|---|---|
| `id`, `tenant_id`, `invitee_email`, `initial_role_id`, `status`, `token_hash`, `expires_at`, `status_changed_at`, `version`, `created_at`, `updated_at` | Giữ |
| `invited_by_membership_id` | Giữ; **thêm FK → `memberships(id)` `on delete set null`** (④a). Thực tế luôn là membership của owner (chỉ owner có `tenant.member.invite`) hoặc `null` với lời mời owner do admin tạo |
| `accepted_membership_id` | **Giữ nguyên** (②c) |
| `target_membership_id` | **Giữ nguyên** (②c) |
| `delivery_correlation_id`, `last_sent_at` | Giữ (lần gửi hiện hành + thời gian chờ resend; khác `email_delivery_outcomes`) |
| `revoke_reason` | **Đổi tên → `status_reason`** (③a) — lý do của lần đổi trạng thái gần nhất (hiện chỉ thu hồi ghi); key payload audit `revoke_reason` giữ nguyên |
| `is_owner` | Giữ |
| `given_name`, `family_name`, `phone` | Giữ — **🔒 để giai đoạn hybrid** (đang trùng với profile tạm; bỏ profile tạm thì đây là nơi lưu duy nhất) |

Index giữ nguyên toàn bộ (`token_hash` unique, pending email unique, tenant/status/expires, accepted membership unique, target membership).

## 3. Sửa lỗi mời lại người đã bị gỡ (⑥)

**Lỗi:** `create_tenant_invitation` luôn `insert` membership tạo sẵn; người từng bị gỡ còn dòng cũ → vi phạm `memberships_tenant_user_unique` → không tạo được lời mời.

**Quyết định:** dùng lại dòng cũ (không tạo `user_id` mới — `user_id` là tài khoản đăng nhập, dùng chung mọi tổ chức).

Khi tạo lời mời, sau khi xác định `v_invitee_user_id`:
- Nếu có membership của người đó trong tenant với `removed_at is not null` → `update` dòng đó: `is_active = true`, `removed_at = null`, `role = <role lời mời>`, `is_owner = false`, `status_changed_at = now`, `version + 1`, `updated_at = now`; dùng `id` của dòng này làm `target_membership_id`.
- Ngược lại → `insert` như hiện tại.

Hành vi hybrid giữ nguyên (membership ở trạng thái đang làm ngay khi mời; từ chối/thu hồi/hết hạn thì unwind gỡ lại). Lịch sử lần bị gỡ trước còn trong audit.

## 4. Phụ thuộc

Chạy sau plan bảng 3 (mô hình `is_active` + `removed_at`; `create_tenant_invitation` trong file owner `20260916005` đã được plan 3 sửa).
