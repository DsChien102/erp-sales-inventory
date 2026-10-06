# Bảng 14 — `iam.password_reset_operations` + `iam.password_reset_email_throttle`

> Trạng thái: ✅ Đã chốt (2026-09-17) — **giữ nguyên 2 bảng**; dọn phần chuyển tiếp cũ trong migration + sửa tài liệu domain model
> Nguyên tắc chung: [README.md](README.md) · Plan: [2026-09-17-iam-refactor-14-password-reset](../../plans/2026-09-17-iam-refactor-14-password-reset.md)

## 1. Bối cảnh

Luồng đặt lại mật khẩu bằng mã 6 số do IAM quản lý, 2 cửa vào dùng chung `password_reset_operations`:
- Đã đăng nhập: `begin_password_reset_operation`, `resend_password_reset_operation`, `verify_password_reset_code`, `mark_password_reset_operation_verified`, `mark_password_reset_operation_completed`, `get_password_reset_operation`.
- Chưa đăng nhập: `begin_password_reset_operation_by_email`, `resend_password_reset_operation_by_email`, `verify_password_reset_code_by_email`, `complete_password_reset_operation_by_email`.

## 2. Quyết định

| # | Điểm | Quyết định |
|---|---|---|
| ① | Cấu trúc 2 bảng (`operation_id`, `user_id`, `status`, `attempt_count`, `code_hash`, `expires_at`, `resend_available_at`, `created_at`, `updated_at`; `email_hash`, `last_requested_at`, `window_count`) | **Giữ nguyên** |
| ② | Khối `DO` xoá bảng "hình dạng cũ" + `alter table … add column if not exists code_hash` trong `20260811021_iam_password_reset_operations.sql` | **Xoá** (chỉ phục vụ nâng cấp DB cũ; reset từ đầu luôn no-op) |
| ③ | `01-domain-model.md` ghi "không lưu code" | **Sửa**: lưu bản băm (`code_hash`), không lưu mã gốc |
| ④ | Không có dọn phiên hết hạn / bản ghi throttle | **Ghi nhận, để sau** |
