# TH-05 / EP-05 — Hủy đơn hàng sau bán

**Trạng thái:** harnessed; implementation `todo`.

## Mục tiêu

Precheck và điều phối hủy đơn cùng refund, inventory, receivable, pricing và E-invoice impacts.

## User stories

| US | Tên | FR | Trạng thái |
| --- | --- | ---: | --- |
| US-01 | [Kiểm tra điều kiện và tác động hủy đơn](US-01.md) | 7 | catalogued |
| US-02 | [Xác định lý do hủy](US-02.md) | 7 | catalogued |
| US-03 | [Xác nhận hủy toàn bộ đơn hàng](US-03.md) | 7 | catalogued |
| US-04 | [Theo dõi các tác động hoàn nguyên](US-04.md) | 7 | catalogued |
| US-05 | [Xem kết quả và lịch sử hủy đơn](US-05.md) | 7 | catalogued |

## Boundary

- Authoritative mutation phải đi qua domain owner trong [harness/01-domain-model.md](../harness/01-domain-model.md).
- Cross-module dependency dùng snapshot, public contract hoặc durable integration event.
- Field-level contract chỉ freeze khi slice tương ứng chuyển sang `in_progress`.

Nguồn đầy đủ: [Theme-5-sales-orders.md](../Theme-5-sales-orders.md).
