# Bảng 5 — `iam.stores`

> Trạng thái: ✅ Đã chốt (2026-09-17) — **giữ nguyên, không có plan**
> Nguyên tắc chung: [README.md](README.md)

## 1. Bối cảnh

`stores` là **khung nền** cho tính năng nhiều cửa hàng sau này. Hiện tại mỗi tổ chức **luôn có đúng 1 cửa hàng** `code = 'default'`, tạo tự động (`_ensure_tenant_default_store`, `bootstrap_owner`). Chưa có RPC/màn hình tạo thêm, đổi tên, tạm ngưng cửa hàng.

## 2. Quyết định

**Giữ nguyên toàn bộ** — cột, constraint, RLS, hàm liên quan.

| Cột | Ghi chú |
|---|---|
| `id`, `tenant_id` | Sales khoá dữ liệu theo `store_id` (không FK chéo schema) |
| `code` | Luôn `'default'`; khoá upsert; snapshot `storeCode` trên hoá đơn Sales |
| `display_name` | Session context trả `active_store_display_name` |
| `status` text `active\|inactive` | Sales helper, Catalog (3 hàm), Pricing (2 hàm) kiểm tra `store.status = 'active'` — không đổi sang boolean |
| `created_at` | Chọn cửa hàng mặc định; chưa cần `updated_at`/`version` |

Constraint giữ: PK `id`, `unique (tenant_id, code)`, `unique (tenant_id, id)` (cho FK cặp từ `membership_store_scopes`). Không thêm ràng buộc "1 cửa hàng / tổ chức".

## 3. Ghi nhận — xử lý khi mở rộng tính năng cửa hàng

- **Tên cửa hàng lệch tên tổ chức:** cửa hàng `default` copy tên tổ chức lúc tạo; đổi tên tổ chức không cập nhật tên cửa hàng.
- **`bootstrap_owner` có thể ghi đè tên thành "My Store":** `get_session_context` gọi `bootstrap_owner(tenant, 'My Store')` khi owner chưa có store scope; upsert `on conflict … set display_name = excluded.display_name` ghi đè tên cửa hàng đã có. Logic này cũng trùng với `_ensure_tenant_default_store` + `_ensure_membership_default_store_scope`.
- **RLS `stores_member_read`** chỉ kiểm tra có dòng membership, không xét `is_active` (member đã gỡ vẫn đọc được danh sách cửa hàng).
