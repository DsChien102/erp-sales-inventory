# TH-05 / EP-06 — Đổi/trả hàng & quyết toán chênh lệch

**Trạng thái:** harnessed; implementation `todo`.

## Mục tiêu

Lập return/exchange, định giá, thu thêm, hoàn tiền hoặc cấn trừ công nợ.

## User stories

| US | Tên | FR | Trạng thái |
| --- | --- | ---: | --- |
| US-01 | [Khởi tạo phiếu đổi/trả từ đơn hàng gốc](US-01.md) | 7 | catalogued |
| US-02 | [Ghi nhận hàng khách trả](US-02.md) | 7 | catalogued |
| US-03 | [Ghi nhận hàng khách nhận đổi](US-03.md) | 7 | catalogued |
| US-04 | [Giữ và bỏ thay đổi chưa xác nhận trong phiên đổi/trả](US-04.md) | 6 | catalogued |
| US-05 | [Xem giá trị và chênh lệch đổi/trả](US-05.md) | 7 | catalogued |
| US-06 | [Quyết toán chênh lệch đổi/trả](US-06.md) | 7 | catalogued |
| US-07 | [Xác nhận và theo dõi kết quả đổi/trả](US-07.md) | 7 | catalogued |

## Boundary

- Authoritative mutation phải đi qua domain owner trong [harness/01-domain-model.md](../harness/01-domain-model.md).
- Cross-module dependency dùng snapshot, public contract hoặc durable integration event.
- Field-level contract chỉ freeze khi slice tương ứng chuyển sang `in_progress`.

Nguồn đầy đủ: [Theme-5-sales-orders.md](../Theme-5-sales-orders.md).
