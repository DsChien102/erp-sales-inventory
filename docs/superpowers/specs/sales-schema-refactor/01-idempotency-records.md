# Bảng 1 — `sales.idempotency_records`

> Trạng thái: ✅ Đã chốt (2026-09-22) — **giữ bảng, bỏ 6 cột không dùng, bỏ trạng thái `uncertain`, xoá câu update thừa ở checkout**
> Nguyên tắc chung: [README.md](README.md) · Plan: [2026-09-22-sales-refactor-01-idempotency-records](../../plans/2026-09-22-sales-refactor-01-idempotency-records.md)

## 1. Bối cảnh

Bảng chống lặp dùng chung cho mọi lệnh ghi của Sales (ADR-3). Chỉ truy cập qua 2 helper trong `20260830006_sales_shared_rpc_helpers.sql`:

- `sales._begin_sales_idempotency`: khoá `tenant:scope:key` bằng `pg_advisory_xact_lock` → trùng key khác hash thì `IDEMPOTENCY_CONFLICT`; đã có kết quả thì `replay`; chưa có thì chèn `in_progress` và trả `new`.
- `sales._complete_sales_idempotency`: ghi `status` + `result_snapshot`.

16 lệnh gọi: nháp (save/update/cancel), `finalize_sales_order`, `record_sales_payment`, `record_sales_refund`, `void_sales_payment`, `generate_sales_receipt`, `record_sales_receipt_activity`, `confirm_sales_order_cancellation`, đổi trả (`start`/`update`/`cancel`/`confirm`/`complete`), `settle_return_exchange_difference`.

RPC duy nhất đọc thẳng bảng: `sales.get_checkout_result` (app phục hồi khi thanh toán đơn không rõ kết quả). Store/người thao tác lưu trong `result_snapshot` (`storeId`, `requestedByUserId`) để kiểm tra phạm vi.

## 2. Quyết định

| # | Điểm | Quyết định |
|---|---|---|
| ① | Bảng | **Giữ** (một bảng chống lặp dùng chung, ADR-3) |
| ② | `id` (không ai đọc; `begin` trả `record_id` nhưng không nơi gọi nào dùng), `result_type`, `result_id` (chỉ ghi), `correlation_id` (chỉ ghi, sinh ngẫu nhiên), `expires_at` (không ai ghi/đọc), `updated_at` (chỉ ghi) | **(a) Bỏ cả 6 cột.** PK = `(tenant_id, command_scope, idempotency_key)`. Helper bỏ tham số tương ứng: `_begin_sales_idempotency(p_tenant_id, p_command_scope, p_idempotency_key, p_payload_hash)`, `_complete_sales_idempotency(p_tenant_id, p_command_scope, p_idempotency_key, p_status, p_result_snapshot)`. `begin` không trả `record_id` nữa. Sửa mọi chỗ gọi ở định nghĩa cuối |
| ③ | Trạng thái `uncertain` không bao giờ được ghi | **(a) Bỏ** khỏi CHECK, khỏi kiểm tra trong `_complete` và nhánh `when v_record.status = 'uncertain'` trong `get_checkout_result`. JSON trả về không đổi (giá trị này chưa từng được trả ra). Enum Dart `CheckoutResultStatus.uncertain` giữ nguyên (contract app) |
| ④ | `finalize_sales_order` update `result_snapshot` (`storeId`, `requestedByUserId`) trước khi xử lý: mọi nhánh commit đều gọi `complete` ghi đè cùng thông tin | **(a) Xoá** câu update này |

Các cột giữ: `tenant_id`, `command_scope`, `idempotency_key`, `payload_hash`, `status` (`in_progress | succeeded | failed`), `result_snapshot`, `created_at`.

Contract RPC mà app gọi **không đổi** (2 helper là nội bộ, đã `revoke` khỏi `authenticated`).

## 3. Ghi nhận (không sửa)

- `in_progress` gần như không nhìn thấy từ ngoài (khoá transaction + cùng commit với nghiệp vụ); vẫn giữ nhánh xử lý.
- Checkout thất bại gửi lại cùng key → replay `blocked`/`failed`, không chạy lại. Đúng khi app sinh key mới lúc người dùng sửa đơn và thanh toán lại.
- Chưa có job dọn bản ghi cũ; `created_at` giữ lại để làm sau.
- `sales_payment_transactions`, `sales_order_cancellations`, `return_exchange_orders` có `idempotency_key` + unique riêng → xem bảng 10, 11, 12.

## 4. Phụ thuộc

Plan đầu tiên của đợt. Sửa `20260830005` (bảng), `20260830006` (helper) và định nghĩa cuối của 16 hàm gọi helper trong `007`–`010`, `012`–`014`, `20260904001` (4 hàm `record_sales_payment`, `record_sales_refund`, `confirm_sales_order_cancellation`, `confirm_return_exchange` có định nghĩa cuối ở `20260904001`; bản cũ trong `009`/`011`/`014` để nguyên theo quy ước).
