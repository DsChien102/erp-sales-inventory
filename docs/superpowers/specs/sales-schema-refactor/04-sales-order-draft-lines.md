# Bảng 4 — `sales.sales_order_draft_lines`

> Trạng thái: ✅ Đã chốt (2026-09-23) — **giữ bảng; cột phẳng = dữ liệu người dùng nhập, `pricing_preview` = hiển thị + kết quả tính giá; bỏ `updated_at`**
> Nguyên tắc chung: [README.md](README.md) · Plan: [2026-09-23-sales-refactor-04-sales-order-draft-lines](../../plans/2026-09-23-sales-refactor-04-sales-order-draft-lines.md)

## 1. Bối cảnh

Dòng hàng của đơn nháp. Chỉ dùng trong `20260830007_sales_draft_rpcs.sql`:

- `_write_draft_lines`: mỗi lần save/update nháp → xoá hết dòng cũ, chèn lại toàn bộ.
- `_draft_payload`: dựng mảng `lines` (sắp theo `line_sequence`) và `total_amount_minor` (tổng `line_total_minor`).

Trước refactor, `_draft_payload` chỉ đọc JSON `pricing_preview` (19 key, chứa cả dữ liệu người dùng nhập); các cột phẳng `product_id`, `product_unit_id`, `quantity_micros`, `manual_unit_price_input_minor`, `manual_discount_amount_input_minor`, `line_note` chỉ ghi, không ai đọc → dữ liệu nhập lưu hai nơi.

## 2. Quyết định

| # | Điểm | Quyết định |
|---|---|---|
| ① | Bảng | **Giữ** |
| ② | Cột phẳng trùng JSON | **(a) Mỗi thứ lưu một nơi.** Cột phẳng là nguồn đúng cho dữ liệu người dùng nhập; thêm `manual_discount_basis_points integer`. `pricing_preview` (đổi thành `not null`) chỉ còn 11 key hiển thị + kết quả tính giá. `_draft_payload` ghép cột + JSON thành đúng các key cũ |
| ③ | `updated_at` luôn = `created_at` (dòng không bao giờ được update) | **Bỏ** |
| ④ | Tên `manual_unit_price_input_minor`, `manual_discount_amount_input_minor` | **Giữ tên** |

Phân chia sau refactor:

| Nơi lưu | Key JSON trả app | Nguồn |
|---|---|---|
| Cột | `line_id` | `id` |
| Cột | `product_id`, `product_unit_id`, `quantity_micros` | cột cùng tên |
| Cột | `manual_unit_price_minor` | `manual_unit_price_input_minor` |
| Cột | `manual_discount_minor` | `manual_discount_amount_input_minor` |
| Cột (mới) | `manual_discount_basis_points` | `manual_discount_basis_points` |
| Cột | `note` | `line_note` |
| `pricing_preview` | `product_sku`, `product_name`, `unit_code`, `unit_name`, `applied_unit_price_minor`, `line_total_minor`, `list_unit_price_minor`, `pricing_source_code`, `pricing_warning_codes`, `pricing_blocking_codes`, `needs_revalidation` | JSON |

Contract JSON (`lines[]`) không đổi key; key có giá trị null vẫn bị lược bỏ như trước (`jsonb_strip_nulls`).

Cột sau refactor: `id`, `tenant_id`, `sales_order_draft_id`, `line_sequence`, `product_id`, `product_unit_id`, `quantity_micros`, `manual_unit_price_input_minor`, `manual_discount_amount_input_minor`, `manual_discount_basis_points`, `line_note`, `pricing_preview`, `created_at`.

## 3. Ghi nhận (không sửa)

- `line_id` đổi sau mỗi lần lưu (xoá + chèn lại); app nhận id mới trong kết quả trả về nên chưa lỗi.
- Không FK sang Catalog (`product_id`, `product_unit_id`): đúng nguyên tắc tách module.

## 4. Phụ thuộc

Sau plan 3 (cùng sửa `_draft_payload` trong `007`; tìm theo nội dung). Test `sales_order_draft_sql_contract_test.dart` là baseline fail → không sửa.
