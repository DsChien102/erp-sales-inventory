# Bảng 14 — `sales.return_exchange_valuations`

> Trạng thái: ✅ Đã chốt (2026-09-23) — **giữ bảng; bỏ `required_settlement_type`, `version`, `calculated_by_user_id`, `confirmed_at`, `updated_at`; bỏ giá trị `superseded`**
> Nguyên tắc chung: [README.md](README.md) · Plan: [2026-09-23-sales-refactor-14-return-exchange-valuations](../../plans/2026-09-23-sales-refactor-14-return-exchange-valuations.md)

## 1. Bối cảnh

Mỗi phiếu đổi trả có đúng 1 bản định giá (FC-08): giá trị trả, giá trị đổi, chênh lệch `exchange − return` (ADR-2, FC-14) và kế hoạch tất toán trong `valuation_details` (ADR-6).

- Ghi: `evaluate_return_exchange_valuation` (`013`, upsert — định giá lại thì ghi đè về `calculated`); `settle_return_exchange_difference` (`013`, cập nhật `settlement_plan`, → `confirmed`); `confirm_return_exchange` (định nghĩa cuối `20260904001`, → `confirmed`).
- Đọc: xác nhận, tất toán, chi tiết đổi trả, tóm tắt trả hàng / thanh toán của đơn. `feature/theme8` không dùng.

## 2. Quyết định

| # | Điểm | Quyết định |
|---|---|---|
| ① | Bảng | **Giữ** |
| ② | `required_settlement_type` — suy ra từ số tiền trong `settlement_plan`, không ai đọc | **Bỏ** cột + CHECK `return_exchange_valuations_settlement_type_check` + khối `case` và biến `v_required_settlement_type` trong `evaluate` |
| ③ | `superseded` không bao giờ được ghi (định giá lại ghi đè) | **Bỏ** khỏi CHECK `status` → `('calculated', 'confirmed')` |
| ④ | Chỉ ghi, không ai đọc: `version`, `calculated_by_user_id`, `confirmed_at`, `updated_at` | **Bỏ cả 4** (xác nhận kiểm tra phiên bản qua `valuation_details.settlement_plan.source_session_version`; phiếu có `confirmed_at` riêng) |

Cột sau refactor: `id`, `tenant_id`, `return_exchange_order_id`, `currency_code`, `return_value_minor`, `exchange_value_minor`, `net_difference_minor`, `status`, `valuation_details`, `calculated_at`, `created_at`.

Contract JSON không đổi (không RPC nào trả các cột bị bỏ).

## 3. Phụ thuộc

Sau plan 13 (cùng sửa `013`). Bản cũ `confirm_return_exchange` trong `014` để nguyên.
