# Bảng 2 — `sales.sales_order_number_counters`

> Trạng thái: ✅ Đã chốt (2026-09-23) — **giữ bảng, giữ khoá theo cửa hàng, bỏ `updated_at`, sửa comment**
> Nguyên tắc chung: [README.md](README.md) · Plan: [2026-09-23-sales-refactor-02-sales-order-number-counters](../../plans/2026-09-23-sales-refactor-02-sales-order-number-counters.md)

## 1. Bối cảnh

Bộ đếm sinh mã đơn, chỉ dùng trong `sales.finalize_sales_order` (`20260830008`): upsert theo `(tenant_id, store_id, period_key)` với `period_key` = ngày giờ VN dạng `YYYYMMDD`, lấy số trả về ghép `'DH' || YYYYMMDD || lpad(n, 4)`. Quá 9999 đơn/ngày → `CHECKOUT_BLOCKED`. Bộ đếm tăng trong cùng transaction con với việc tạo đơn → đơn lỗi thì số lùi theo, không nhảy số.

Mã khác không dùng bảng này: phiếu đổi trả `DT<số mã đơn>-NN`, giao dịch thanh toán `PMT-<16 ký tự UUID>`.

## 2. Quyết định

| # | Điểm | Quyết định |
|---|---|---|
| ① | Bảng | **Giữ** |
| ② | Khoá có `store_id` trong khi `order_code` chỉ unique theo `(tenant_id, order_code)` | **Giữ nguyên** — chưa làm tính năng cửa hàng (khớp quyết định 2026-09-08). Ghi known issue ở README |
| ③ | Tên `next_value` thực chất lưu số **vừa cấp** | **Giữ tên**, thêm comment giải thích trên cột |
| ④ | `updated_at` chỉ ghi, không ai đọc | **Bỏ** (cột + `updated_at = now()` trong upsert của finalize) |
| ⑤ | Comment `period_key` ghi "yyyymm" (sai) | **Sửa** thành "yyyymmdd theo ngày giờ Asia/Ho_Chi_Minh" |

Cột giữ: `tenant_id`, `store_id`, `period_key`, `next_value`; PK `(tenant_id, store_id, period_key)`.

## 3. Ghi nhận (không sửa)

- **Known issue:** tổ chức có từ 2 cửa hàng, cùng ngày, cả hai cùng cấp số 1 → cùng `DH…0001` → lỗi `sales_orders_code_unique`. Hiện mỗi tổ chức chỉ có 1 cửa hàng (IAM bảng 5) nên chưa xảy ra. Khi làm tính năng cửa hàng: hoặc thêm ký hiệu cửa hàng vào mã đơn, hoặc bỏ `store_id` khỏi khoá.
- Giới hạn 9999 đơn/ngày/cửa hàng: đủ dùng.

## 4. Phụ thuộc

Sửa `20260830005` (bảng) và `finalize_sales_order` trong `20260830008` (file owner duy nhất). Chạy sau plan 1 (plan 1 Task 3 cũng sửa `finalize_sales_order`).
