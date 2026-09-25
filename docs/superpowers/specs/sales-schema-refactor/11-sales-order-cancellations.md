# Bảng 11 — `sales.sales_order_cancellations`

> Trạng thái: ✅ Đã chốt (2026-09-23) — **giữ bảng; sửa FC-17 thành `unique (tenant_id, sales_order_id)`; giữ 8 giá trị `status`; bỏ 11 cột**
> Nguyên tắc chung: [README.md](README.md) · Plan: [2026-09-23-sales-refactor-11-sales-order-cancellations](../../plans/2026-09-23-sales-refactor-11-sales-order-cancellations.md)

## 1. Bối cảnh

Phiếu huỷ đơn. Ghi duy nhất: `confirm_sales_order_cancellation` (định nghĩa cuối `20260904001`) — insert một lần với `status = 'confirmed'`, không có câu update nào trong repo. Đọc: `get_sales_order_cancellation` (`011`), timeline (`010`), precheck huỷ, 6 chỗ ở đổi trả (chặn `COMPETING_CANCELLATION` bằng `status in (…)`). `feature/theme8` không dùng.

Domain model mô tả luồng nhiều bước (Model B, đã hoãn); thực tế hiện chỉ có "xác nhận là xong".

## 2. Quyết định

| # | Điểm | Quyết định |
|---|---|---|
| ① | Bảng | **Giữ** |
| ② | FC-17: partial unique index `sales_order_cancellations_one_completed … where status = 'completed'` không bao giờ có tác dụng (status luôn `confirmed`) | **Thay** bằng constraint `sales_order_cancellations_order_unique unique (tenant_id, sales_order_id)` — mỗi đơn tối đa 1 phiếu huỷ (huỷ là trạng thái cuối) |
| ③ | `status` 8 giá trị, thực tế chỉ `confirmed` | **Giữ nguyên** CHECK 8 giá trị (khớp domain; các chỗ lọc vẫn đúng) |
| ④ | Không ai ghi: `completed_by_user_id`, `blocker_codes`, `completed_at`, `blocked_at`, `failed_at` | **Bỏ cả 5**; timeline bỏ `completed_by_user_id` khỏi `coalesce` |
| ⑤ | Trùng / chỉ ghi: `version` (luôn 1), `confirmed_by_user_id` (= `requested_by_user_id`), `required_impacts_snapshot` (= `precheck_snapshot->'impacts'`), `requested_at` (= `created_at`), `updated_at` (không bao giờ update) | **Bỏ cả 5**; chỗ đọc `confirmed_by_user_id` (timeline, `get_sales_order_cancellation`) đổi sang `requested_by_user_id` |
| ⑥ | `idempotency_key` + unique — trùng `idempotency_records`; đoạn tra phiếu cũ theo key trong `confirm` không bao giờ tìm thấy (bản ghi chống lặp + phiếu cùng transaction) | **Bỏ** cột + unique + đoạn tra `v_existing` |

Cột sau refactor: `id`, `tenant_id`, `sales_order_id`, `status`, `source_order_version`, `requested_by_user_id`, `reason`, `precheck_snapshot`, `confirmed_at`, `created_at`.

Xoá thêm phần alter cũ trong `005` ngay sau `create table`: `alter table … drop column if exists reason_code` (chỉ phục vụ DB cũ) và partial index FC-17 cũ.

Contract JSON không đổi: `cancelledByActorId` vẫn là người huỷ (trước đây `coalesce(confirmed_by, requested_by)` — hai giá trị luôn bằng nhau).

## 3. Phụ thuộc

Sau plan 10. Plan 1 có test đếm lời gọi `_complete_sales_idempotency` trong `confirm_sales_order_cancellation` (2 lời gọi, một nằm trong đoạn `v_existing` bị xoá) → plan này sửa test plan 1: 15 begin / **20** complete.
