# TH-05 / EP-02 — Thanh toán & hoàn tất đơn hàng

**Trạng thái:** harnessed; implementation `todo`.

## Mục tiêu

Kiểm tra checkout, ghi nhận payment/receivable intent, tạo SalesOrder và receipt.

## User stories

| US | Tên | FR | Trạng thái |
| --- | --- | ---: | --- |
| US-01 | [Kiểm tra tổng tiền và nghĩa vụ thanh toán](US-01.md) | 7 | catalogued |
| US-02 | [Ghi nhận một hoặc nhiều khoản thanh toán](US-02.md) | 7 | catalogued |
| US-03 | [Xử lý đơn hàng còn phải thu](US-03.md) | 7 | catalogued |
| US-04 | [Kiểm tra điều kiện checkout](US-04.md) | 7 | catalogued |
| US-05 | [Hoàn tất đơn hàng an toàn](US-05.md) | 7 | catalogued |
| US-06 | [Xem kết quả giao dịch](US-06.md) | 7 | catalogued |
| US-07 | [Xem, in hoặc chia sẻ phiếu bán hàng](US-07.md) | 7 | catalogued |

## Boundary

- Authoritative mutation phải đi qua domain owner trong [harness/01-domain-model.md](../harness/01-domain-model.md).
- Cross-module dependency dùng snapshot, public contract hoặc durable integration event.
- Field-level contract chỉ freeze khi slice tương ứng chuyển sang `in_progress`.

Nguồn đầy đủ: [Theme-5-sales-orders.md](../Theme-5-sales-orders.md).
