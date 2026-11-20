# TH-05 / EP-01 — Lập đơn hàng & lưu nháp

**Trạng thái:** harnessed; implementation `todo`.

## Mục tiêu

Khởi tạo working state, chọn khách hàng/sản phẩm, xử lý pricing preview và lưu/khôi phục đơn nháp.

## User stories

| US | Tên | FR | Trạng thái |
| --- | --- | ---: | --- |
| US-01 | [Khởi tạo đơn hàng đang lập](US-01.md) | 7 | catalogued |
| US-02 | [Xác định khách hàng cho đơn hàng](US-02.md) | 7 | catalogued |
| US-03 | [Thêm và quản lý dòng hàng](US-03.md) | 7 | catalogued |
| US-04 | [Kiểm tra và điều chỉnh giá bán](US-04.md) | 7 | catalogued |
| US-05 | [Lưu giá riêng hoặc nhớ giá từ đơn hàng](US-05.md) | 7 | catalogued |
| US-06 | [Lưu đơn hàng thành đơn nháp](US-06.md) | 7 | catalogued |
| US-07 | [Khôi phục và quản lý đơn nháp](US-07.md) | 7 | catalogued |

## Boundary

- Authoritative mutation phải đi qua domain owner trong [harness/01-domain-model.md](../harness/01-domain-model.md).
- Cross-module dependency dùng snapshot, public contract hoặc durable integration event.
- Field-level contract chỉ freeze khi slice tương ứng chuyển sang `in_progress`.

Nguồn đầy đủ: [Theme-5-sales-orders.md](../Theme-5-sales-orders.md).
