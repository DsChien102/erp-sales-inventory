# UI Contracts — Theme 07

> **Snapshot lịch sử v4.1.0.** 17 link bên dưới cố ý giữ nguyên đường dẫn cũ và không tham gia gate liên kết active của v4.3.0. Dùng `screen-group-retirement-map.json` và Screen Registry hiện hành để tra migration.

UI Contract là đặc tả dẫn xuất do BA và Designer phối hợp duy trì. SRS vẫn giữ hành vi/thẩm quyền; UI Contract giữ **Screen inventory, Screen→State coverage, UI tree/composition và trace tới Action–BC–API**; prototype là bản chạy để duyệt flow.

## Cách đọc

1. Đọc hành trình tại [`../srs/02-business-journeys/00-business-journey-map.md`](../../../../../../02.specification/behavior/journeys/00-business-journey-map.md).
2. Đọc Screen Group index tại [`../srs/08-ui-ux.md`](../../../../implementation/legacy-harness/frozen-source/srs/08-ui-ux.md).
3. Mở `sg-xx/ui-contract.md` và `composition-map.yaml`.
4. Chạy [`../prototype/index.html`](../prototype/index.html) để duyệt mọi Screen/State.

## Danh mục

| SG | Tên | Journey | Screens | State fixtures | Actions |
|---|---|---|---:|---:|---:|
| [`SG-01`](./sg-01/ui-contract.md) | Tồn kho và khả dụng | `BJ-01` | 5 | 30 | 1 |
| [`SG-02`](./sg-02/ui-contract.md) | Nhận hàng | `BJ-02` | 8 | 51 | 4 |
| [`SG-03`](./sg-03/ui-contract.md) | Hàng chờ giá | `BJ-03`, `BJ-13`, `BJ-14` | 6 | 32 | 2 |
| [`SG-04`](./sg-04/ui-contract.md) | Reservation và thiếu hàng | `BJ-04` | 5 | 28 | 2 |
| [`SG-06`](./sg-06/ui-contract.md) | Pick, pack và bàn giao | `BJ-05` | 5 | 27 | 2 |
| [`SG-07`](./sg-07/ui-contract.md) | Khách trả và phân loại | `BJ-06` | 6 | 33 | 2 |
| [`SG-08`](./sg-08/ui-contract.md) | Trạng thái, trả nhà cung cấp và tiêu hủy | `BJ-07`, `BJ-09`, `BJ-10` | 6 | 32 | 3 |
| [`SG-09`](./sg-09/ui-contract.md) | Kiểm kê | `BJ-08` | 6 | 33 | 4 |
| [`SG-10`](./sg-10/ui-contract.md) | Operation, phê duyệt và sửa sai | `BJ-11` | 6 | 39 | 5 |
| [`SG-11`](./sg-11/ui-contract.md) | Thẻ kho và lịch sử | `BJ-01`, `BJ-15` | 6 | 33 | 1 |
| [`SG-12`](./sg-12/ui-contract.md) | Chính sách tồn sản phẩm và chỉ báo | `CAP-01`, `BJ-01`, `BJ-04` | 6 | 34 | 2 |
| [`SG-13`](./sg-13/ui-contract.md) | Opening balance và Chuyển đổi chính thức | `BJ-12` | 6 | 36 | 2 |
| [`SG-14`](./sg-14/ui-contract.md) | Tính giá vốn và đóng kỳ | `BJ-14` | 6 | 37 | 2 |
| [`SG-15`](./sg-15/ui-contract.md) | Tin cậy, UNKNOWN và đối soát | `BJ-16`, `BJ-17`, `PROC-01` | 6 | 34 | 1 |

## Cấu trúc mỗi SG

- `ui-contract.md`: người đọc — mục tiêu, luồng chính thức, Screen/State/Action và acceptance.
- `composition-map.yaml`: máy đọc — UI tree, component role, state delta và Action→BC→API.
- `prototype-manifest.yaml`: route, fixture, metadata và authority của bản chạy.

## Quy tắc bắt buộc

- Mỗi BJ ánh xạ tới SG hoặc `NO_UI`; SG dùng chung phải ghi rõ journey và mục đích sử dụng.
- SG là bề mặt UI ổn định, không phải đơn vị chia task; một SG có thể phục vụ nhiều UC/BJ.
- Mỗi SG phải khai đủ Screen; mỗi Screen phải khai đủ state áp dụng.
- Tên Screen luôn hiển thị trước khi chọn trong prototype.
- Prototype controller và trace không thuộc sản phẩm; Figma chỉ lấy vùng `[data-design-viewport]`.
- Không có `prototype-starter-v1` trong template của package này.
