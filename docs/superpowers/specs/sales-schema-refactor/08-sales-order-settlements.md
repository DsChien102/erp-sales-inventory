# Bảng 8 — `sales.sales_order_settlements`

> Trạng thái: ✅ Đã chốt (2026-09-23) — **giữ bảng, bỏ `reconciliation_status`, `last_transaction_at`; giữ `settled_at`**
> Nguyên tắc chung: [README.md](README.md) · Plan: [2026-09-23-sales-refactor-08-sales-order-settlements](../../plans/2026-09-23-sales-refactor-08-sales-order-settlements.md)

## 1. Bối cảnh

Tổng hợp tiền của đơn (1:1 với `sales_orders`). Ghi: `finalize_sales_order` (tạo); `_recompute_sales_settlement` (`006`) tính lại mọi số từ giao dịch đã xác nhận; `_apply_settlement_obligation_adjustment` (`006`) cộng điều chỉnh nghĩa vụ (huỷ đơn, đổi trả) rồi tính lại. Khoảng 25 hàm đọc. `feature/theme8`: chỉ draft `017` (bản sao finalize) ghi.

## 2. Quyết định

| # | Điểm | Quyết định |
|---|---|---|
| ① | Bảng | **Giữ** |
| ② | `reconciliation_status` — luôn `'not_required'`, không ai đọc; đối soát thuộc Receivable (TH-07) | **Bỏ** (cột + CHECK `sales_settlements_recon_status_check`). Khi làm đối soát thì thêm lại |
| ③ | `last_transaction_at` — `max(confirmed_at)` giao dịch, không ai đọc | **Bỏ** (cột + phần tính trong `_recompute_sales_settlement`) |
| ④ | `settled_at` — mốc "khách trả đủ", chưa ai đọc | **Giữ** (mốc nghiệp vụ; tính ngược từ giao dịch rắc rối khi có hoàn/điều chỉnh) |

Các cột khác giữ nguyên (`currency_code`, 7 cột tiền, `payment_status`, `version`, `settled_at`, `created_at`, `updated_at`) cùng các CHECK công thức FC-15, FC-16.

Gộp khối "SCHEMA EVOLUTION" của bảng vào `create table`: cặp `drop/add constraint sales_settlements_payment_status_check` (định nghĩa giống hệt trong `create table`) → xoá.

Contract JSON không đổi (không RPC nào trả 2 cột bị bỏ).

## 3. Ghi nhận (không sửa)

- Danh sách đơn, huỷ đơn, đổi trả lấy settlement bằng `order by version desc limit 1` — thừa vì unique `(sales_order_id)`, vô hại.
- Trả một phần rồi hoàn một phần → `partially_refunded` (ưu tiên hơn `partially_paid`) — hợp lý.

## 4. Phụ thuộc

Sau plan 1–7 (plan 1–3, 5, 6 cùng sửa `finalize_sales_order`; tìm theo nội dung).

**Đồng bộ khi merge `feature/theme8`:** `_drafts/017_sales_buyer_invoice_snapshot.sql` — insert `sales_order_settlements` bỏ `reconciliation_status`, `last_transaction_at`.
