# Bảng 9 — `sales.settlement_obligation_adjustments`

> Trạng thái: ✅ Đã chốt (2026-09-23) — **giữ bảng + mọi cột; chuyển `create table` lên phần SALES SETTLEMENT; thêm kiểm tra cân đối tổng điều chỉnh**
> Nguyên tắc chung: [README.md](README.md) · Plan: [2026-09-23-sales-refactor-09-settlement-obligation-adjustments](../../plans/2026-09-23-sales-refactor-09-settlement-obligation-adjustments.md)

## 1. Bối cảnh

Sổ ghi mỗi lần nghĩa vụ phải thu của đơn đổi sau khi bán, mỗi nguồn một lần:

- Huỷ đơn (`confirm_sales_order_cancellation`, `20260904001`): `−current_payable`.
- Đổi trả (`confirm_return_exchange`, `20260904001`): `exchange − return`.

Cả hai gọi `_apply_settlement_obligation_adjustment` (`006`): chống ghi trùng theo `(tenant_id, source_kind, source_id)` (khác số tiền → lỗi), cộng vào `settlements.post_sale_adjustment_amount_minor`, tính lại settlement. Đọc: `generate_sales_receipt` (khoá theo `id`, trả `adjustmentSources` sắp theo `created_at, id`). `feature/theme8` không dùng.

## 2. Quyết định

| # | Điểm | Quyết định |
|---|---|---|
| ① | Bảng + cột (`id`, `tenant_id`, `sales_order_settlement_id`, `source_kind`, `source_id`, `amount_minor`, `created_at`) | **Giữ nguyên** |
| ② | `id` (chỉ dùng sắp xếp/khoá theo thứ tự) | **Giữ** |
| ③ | `create table` đang nằm trong khối SCHEMA EVOLUTION cuối `005` | **Chuyển** lên phần "SALES SETTLEMENT", ngay sau `sales_order_settlements` (nội dung không đổi) |
| ④ | Chưa kiểm tra `post_sale_adjustment_amount_minor = Σ amount_minor` | **Thêm** nhánh `settlement_adjustment_sum_mismatch` vào `audit_sales_review_invariants` (`006`) |

## 3. Ghi nhận

- `source_id` trỏ phiếu huỷ hoặc phiếu đổi trả tuỳ `source_kind` → không có FK (chấp nhận).

## 4. Phụ thuộc

Sau plan 8 (plan 7 cũng sửa `audit_sales_review_invariants`; nhánh mới chèn ngay trước nhánh `return_projection_status_mismatch`). Không đổi contract RPC.
