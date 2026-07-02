# Epic-03 — Theo dõi lịch sử giao dịch của đối tác

## Epic overview

Epic này cho phép xem lịch sử làm việc/giao dịch đã phát sinh với đối tác, hỗ trợ lọc, tìm kiếm và mở chi tiết giao dịch nguồn khi cần.

Dữ liệu lịch sử được tổng hợp từ các module nguồn (bán hàng, nhập hàng, công nợ, …) qua integration events vào read model của module partner — **không** query trực tiếp bảng module khác tại runtime.

Epic này chỉ phục vụ **tra cứu và điều hướng**; không chỉnh sửa giao dịch nguồn.

## Phụ thuộc

| Module nguồn | Trạng thái | Ghi chú |
| ------------ | ---------- | ------- |
| sales | skeleton | Publish `sales.order.checked_out` (planned) |
| inventory | skeleton | Publish inbound events (planned) |
| accounting | skeleton | Publish receivable events (planned) |

**Trạng thái epic:** blocked cho đến khi module nguồn publish integration events.

## User stories

| US | Tên | Folder |
| -- | --- | ------ |
| US-01 | Theo dõi lịch sử làm việc với đối tác | [US-01/](US-01/) |

## Out of scope

- Tạo/sửa đơn bán, phiếu nhập, công nợ từ màn lịch sử
- Tính toán công nợ chi tiết
