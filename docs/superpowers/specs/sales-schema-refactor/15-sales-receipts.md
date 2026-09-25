# Bảng 15 — `sales.sales_receipts`

> Trạng thái: ✅ Đã chốt (2026-09-23) — **giữ bảng; bỏ 7 cột (`template_code`, `template_version`, `superseded_by_receipt_id`, `archived_by_user_id`, `archived_at`, `generated_by_user_id`, `created_at`) cùng FK/CHECK/index kèm theo**
> Nguyên tắc chung: [README.md](README.md) · Plan: [2026-09-23-sales-refactor-15-sales-receipts](../../plans/2026-09-23-sales-refactor-15-sales-receipts.md)

## 1. Bối cảnh

Bản chụp hoá đơn có phiên bản. `generate_sales_receipt` (`010`): mỗi lần gọi tạo phiên bản mới `generated`, chuyển các bản `generated` cũ sang `superseded`. `record_sales_receipt_activity` (`010`): ghi hoạt động (bảng 16); với `archived` thì chuyển hoá đơn sang `archived`. Đọc: `get_sales_receipt`, `_sales_receipt_envelope` (JSON `receiptId`, `salesOrderId`, `version`, `status`, `generatedAt`, `document`), chi tiết đơn, `audit_sales_review_invariants`. `feature/theme8` không dùng.

## 2. Quyết định

| # | Điểm | Quyết định |
|---|---|---|
| ① | Bảng | **Giữ** |
| ② | `template_code`, `template_version` — hằng số `'sales_receipt_default'`, `'1'`, không ai đọc | **Bỏ**; khi có nhiều mẫu in thì thêm lại |
| ③ | `superseded_by_receipt_id` — bản thay thế luôn là phiên bản kế tiếp (`receipt_version`); chỉ hàm kiểm tra đọc để kiểm tra chính nó | **Bỏ** cột + FK `sales_receipts_superseded_same_order_fk` + CHECK `sales_receipts_no_self_supersession` + unique index `sales_receipts_tenant_order_id_uidx` (chỉ phục vụ FK) + nhánh `receipt_superseded_cross_order` trong `audit_sales_review_invariants` |
| ④ | `archived_by_user_id`, `archived_at` — trùng dòng hoạt động `archived` (bảng 16 có người + thời điểm) | **Bỏ** |
| ⑤ | `generated_by_user_id` — không ai đọc | **Bỏ** |
| ⑥ | `created_at` — luôn = `generated_at`, không ai đọc | **Bỏ**; giữ `generated_at` |

Cột sau refactor: `id`, `tenant_id`, `sales_order_id`, `receipt_version`, `status`, `content_hash`, `receipt_snapshot`, `generated_at`. Giữ CHECK `status` 3 giá trị, unique FC-09, FK sang đơn, unique `(tenant_id, id)` (đích FK của bảng 16).

Contract JSON không đổi.

## 3. Ghi nhận (không sửa)

- `generate` luôn tạo phiên bản mới kể cả khi nội dung không đổi (không so `content_hash` với bản hiện tại) — nếu app gọi mỗi lần mở/in thì bảng phình. Đổi hành vi là việc nghiệp vụ riêng.

## 4. Phụ thuộc

Sau plan 14. Plan 6 đã sửa `generate_sales_receipt` (key `lines`), plan 1 đã sửa lời gọi helper — tìm theo nội dung. Test cũ `sales_receipt_group_e_sql_contract_test.dart`, `sales_read_group_e_sql_contract_test.dart` (có nhắc `superseded_by_receipt_id`) là baseline fail ở `setUpAll` → không sửa.
