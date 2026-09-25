# Bảng 3 — `sales.sales_order_drafts`

> Trạng thái: ✅ Đã chốt (2026-09-23) — **giữ bảng, bỏ 5 cột không dùng, tách `preview_snapshot` thành cột rõ ràng**
> Nguyên tắc chung: [README.md](README.md) · Plan: [2026-09-23-sales-refactor-03-sales-order-drafts](../../plans/2026-09-23-sales-refactor-03-sales-order-drafts.md)

## 1. Bối cảnh

Đơn nháp để mở lại sau. RPC trong `20260830007_sales_draft_rpcs.sql`: `save_sales_order_draft`, `update_sales_order_draft`, `cancel_sales_order_draft`, `list_sales_order_drafts`, `get_sales_order_draft_for_restore`; helper `_draft_payload` (dựng JSON trả app), `_write_draft_lines`, `_draft_preview_snapshot`. `finalize_sales_order` (`20260830008`) chuyển nháp sang `converted`.

JSON trả app (key giữ nguyên): `draft_id`, `version`, `status`, `store_id`, `currency_code`, `saved_at`, `saved_by_actor_id`, `customer`, `order_note`, `pricing_preview_token`, `needs_revalidation`, `lines`, `total_amount_minor`; restore trả thêm `saved_at`, `saved_by_actor_id` ở cấp ngoài.

## 2. Quyết định

| # | Điểm | Quyết định |
|---|---|---|
| ① | Bảng | **Giữ** |
| ② | `sales_shift_id` không ai ghi/đọc (tính năng ca bán chưa làm) | **Bỏ**. Thêm lại khi làm tính năng ca bán. `sales_orders` xét ở bảng 5 |
| ③ | `expires_at`, `expired_at` không ai ghi/đọc | **Bỏ**. Giữ giá trị `expired` trong CHECK (khớp `SalesDraftStatus` Dart và spec US-07) |
| ④ | `converted_at` (finalize ghi), `cancelled_at` (cancel ghi), không ai đọc | **Bỏ**. Nháp kết thúc thì không sửa nữa → `updated_at` là thời điểm kết thúc |
| ⑤ | `preview_snapshot` jsonb gộp 5 thứ | **Tách cột**: `customer_snapshot jsonb`, `pricing_preview_token text`, `needs_revalidation boolean not null default false`, `updated_by_user_id uuid not null`. Bỏ `saved_at` (luôn = `updated_at`). Helper `_draft_preview_snapshot` thay bằng `_draft_customer_snapshot(p_customer jsonb)` (chỉ chuẩn hoá khách) |

Ánh xạ key JSON (không đổi contract):

| Key | Trước | Sau |
|---|---|---|
| `saved_at` | `preview_snapshot->>'saved_at'`, dự phòng `updated_at` | `updated_at` |
| `saved_by_actor_id` | `preview_snapshot->>'saved_by_actor_id'`, dự phòng `created_by_user_id` | `updated_by_user_id` |
| `customer` | `preview_snapshot->'customer'` | `customer_snapshot` |
| `pricing_preview_token` | `preview_snapshot->>'pricing_preview_token'` | `pricing_preview_token` |
| `needs_revalidation` | `preview_snapshot->>'needs_revalidation'` | `needs_revalidation` |

`updated_by_user_id` được ghi ở save, update, cancel, finalize (người thay đổi gần nhất).

Cột sau refactor: `id`, `tenant_id`, `store_id`, `created_by_user_id`, `updated_by_user_id`, `customer_partner_id`, `customer_snapshot`, `status`, `currency_code`, `note`, `pricing_preview_token`, `needs_revalidation`, `version`, `created_at`, `updated_at`.

### Khác biệt chấp nhận

- Nháp đã huỷ: `saved_at` trong JSON trả về của `cancel_sales_order_draft` trở thành thời điểm huỷ (trước đây giữ thời điểm lưu cuối), `saved_by_actor_id` là người huỷ. Danh sách/restore chỉ đọc nháp `active` nên không ảnh hưởng màn hình.

## 3. Ghi nhận (không sửa)

- Danh sách nháp sắp theo `created_at` trong khi màn hình hiện `saved_at`; nháp cũ vừa sửa không nổi lên đầu (quyết định UX, để sau).
- Chưa có index `(tenant_id, store_id, status, created_at)` cho danh sách; thêm khi dữ liệu lớn.
- Chưa có RPC hết hạn nháp (`ExpireSalesOrderDraft`); khi làm thì thêm cột hạn nếu cần.

## 4. Phụ thuộc

Sau plan 1 và 2 (cùng sửa `007` và `finalize_sales_order` trong `008`; tìm theo nội dung). Test `sales_order_draft_sql_contract_test.dart` đang fail sẵn ở `setUpAll` (baseline) → không sửa.
