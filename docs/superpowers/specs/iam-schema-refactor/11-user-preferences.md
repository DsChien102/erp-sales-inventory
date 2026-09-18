# Bảng 11 — `iam.user_preferences`

> Trạng thái: ✅ Đã chốt (2026-09-17) — **giữ nguyên, không có plan**
> Nguyên tắc chung: [README.md](README.md)

## 1. Quyết định

**Giữ nguyên toàn bộ.**

| Cột | Ghi chú |
|---|---|
| `user_id` PK, FK → `auth.users` on delete cascade | Chỉ ghi khi người dùng đã đăng nhập thật (không dính placeholder) |
| `last_selected_tenant_id` FK → `tenants` on delete set null | Tổ chức chọn gần nhất (LastSelectedTenant) |
| `updated_at` | |

RLS `user_preferences_self`: người dùng chỉ đọc/ghi dòng của mình. Hàm dùng: `get_last_selected_tenant`, `set_last_selected_tenant`, `accept_invitation` (đặt tổ chức vừa chấp nhận làm mặc định).

## 2. Ghi nhận

`set_last_selected_tenant` không kiểm tra người dùng có là member của tổ chức — có thể lưu tổ chức không có quyền. Không lọt quyền (`switch_tenant_context` / `get_session_context` vẫn chặn); app chỉ thử vào rồi hiện màn chọn tổ chức. Migration `20260820007` từng dọn dữ liệu kiểu này. Không sửa đợt này.
