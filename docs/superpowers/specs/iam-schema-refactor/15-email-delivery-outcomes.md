# Bảng 15 — `iam.email_delivery_outcomes`

> Trạng thái: ✅ Đã chốt (2026-09-17) — **giữ nguyên, không có plan**
> Nguyên tắc chung: [README.md](README.md)

## 1. Bối cảnh

Projection kết quả gửi email hệ thống (lời mời, kích hoạt chủ sở hữu, mã đặt lại mật khẩu). `messaging_worker` gửi qua Resend rồi ghi bằng `iam.record_email_delivery_outcome`; `_invitation_detail_json`, `list_tenant_invitations`, `get_tenant_invitation`, `decline_invitation` đọc `status` theo `correlation_id`; `is_current_tenant_invitation_delivery` bỏ qua kết quả của lần gửi cũ.

## 2. Quyết định

| # | Điểm | Quyết định |
|---|---|---|
| ① | Cột `id`, `tenant_id`, `template_id`, `to_email_masked`, `correlation_id` (unique), `provider`, `provider_message_id`, `status`, `error`, `created_at`, `updated_at` | **Giữ nguyên** |
| ② | Vị trí schema (domain model coi Email delivery thuộc Notification) | **Giữ ở `iam`** — repo chưa có module Notification riêng, chỉ IAM gửi mail. Ghi nhận: tách sang schema/module riêng khi có module khác cần gửi mail |
| ③ | `status` có `bounced` nhưng chưa có nguồn ghi | **Giữ trong CHECK** — chờ webhook Resend |
