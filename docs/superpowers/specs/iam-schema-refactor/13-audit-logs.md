# Bảng 13 — `iam.audit_logs`

> Trạng thái: ✅ Đã chốt (2026-09-17) — **giữ bảng, chỉ bỏ `created_at`**
> Nguyên tắc chung: [README.md](README.md) · Plan: [2026-09-17-iam-refactor-13-audit-logs](../../plans/2026-09-17-iam-refactor-13-audit-logs.md)

## 1. Bối cảnh

Bảng audit dùng chung tenant + platform, dựng lại ở `20260826004_iam_audit_logs_v2_rebuild.sql`. Ghi duy nhất qua `iam.append_audit_log` (16 lời gọi); đọc qua `search_tenant_audit_logs_v2`, `get_tenant_audit_log`, `search_platform_audit_logs`, `get_platform_audit_log`.

## 2. Quyết định

| # | Điểm | Quyết định |
|---|---|---|
| ② | `occurred_at` và `created_at` luôn bằng nhau (không lời gọi nào truyền `p_occurred_at`); không RPC nào đọc `created_at` | **Bỏ `created_at`** |
| ③ | `activity_code`, `title_snapshot` luôn = `event_code` | **Giữ** — khung cho Audit Activity mapping (ghi chú trong migration) |
| ④ | `event_category` suy ra từ `event_code` | **Giữ** — lưu sẵn để lọc theo nhóm |
| ⑤ | Cột phẳng `actor_display_name_snapshot`, `actor_context_label`, `target_display_name_snapshot`, `target_secondary_identifier` trùng `actor_snapshot` / `target_snapshot` | **Giữ** — cột phẳng cho tìm kiếm, jsonb cho chi tiết |
| ⑥ | Tên `source_event_refs` (thực chất lưu before/after) | **Giữ** |

Các cột khác giữ nguyên. Key JSON đầu ra `created_at` / `timestamp` hiện đã lấy từ `occurred_at` → không đổi contract.

## 3. Phụ thuộc

Độc lập với các plan khác (chỉ sửa `create table` và `append_audit_log` trong `20260826004`); thực hiện sau plan 12 theo thứ tự chung.
