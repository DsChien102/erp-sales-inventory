# EP02 — Giá riêng / Nhớ giá

**Trạng thái:** `active`.

## Mục tiêu

Cho phép tenant quản lý giá bán riêng theo khách hàng × sản phẩm × đơn vị bán × khoảng hiệu lực, đồng thời nhận yêu cầu nhớ giá idempotent từ Sales và lưu đầy đủ lịch sử thay đổi.

## User stories

| US | Tên | Slice |
| -- | --- | ----- |
| [US-01](US-01.md) | Danh sách, tìm kiếm và lọc giá riêng | S2 |
| [US-02](US-02.md) | Chọn cách thêm giá riêng | S4 |
| [US-03](US-03.md) | Xem chi tiết giá riêng | S3 |
| [US-04](US-04.md) | Tạo giá riêng thủ công | S1 |
| [US-05](US-05.md) | Import giá riêng từ Excel | S8 |
| [US-06](US-06.md) | Chỉnh sửa giá riêng | S5 |
| [US-07](US-07.md) | Vô hiệu hóa giá riêng | S6 |
| [US-08](US-08.md) | Kích hoạt lại giá riêng | S7 |
| [US-09](US-09.md) | Nhớ giá từ đơn bán | S9 |
| [US-10](US-10.md) | Xem lịch sử giá riêng | S10 |

Domain và contract triển khai nằm tại [harness/](../harness/).

