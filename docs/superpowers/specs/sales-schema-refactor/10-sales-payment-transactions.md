# Bảng 10 — `sales.sales_payment_transactions`

> Trạng thái: ✅ Đã chốt (2026-09-23) — **giữ bảng; xoá `void_sales_payment` + giá trị `reversal`/`voided`; bỏ 8 cột; gộp alter cũ vào `create table`**
> Nguyên tắc chung: [README.md](README.md) · Plan: [2026-09-23-sales-refactor-10-sales-payment-transactions](../../plans/2026-09-23-sales-refactor-10-sales-payment-transactions.md)

## 1. Bối cảnh

Sổ giao dịch thu/hoàn chỉ thêm (không có câu update nào). Settlement tính lại từ các dòng `confirmed`.

- Ghi (định nghĩa cuối): `finalize_sales_order` (`008`), `record_sales_payment` + `record_sales_refund` (`20260904001`), `settle_return_exchange_difference` (`013`), `void_sales_payment` (`009`).
- Đọc: `_recompute_sales_settlement`, `get_sales_order_payment_transactions`, timeline, hoá đơn, `audit_sales_review_invariants`, `record_sales_refund` (kiểm tra số còn hoàn được).
- `feature/theme8`: chỉ draft `017` (bản sao finalize).

**Void:** domain model ghi quyết định 2026-09-09 không hỗ trợ huỷ riêng khoản thu/hoàn, SQL xoá "ở draft 025" — draft đó không tồn tại ở nhánh nào. `void_sales_payment` vẫn nằm trong `009`, app không gọi; `sales_rpc_surface_parity_test` đã bỏ qua hàm này như đã xoá; comment trong `record_sales_refund` (`20260904001`) ghi "the void API is removed". Void là nơi duy nhất ghi `transaction_type = 'reversal'`; không nơi nào ghi `status` khác `confirmed`.

## 2. Quyết định

| # | Điểm | Quyết định |
|---|---|---|
| ① | Bảng | **Giữ** |
| ② | Void (quyết định 2026-09-09) | **Xoá** `void_sales_payment` (hàm + revoke/grant + header `009`). Bỏ `reversal` khỏi CHECK `transaction_type` và `type_direction`; bỏ `voided` khỏi CHECK `status`. Bỏ 2 đoạn kiểm tra `reversal` trong `record_sales_refund`. Bỏ dòng skip `void_sales_payment` trong `sales_rpc_surface_parity_test` |
| ③ | `metadata`, `voided_at` (không ai ghi/đọc), `confirmed_at` (= `occurred_at`), `confirmed_by_user_id` (= `initiated_by_user_id`), `updated_at` (bảng không bao giờ update) | **Bỏ cả 5** |
| ④ | `transaction_code` (`'PMT-'`/`'RXC-'`/`'RXR-'` + UUID, không ai đọc) | **Bỏ** (kèm unique `sales_payment_tx_code_unique`) |
| ⑤ | `idempotency_key` + unique — trùng vai trò `idempotency_records` | **Bỏ** (kèm unique `sales_payment_tx_idempotency_unique`); mọi lệnh ghi giao dịch đã chạy qua `idempotency_records` |
| ⑥ | `payment_method_snapshot`, `external_reference` — dữ liệu người dùng nhập, chưa hiển thị | **Giữ** |

Giữ `status` (`pending | confirmed | failed` — chờ tích hợp cổng thanh toán), `source_type`/`source_id` (timeline nối giao dịch với phiếu đổi trả), `related_transaction_id` (hoàn tiền trỏ khoản thu gốc).

Gộp khối SCHEMA EVOLUTION của bảng vào `create table`: unique `(tenant_id, sales_order_settlement_id, id)` (trước là `create unique index sales_payment_tx_tenant_settlement_id_uidx`), FK `sales_payment_tx_related_same_settlement_fk` (thay FK cũ `sales_payment_tx_related_fk` chỉ theo `id`), CHECK `sales_payment_tx_type_direction`.

Cột sau refactor: `id`, `tenant_id`, `sales_order_settlement_id`, `transaction_type`, `direction`, `amount_minor`, `currency_code`, `payment_method_code`, `payment_method_snapshot`, `status`, `source_context`, `source_type`, `source_id`, `related_transaction_id`, `initiated_by_user_id`, `reason_code`, `reason`, `external_reference`, `occurred_at`, `created_at`.

Contract JSON không đổi (không RPC nào trả các cột bị bỏ). Enum Dart (`reversal`, `voided`) giữ nguyên — contract app.

## 3. Phụ thuộc

Sau plan 9. Plan 8 đã bỏ `max(confirmed_at)` trong `_recompute_sales_settlement` (bắt buộc trước plan này). Plan 1 có test đếm lời gọi helper ở `void_sales_payment` → plan này sửa test đó (16→15 begin, 22→21 complete).

**Đồng bộ khi merge `feature/theme8`:** `_drafts/017_sales_buyer_invoice_snapshot.sql` — insert `sales_payment_transactions` trong finalize bỏ `transaction_code`, `confirmed_by_user_id`, `idempotency_key`, `confirmed_at`.
