# Bảng 5 — `sales.sales_orders`

> Trạng thái: ✅ Đã chốt (2026-09-23, sửa cùng ngày: **giữ `buyer_tax_snapshot`**) — **giữ bảng, bỏ 7 cột; gộp phần alter cũ vào `create table`**
> Nguyên tắc chung: [README.md](README.md) · Plan: [2026-09-23-sales-refactor-05-sales-orders](../../plans/2026-09-23-sales-refactor-05-sales-orders.md)

## 1. Bối cảnh

Đơn bán đã chốt, nội dung thương mại không sửa. Ghi ở 2 nơi: `finalize_sales_order` (`20260830008`, tạo) và `confirm_sales_order_cancellation` (định nghĩa cuối ở `20260904001`, chuyển `cancelled`). Khoảng 30 hàm đọc (tra cứu, hoá đơn, thanh toán, huỷ, đổi trả).

## 2. Quyết định

| # | Cột | Lý do | Quyết định |
|---|---|---|---|
| 1 | `sales_shift_id` | Không ai ghi/đọc; tính năng ca bán chưa làm (khớp bảng 3) | **Bỏ** |
| 2 | `reference_code` | Không ai ghi/đọc | **Bỏ** |
| 3 | `locked_at`, `locked_by_user_id` | Không ai ghi/đọc; chưa có RPC khoá/mở khoá | **Bỏ** |
| 4 | `buyer_tax_snapshot` | Trên `fix/theme5` không ai ghi/đọc, **nhưng** nhánh `feature/theme8` (hoá đơn điện tử) dùng: draft `017_sales_buyer_invoice_snapshot.sql` ghi (`buyerType`, `legalName`, `taxCode`, `email`, `address` app lấy từ Partner lúc chọn khách), draft `018_sales_einvoice_source_contract.sql` đọc để lập hoá đơn | **Giữ** |
| 5 | `customer_snapshot` | = `sales_context_snapshot->'customer'`; `generate_sales_receipt` đọc; draft `018` (theme8) đọc làm dự phòng tên/MST/SĐT | **Bỏ**; `generate_sales_receipt` đọc `sales_context_snapshot->'customer'`; khi merge theme8 sửa `018` tương tự (key giống hệt) |
| 6 | `pricing_summary_snapshot` | Chỉ ghi; trùng 3 cột tiền | **Bỏ** |
| 7 | `business_time` | Chỉ ghi, = `completed_at` | **Bỏ** |

Giữ (không thay đổi):

- `channel_code` — luôn `'pos'`, không ai đọc; giữ cho đa kênh sau này (spec US-01).
- `lock_status` — app đọc và lọc (`lockStatus`, enum Dart).
- `buyer_tax_snapshot` — dữ liệu người mua cho hoá đơn điện tử (theme8). Trên `fix/theme5` cột luôn `null` cho tới khi merge theme8.
- `tax_amount_minor`, `rounding_amount_minor` — luôn 0; cần cho công thức cân đối.
- `cancelled_at`, `created_at`, `updated_at`, `source_draft_id`, `payment_due_date`, `version` và các cột còn lại.

Gộp khối "SCHEMA EVOLUTION" của bảng này vào `create table` (theo quy ước README): `alter table … add column if not exists payment_due_date` (xoá — cột đã có trong `create table`) và `sales_orders_commercial_balance` (chuyển thành constraint trong `create table`).

Cột sau refactor: `id`, `tenant_id`, `source_draft_id`, `order_code`, `store_id`, `seller_user_id`, `customer_partner_id`, `channel_code`, `currency_code`, `lifecycle_status`, `lock_status`, `version`, `internal_note`, `subtotal_amount_minor`, `discount_amount_minor`, `tax_amount_minor`, `rounding_amount_minor`, `payable_amount_minor`, `sales_context_snapshot`, `buyer_tax_snapshot`, `completed_at`, `cancelled_at`, `payment_due_date`, `created_at`, `updated_at`.

Contract JSON không đổi (hoá đơn: key `customer` trước đây cũng rơi về `sales_context_snapshot->'customer'` khi `customer_snapshot` rỗng; khách vãng lai vẫn là `null`).

## 3. Ghi nhận / để sau

- **Dòng hàng lưu 2 nơi** (`sales_context_snapshot->'lines'` và bảng `sales_order_lines`): chi tiết đơn + hoá đơn đọc snapshot, đổi trả đọc bảng (snapshot chỉ là dự phòng không bao giờ chạy). → Quyết định ở **bảng 6**.
- Thuế/làm tròn luôn 0 — chờ tính năng thuế.
- Khoá đơn: `lock_status` luôn `unlocked` cho tới khi có RPC khoá/mở khoá; khi làm thì thêm lại cột thời điểm/người khoá.

## 4. Phụ thuộc

Sau plan 1–4 (plan 1–3 cùng sửa `finalize_sales_order`; tìm theo nội dung).

**Đồng bộ khi merge `feature/theme8`** (ghi ở README "Việc phát sinh"):
- `_drafts/017_sales_buyer_invoice_snapshot.sql` là bản sao đầy đủ `finalize_sales_order`: áp lại thay đổi finalize của plan 1 (helper chống lặp, xoá update thừa), plan 2 (bộ đếm bỏ `updated_at`), plan 3 (nháp `converted` bỏ `converted_at`, ghi `updated_by_user_id`) và plan 5 (insert bỏ `business_time`, `customer_snapshot`, `pricing_summary_snapshot`); giữ ghi `buyer_tax_snapshot`.
- `_drafts/018_sales_einvoice_source_contract.sql`: `v_order.customer_snapshot ->> 'displayName' | 'taxCode' | 'phoneNumber'` → `v_order.sales_context_snapshot -> 'customer' ->> …`.
