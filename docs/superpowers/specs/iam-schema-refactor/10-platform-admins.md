# Bảng 10 — `iam.platform_admins`

> Trạng thái: ✅ Đã chốt (2026-09-17) — **giữ nguyên, không có plan**
> Nguyên tắc chung: [README.md](README.md)

## 1. Quyết định

**Giữ nguyên toàn bộ.**

| Cột | Ghi chú |
|---|---|
| `user_id` PK, FK → `auth.users` on delete cascade | Admin luôn có tài khoản Auth thật (không dính placeholder) |
| `created_at` | Mốc cấp quyền admin |

- Dữ liệu vận hành cố định: thêm admin bằng CLI `vet45 admin` (`tools/vet45_env`) qua service role; không có RPC/màn hình trong app.
- Chỉ `iam.has_platform_permission` đọc: có tên trong bảng → mọi quyền `platform.*` (interim).
- RLS bật không policy + grant `select` cho `authenticated` (thừa nhưng vô hại) — giữ nguyên.

## 2. Phát hiện liên quan — khoá tài khoản nền tảng không có hiệu lực

Không thuộc cấu trúc bảng này; ghi lại để quyết định riêng.

`iam.suspend_platform_user` (định nghĩa mới nhất `20260820002_iam_platform_user_suspend_state_changed_fix.sql`) chỉ đổi `platform_user_profiles.status = 'suspended'` và `version`:
- Không nơi nào kiểm tra trạng thái này: đăng nhập (Auth, `SignInTenantUser`, `SignInPlatformAdmin`), `has_permission`, `has_platform_permission`, `get_session_context`.
- Không ban trên Supabase Auth (`banned_until`), không thu hồi phiên đăng nhập đang có.
- Lý do khoá (`p_reason`) không được lưu (chỉ nằm trong fingerprint idempotency); không ghi audit; `restore_platform_user` cũng không ghi audit.

→ Người bị khoá (kể cả admin nền tảng) vẫn đăng nhập và thao tác bình thường; chỉ màn admin hiện "Tạm ngừng".

Spec TH-01 yêu cầu: *"Suspend thành công làm User mất access theo identity policy"*, *"Suspend/restore phải ghi privileged Audit"*, mã lỗi `PLATFORM_USER_SUSPENDED`.

### Quyết định sửa (2026-09-17) — bug, làm trong đợt refactor

Gộp vào [plan bảng 8](../../plans/2026-09-17-iam-refactor-08-owner-flag-checks.md) (Task 2–3, sửa tại file owner; helper mới đặt cuối `20260911001`). Bảng không đổi.

- Helper `iam._is_platform_user_suspended(user_id)`.
- `has_permission`, `has_platform_permission` trả `false` cho người bị tạm ngừng.
- `get_session_context` / `switch_tenant_context` ném `PLATFORM_USER_SUSPENDED`; `get_tenant_context` trả invalidation `identityInactive` + `blocked_error_code = PLATFORM_USER_SUSPENDED`.
- `suspend_platform_user`: không cho tự tạm ngừng chính mình (`VALIDATION_ERROR`); ghi audit `iam.platform_user.suspended` kèm `reason`. `restore_platform_user`: ghi audit `iam.platform_user.restored`. Đăng ký 2 mã sự kiện (nhóm `security`).
- RPC mới `iam.assert_my_platform_access()`; `LoginAuditAuthenticator` gọi sau khi đăng nhập → bị tạm ngừng thì đăng xuất + `IamBlockedException(PLATFORM_USER_SUSPENDED)`.
- Thông báo (admin + ERP): *"Tài khoản của bạn đã bị tạm ngừng. Vui lòng liên hệ quản trị viên."*
- **Ngoài phạm vi (để sau):** ban trên Supabase Auth + thu hồi phiên (cần Auth Admin API qua worker); lưu lý do vào hồ sơ (hiện chỉ trong audit).
