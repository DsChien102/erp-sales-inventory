# Bảng 7 — `sales.sales_order_return_status_projections`

> Trạng thái: ✅ Đã chốt (2026-09-23) — **giữ bảng phụ; bỏ `id`, `sold_quantity_micros`, `returned_quantity_micros`, `version`**
> Nguyên tắc chung: [README.md](README.md) · Plan: [2026-09-23-sales-refactor-07-sales-order-return-status-projections](../../plans/2026-09-23-sales-refactor-07-sales-order-return-status-projections.md)

## 1. Bối cảnh

Bảng phụ (projection) lưu trạng thái trả hàng của đơn để danh sách đơn lọc nhanh; tối đa 1 dòng/đơn.

- Ghi: `confirm_return_exchange` (định nghĩa cuối `20260904001`) — tính lại theo **từng dòng gốc** từ các phiếu `completed` rồi upsert; `complete_return_exchange` (`014`, không còn được gọi — xác nhận đã chuyển thẳng `completed`) cũng upsert.
- Đọc: `list_sales_orders`, `search_sales_orders` (`returnStatus` + lọc "có trả hàng"); `audit_sales_review_invariants` (`006`, `language sql`); `complete_return_exchange` (`for update`).
- `feature/theme8`: chỉ test nhắc tên bảng.

## 2. Quyết định

| # | Điểm | Quyết định |
|---|---|---|
| ① | Bảng | **Giữ** (domain: return status là projection) |
| ② | `id` không ai đọc; khoá thật `(tenant_id, sales_order_id)` | **Bỏ**; PK = `(tenant_id, sales_order_id)` |
| ③ | `sold_quantity_micros`, `returned_quantity_micros` cộng số lượng mọi dòng bất kể đơn vị; chỉ hàm kiểm tra cân đối đọc | **Bỏ**. Nhánh `return_projection_quantity_mismatch` trong `audit_sales_review_invariants` thay bằng `return_projection_status_mismatch` (so `return_status` đã lưu với trạng thái tính lại theo từng dòng gốc) |
| ④ | `version` chỉ tăng, không ai đọc | **Bỏ** |

Cột sau refactor: `tenant_id`, `sales_order_id`, `return_status`, `updated_at`; PK `(tenant_id, sales_order_id)`; giữ CHECK `return_status` và FK sang `sales_orders`.

**Sự kiện `return_exchange_completed.v1` (sửa 2026-09-23 sau rà quy đổi đơn vị):** trước đây `soldQuantityMicros`/`returnedQuantityMicros` cộng `quantity_micros` của mọi dòng bất kể đơn vị (vô nghĩa khi đơn có nhiều đơn vị). Đổi sang **tổng số lượng gốc** (cùng đơn vị cơ sở, cộng được): key mới `soldBaseQuantityMicros` = Σ `sales_order_lines.base_quantity_micros`, `returnedBaseQuantityMicros` = Σ `return_exchange_lines.base_quantity_micros` của dòng trả nguồn gốc thuộc phiếu `completed`. Không có nơi tiêu thụ trên cả 2 nhánh → đổi key được. Giá trị dòng trả đúng sau plan 13 (tính đúng `base_quantity_micros`). Trạng thái trả hàng vẫn so **theo từng dòng bằng `quantity_micros`** (dòng trả cùng đơn vị dòng nguồn — bảng 13 ⑦).

**`complete_return_exchange`** đang tính trạng thái bằng tổng gộp cả đơn (`v_returned >= v_sold`, trộn đơn vị, và đếm cả dòng trả nguồn đổi) → thay bằng cùng CTE theo từng dòng như `confirm_return_exchange` để hàm dự phòng không ghi sai trạng thái.

## 3. Ghi nhận

- Chỉ tính hàng gốc (`original_sales_order_line_id`), không tính hàng đổi vào rồi trả lại — đúng nghĩa "trạng thái trả hàng của đơn gốc".
- `complete_return_exchange` không còn được gọi nhưng vẫn là định nghĩa cuối → plan này sửa upsert trong đó; có xoá hẳn hàm hay không quyết ở **bảng 12**.

## 4. Phụ thuộc

Độc lập với plan 1–6 về nội dung (sửa `005`, `006` audit, `014` complete, `20260904001` confirm). Thứ tự chung: sau plan 6. Giá trị `returnedBaseQuantityMicros` chỉ đúng sau plan 13 (cả hai đều xong trước khi reset DB).
