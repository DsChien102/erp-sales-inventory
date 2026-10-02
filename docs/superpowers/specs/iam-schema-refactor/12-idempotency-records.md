# Bảng 12 — nhóm bảng chống lặp (idempotency) → `iam.idempotency_records`

> Trạng thái: ✅ Đã chốt (2026-09-17) — **phương án A1: gộp 8 bảng thành 1, xoá phần theo dõi bước onboarding**
> Nguyên tắc chung: [README.md](README.md) · Plan: [2026-09-17-iam-refactor-12-idempotency-records](../../plans/2026-09-17-iam-refactor-12-idempotency-records.md)

## 1. Hiện trạng

8 bảng cùng một chức năng: lệnh gửi lặp với cùng mã chống lặp → trả lại kết quả cũ, không thực thi lần hai; cùng mã khác nội dung → `IDEMPOTENCY_CONFLICT` (nơi có hash).

| Bảng | Lệnh |
|---|---|
| `onboarding_operations` | `create_tenant_onboarding` |
| `tenant_invitation_operations` | `create_tenant_invitation` |
| `tenant_invitation_mutate_operations` | `resend_tenant_invitation`, `revoke_tenant_invitation` |
| `tenant_invitation_token_operations` | `accept_invitation`, `decline_invitation` |
| `tenant_activation_operations` | `activate_tenant` |
| `ownership_transfer_operations` | `transfer_platform_tenant_ownership` |
| `platform_user_lifecycle_operations` | `suspend_platform_user` |
| `provisioning_owner_reinvite_operations` | `reinvite_provisioning_owner` |

**Phần chết:** 6 cột theo dõi bước của `onboarding_operations` (`operation_id`, `status`, `completed_steps`, `failed_step`, `tenant_id`, `owner_user_id`) luôn giữ giá trị mặc định; kết quả onboarding không trả `operation_id`; RPC `get_tenant_onboarding_operation` / `retry_tenant_onboarding_operation` không dùng được và không màn hình nào gọi. Onboarding chạy trong 1 transaction nên không có trạng thái "làm dở".

## 2. Quyết định

### Bảng mới

```sql
create table iam.idempotency_records (
  operation        text        not null,
  scope_id         text        not null,
  idempotency_key  text        not null,
  payload_hash     text,
  result           jsonb,
  created_at       timestamptz not null default now(),
  primary key (operation, scope_id, idempotency_key)
);
```

Helper:
- `iam._idempotency_find(p_operation, p_scope_id, p_key, p_payload_hash) returns iam.idempotency_records` — không thấy → dòng toàn `null`; thấy mà `p_payload_hash` khác (khi cả hai không null) → `IDEMPOTENCY_CONFLICT`.
- `iam._idempotency_store(p_operation, p_scope_id, p_key, p_payload_hash, p_result) returns void`.

### Ánh xạ (giữ nguyên phạm vi và hành vi cũ)

| Lệnh | `operation` | `scope_id` | `payload_hash` | `result` |
|---|---|---|---|---|
| `create_tenant_onboarding` | `tenant.onboard` | `platform` | `null` | kết quả |
| `create_tenant_invitation` | `tenant.invitation.create` | `tenant_id` | md5 hiện tại | kết quả |
| `resend_tenant_invitation` | `tenant.invitation.resend` | `invitation_id` | md5 hiện tại | kết quả |
| `revoke_tenant_invitation` | `tenant.invitation.revoke` | `invitation_id` | md5 hiện tại | kết quả |
| `accept_invitation` | `tenant.invitation.accept` | `token_hash` | md5 hiện tại | kết quả |
| `decline_invitation` | `tenant.invitation.decline` | `token_hash` | md5 hiện tại | kết quả |
| `activate_tenant` | `tenant.activate` | `tenant_id` | md5 hiện tại | kết quả |
| `transfer_platform_tenant_ownership` | `tenant.ownership.transfer` | `platform` | fingerprint hiện tại | `null` |
| `suspend_platform_user` | `platform_user.suspend` | `platform` | fingerprint hiện tại | `null` |
| `reinvite_provisioning_owner` | `tenant.owner.reinvite` | `platform` | `null` | kết quả |

### Xoá (A1)
- 8 bảng cũ (không chuyển dữ liệu — dữ liệu chống lặp ngắn hạn, DB dev).
- RPC `get_tenant_onboarding_operation(uuid)`, `retry_tenant_onboarding_operation(uuid, text)`.
- Dart: query/command/handler/validator/DTO/status get + retry onboarding operation, method port/gateway, phần Fake + scenario `onboardingPartialFailure`, `onboardingResumeOk`, test liên quan; chạy lại codegen.

### Khác biệt chấp nhận
- Không FK theo tenant (bảng cũ `tenant_activation_operations` cascade khi xoá tenant) — bản ghi thừa vô hại.
- `restore_platform_user` vẫn không chống lặp (giữ hành vi hiện tại).

## 3. Phụ thuộc

Chạy sau plan bảng 1–8 (sửa tiếp các file owner mà các plan trước đã sửa). Bảng mới + helper đặt tại `20260811005` (thay chỗ tạo `platform_user_lifecycle_operations`); các câu tạo 7 bảng còn lại bị xoá tại migration gốc.
