# TH-05 / EP-03 — Tra cứu & theo dõi đơn hàng

**Trạng thái:** harnessed; implementation `todo`.

## Mục tiêu

Danh sách, chi tiết, settlement summary, timeline, receipt; integration status **deferred stub** (US-06 / S20).

## User stories

| US | Tên | FR | Trạng thái |
| --- | --- | ---: | --- |
| US-01 | [Tra cứu danh sách đơn hàng](US-01.md) | 7 | catalogued |
| US-02 | [Xem chi tiết giao dịch gốc](US-02.md) | 7 | catalogued |
| US-03 | [Kiểm tra thanh toán và công nợ của đơn](US-03.md) | 7 | catalogued |
| US-04 | [Theo dõi timeline và lịch sử sau bán](US-04.md) | 7 | catalogued |
| US-05 | [Xem lại phiếu bán hàng](US-05.md) | 7 | catalogued |
| US-06 | [Theo dõi trạng thái xử lý liên quan](US-06.md) | 7 | **deferred stub** |
| US-07 | [Khởi tạo thao tác sau bán](US-07.md) | 7 | catalogued |

## Boundary

- Authoritative mutation phải đi qua domain owner trong [harness/01-domain-model.md](../harness/01-domain-model.md).
- Cross-module dependency dùng snapshot, public contract hoặc durable integration event.
- Field-level contract chỉ freeze khi slice tương ứng chuyển sang `in_progress`.

Nguồn đầy đủ: [Theme-5-sales-orders.md](../Theme-5-sales-orders.md).
