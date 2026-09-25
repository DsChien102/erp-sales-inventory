# Bảng 16 — `sales.sales_receipt_activities`

> Trạng thái: ✅ Đã chốt (2026-09-23) — **giữ bảng; bỏ `channel`, `destination_masked`, `device_context`, `activity_metadata`, `created_at`; `actor_user_id` → `not null`**
> Nguyên tắc chung: [README.md](README.md) · Plan: [2026-09-23-sales-refactor-16-sales-receipt-activities](../../plans/2026-09-23-sales-refactor-16-sales-receipt-activities.md)

## 1. Bối cảnh

Sổ ghi mỗi lần in / chia sẻ / lưu trữ một bản hoá đơn. Ghi duy nhất: `record_sales_receipt_activity` (`20260830010`) — insert `(id, tenant_id, sales_receipt_id, actor_user_id, activity_type, occurred_at)`. Không RPC/màn hình nào đọc. RPC/app chỉ gửi loại hoạt động. `feature/theme8` không dùng.

Bảng 15 đã bỏ `archived_by_user_id`/`archived_at` của hoá đơn vì thông tin đó nằm ở đây → bảng này là nguồn duy nhất cho người/thời điểm lưu trữ.

## 2. Quyết định

| # | Điểm | Quyết định |
|---|---|---|
| ① | Bảng | **Giữ** |
| ② | `channel`, `destination_masked`, `device_context`, `activity_metadata` — không ai ghi/đọc, app không gửi | **Bỏ cả 4**; khi app gửi thông tin chia sẻ/thiết bị thì thêm lại |
| ③ | `created_at` — luôn = `occurred_at` | **Bỏ** (giống bảng 15) |
| ④ | `actor_user_id` nullable nhưng luôn có giá trị (actor đã được `_assert_sales_actor` kiểm tra) | **Đổi sang `not null`** |

Cột sau refactor: `id`, `tenant_id`, `sales_receipt_id`, `actor_user_id`, `activity_type`, `occurred_at`. Giữ CHECK `activity_type` và FK `on delete cascade` sang hoá đơn.

Không đổi hàm nào: câu insert hiện đã chỉ ghi các cột được giữ.

## 3. Ghi nhận

- Chưa có nơi xem lịch sử in/chia sẻ/lưu trữ — cần RPC đọc riêng nếu làm màn lịch sử (tính năng riêng).

## 4. Phụ thuộc

Sau plan 15. Chỉ sửa `20260830005`.
