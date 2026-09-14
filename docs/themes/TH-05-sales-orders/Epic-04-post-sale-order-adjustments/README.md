# TH-05 / EP-04 — Chỉnh sửa ghi chú đơn hàng sau bán

> **Superseded / out of scope.** Order note adjustment (SG-09 / S22) đã gỡ khỏi implementation. Nội dung US dưới đây giữ làm lịch sử product; không implement lại trừ khi theme mở lại scope.

**Trạng thái:** `superseded` / out of scope (implementation removed).

## Mục tiêu (lịch sử)

Phase 1: cho phép cập nhật hoặc xóa `order_note` của SalesOrder `completed`, ghi nhận `OrderAdjustment` append-only (`adjustment_type = order_note_update`), không đụng commercial snapshot / payment / inventory / e-invoice.

## User stories

| US | Tên | FR | Trạng thái |
| --- | --- | ---: | --- |
| US-01 | [Cập nhật ghi chú đơn hàng](US-01.md) | 5 | superseded |

## Boundary

- Authoritative mutation phải đi qua domain owner trong [harness/01-domain-model.md](../harness/01-domain-model.md).
- Cross-module dependency dùng snapshot, public contract hoặc durable integration event.
- Field-level contract chỉ freeze khi slice tương ứng chuyển sang `in_progress`.
- Phase 1 **không** mở whitelist multi-field hay reason flow; request ngoài `order_note` bị từ chối toàn bộ.
- **Hiện tại:** EP-04 / S22 / Group G không còn trong scope deliver; post-sale entry chỉ cancel + return/exchange.

Nguồn đầy đủ: [Theme-5-sales-orders.md](../Theme-5-sales-orders.md) §4.5.
