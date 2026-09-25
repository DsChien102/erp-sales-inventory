# Bảng 12 — `sales.return_exchange_orders`

> Trạng thái: ✅ Đã chốt (2026-09-23) — **giữ bảng; giữ `complete_return_exchange` (xoá làm riêng); bỏ 7 cột; `reason` được ghi qua tham số mới của `start`/`update`**
> Nguyên tắc chung: [README.md](README.md) · Plan: [2026-09-23-sales-refactor-12-return-exchange-orders](../../plans/2026-09-23-sales-refactor-12-return-exchange-orders.md)

## 1. Bối cảnh

Phiếu đổi trả. Vòng đời một bước (quyết định 2026-08-17): `start` → `draft`; `update` sửa khi `draft`; `confirm` → `confirmed` rồi `completed` trong cùng lệnh; hoặc `cancel` → `cancelled`.

- Ghi: `start_return_exchange`, `update_return_exchange`, `cancel_return_exchange` (`012`); `confirm_return_exchange` (định nghĩa cuối `20260904001`); `complete_return_exchange` (`014`).
- Đọc: ngữ cảnh/chi tiết đổi trả, `settle_return_exchange_difference` (`013`, ghép theo `correlation_id`), timeline, danh sách, hàm kiểm tra cân đối. `feature/theme8` không dùng.
- App sinh key `return-exchange:<lệnh>:<attemptId>` → key của `update` không bao giờ trùng key của `start`.

## 2. Quyết định

| # | Điểm | Quyết định |
|---|---|---|
| ① | Bảng | **Giữ** |
| ② | `complete_return_exchange` không được gọi trong luồng một bước, nhưng ERP còn đường gọi (nút "Hoàn tất phiếu" khi `processing`, `completeIfReady`, command/handler/gateway Dart) | **Giữ trong đợt này**; ghi "Việc phát sinh": xoá SQL + Dart + đường gọi ERP làm riêng |
| ③ | `reason_code` NOT NULL — luôn `'SESSION'`, không ai đọc | **Bỏ** |
| ③ | `reason` — chưa ai ghi; spec chỉ có lý do theo dòng; app chưa có ô nhập | **Giữ cột**, thêm tham số `reason text default null` (cuối danh sách) cho `start_return_exchange` và `update_return_exchange`, ghi `nullif(btrim(reason), '')`. App chưa gửi → cột tạm `null`; Dart/UI làm sau khi có thiết kế màn hình |
| ④ | `idempotency_key` + unique, `payload_hash` — trùng `idempotency_records`; đoạn tra phiếu cũ theo key trong `start` và 2 nhánh so hash/key trong `update` không bao giờ chạy | **Bỏ** cột + unique + 3 đoạn code chết |
| ⑤ | `operation_type` — tính từ dòng ở `start`/`update`, không ai đọc | **Bỏ** cột + CHECK + 2 khối `case` |
| ⑥ | `causation_id` (không ai đọc), `cancelled_at` (= `updated_at` khi huỷ, không ai đọc) | **Bỏ cả 2**. Tham số `causation_id` của các RPC giữ nguyên (contract) nhưng không lưu |

Cột sau refactor: `id`, `tenant_id`, `sales_order_id`, `status`, `version`, `source_order_version`, `created_by_user_id`, `confirmed_by_user_id`, `completed_by_user_id`, `reason`, `currency_code`, `entry_source`, `source_settlement_version`, `reference_number`, `correlation_id`, `confirmation_decision_snapshot`, `confirmed_at`, `completed_at`, `created_at`, `updated_at`.

**Đổi chữ ký RPC** (thêm tham số có mặc định — app hiện tại gọi bằng tham số đặt tên nên không vỡ): `start_return_exchange(…, reference_decision jsonb, reason text)`, `update_return_exchange(…, reference_decision jsonb, reason text)`; cập nhật `revoke`/`grant`. `sales_rpc_surface_parity_test` chỉ đòi tham số Dart ⊆ SQL → vẫn pass.

## 3. Phụ thuộc

Sau plan 11. Plan 1 có test đếm lời gọi `_complete_sales_idempotency`: đoạn chết ở `start` (1 lời gọi) và nhánh chết ở `update` (1 lời gọi) bị xoá → sửa test plan 1: 15 begin / **18** complete.
