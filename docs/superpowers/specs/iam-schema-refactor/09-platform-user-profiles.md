# Bảng 9 — `iam.platform_user_profiles`

> Trạng thái: ✅ Đã chốt (2026-09-17) — **giữ nguyên, không có plan**; 1 vấn đề **⏸ pending** chờ team thảo luận
> Nguyên tắc chung: [README.md](README.md)

## 1. Quyết định

**Giữ nguyên toàn bộ** cột, index, RLS, hàm liên quan.

| Cột | Ghi chú |
|---|---|
| `user_id` PK | FK → `auth.users` đã bỏ (placeholder) — 🔒 giai đoạn hybrid |
| `status` enum `pending_activation\|active\|suspended` | `pending_activation` phục vụ placeholder — 🔒 hybrid |
| `email` | Bản sao email Auth, cần cho placeholder — 🔒 hybrid |
| `email_verified` | **⏸ Pending** — xem §2 |
| `last_login_at` | Giữ (trùng `auth.users.last_sign_in_at`, ghi qua `record_my_platform_login`) |
| `given_name`, `family_middle_name`, `phone_number`, `avatar_reference` | Giữ |
| `version`, `created_at`, `updated_at` | Giữ |

Index `platform_user_profiles_pending_email_uidx` — 🔒 hybrid.

## 2. ⏸ Pending: ý nghĩa và cách dùng `email_verified`

**Hiện trạng:**
- Cột thuộc hồ sơ người dùng (1 dòng/người, dùng chung mọi tổ chức).
- Chỉ `accept_invitation` ghi `true`; không nơi nào ghi lại `false` → sau lần chấp nhận lời mời đầu tiên, cột luôn `true`.
- Chỉ `get_platform_tenant` đọc → `owner_email_verified` → app admin hiện cảnh báo **"Email Chủ sở hữu chưa xác minh"** ở chi tiết tổ chức đang thiết lập.
- Màn chi tiết người dùng và readiness dùng `auth.users.email_confirmed_at` (nguồn khác).

**Vấn đề:**
1. Người đã có tài khoản nhưng chưa từng chấp nhận lời mời nào → cảnh báo "email chưa xác minh" dù email Auth đã xác minh.
2. Người đã chấp nhận lời mời ở tổ chức A, được chọn làm chủ tổ chức B nhưng **chưa chấp nhận** lời mời của B → cột vẫn `true` → **không** cảnh báo.

**Hướng đã thảo luận (chưa chốt):**
- Đổi câu chữ cảnh báo thành "Chủ sở hữu chưa kích hoạt tài khoản".
- Đổi nguồn: chưa kích hoạt ⇔ tổ chức còn lời mời `is_owner = true` ở trạng thái `pending` (dữ liệu `tenant_invitations`, không đổi bảng); sửa `get_platform_tenant`.
- Đổi tên field nội bộ `unverifiedEmail` → `ownerNotActivated` (DTO, UI model, gateway, mapper).

User sẽ thảo luận với team rồi quyết định sau.
