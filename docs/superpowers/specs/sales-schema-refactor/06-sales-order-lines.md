# Bảng 6 — `sales.sales_order_lines`

> Trạng thái: ✅ Đã chốt (2026-09-23) — **giữ bảng, bỏ `pricing_snapshot` + `tax_snapshot`; bảng là nguồn dòng hàng duy nhất (bỏ `lines` khỏi `sales_orders.sales_context_snapshot`)**
> Nguyên tắc chung: [README.md](README.md) · Plan: [2026-09-23-sales-refactor-06-sales-order-lines](../../plans/2026-09-23-sales-refactor-06-sales-order-lines.md)

## 1. Bối cảnh

Dòng hàng bất biến của đơn đã chốt. Chỉ `finalize_sales_order` ghi. 12 hàm đọc: chi tiết đơn, hoá đơn, đổi trả (returnable/precheck/start/update/evaluate/confirm/complete), `audit_sales_review_invariants`. Nhánh `feature/theme8`: draft `018_sales_einvoice_source_contract.sql` đọc bảng để lập hoá đơn điện tử.

Trước refactor, dòng hàng lưu **2 nơi**: bảng này và `sales_orders.sales_context_snapshot->'lines'` (cùng nội dung `lineId`, `product`, `unit`, `quantityMicros`, `unitPrice`, `discountTotal`, `lineTotal`). Chi tiết đơn (`lines`) và hoá đơn đọc snapshot; đổi trả + hoá đơn điện tử đọc bảng; `get_returnable_order_lines` và `start_return_exchange` chỉ đọc snapshot làm dự phòng khi `product_snapshot` thiếu tên (không xảy ra — finalize luôn ghi tên).

## 2. Quyết định

| # | Điểm | Quyết định |
|---|---|---|
| ① | Bảng | **Giữ** |
| ② | `pricing_snapshot` (chỉ ghi `unitPriceMinor`, `lineTotalMinor` — trùng 2 cột tiền), `tax_snapshot` (không ai ghi/đọc) — không ai đọc trên cả 2 nhánh | **Bỏ cả 2** |
| ③ | Dòng hàng lưu 2 nơi | **Bảng là nguồn duy nhất.** Finalize bỏ key `lines` khỏi `sales_context_snapshot` (còn `store`, `seller`, `customer`). Helper mới `sales._sales_order_lines_payload(p_tenant_id uuid, p_sales_order_id uuid, p_currency_code text)` dựng mảng `lines` từ bảng; `get_sales_order_detail` và `generate_sales_receipt` dùng helper. Bỏ đoạn dự phòng đọc snapshot trong `get_returnable_order_lines` (2 chỗ) và `start_return_exchange` (1 chỗ) |
| ④ | 2 lỗi ở dòng đổi trả (ghi nhận §3) | Để **bảng 13** |

Giữ: mọi cột còn lại, gồm `gross_amount_minor`, `tax_amount_minor` (luôn 0, cần cho công thức cân đối), `base_quantity_micros`, `product_snapshot`, `product_unit_snapshot`, `line_note`, `created_at`.

Gộp khối "SCHEMA EVOLUTION" của bảng vào `create table`: `sales_order_lines_base_qty_positive`, `sales_order_lines_commercial_balance`.

Contract JSON `lines[]` (chi tiết đơn, hoá đơn) giữ các key cũ; dư thêm `note` và `unit.conversionRateToBase` (Dart đọc theo key → không ảnh hưởng). Hoá đơn đã sinh lưu `receipt_snapshot` riêng → không đổi.

Cột sau refactor: `id`, `tenant_id`, `sales_order_id`, `line_sequence`, `product_id`, `product_unit_id`, `quantity_micros`, `base_quantity_micros`, `unit_price_minor`, `gross_amount_minor`, `discount_amount_minor`, `tax_amount_minor`, `line_total_minor`, `product_snapshot`, `product_unit_snapshot`, `line_note`, `created_at`.

## 3. Ghi nhận — chuyển bảng 13 (`return_exchange_lines`)

- `start_return_exchange` ghi `base_quantity_micros = quantity_micros` (không nhân hệ số quy đổi đơn vị) — sai khi trả theo đơn vị có hệ số ≠ 1.
- `evaluate_return_exchange_valuation` (`013`) đọc `pricing_snapshot ->> 'unit_price_minor'` của dòng đổi trả, nơi ghi dùng `unitPriceMinor`; chỉ là nhánh dự phòng nên chưa gây lỗi.

## 4. Phụ thuộc

Sau plan 1–5 (plan 1–3, 5 cùng sửa `finalize_sales_order`; tìm theo nội dung).

**Đồng bộ khi merge `feature/theme8`:** `_drafts/017_sales_buyer_invoice_snapshot.sql` (bản sao finalize) bỏ `v_normalized_lines` + key `lines` khỏi snapshot, bỏ `pricing_snapshot` khỏi insert `sales_order_lines`. Draft `018` đọc bảng, không cần sửa.
