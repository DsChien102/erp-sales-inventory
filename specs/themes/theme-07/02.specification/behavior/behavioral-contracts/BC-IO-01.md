---
id: BC-IO-01
type: behavioral-contract
theme: theme-07
title: "Query inventory availability"
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
<a id="bc-io-01"></a>
# BC-IO-01 — Query inventory availability

## 1. Ý định

Trả lượng vật lý, eligible, reserved, available, trạng thái và lô theo filter/cut-off.

## 2. Phạm vi áp dụng

- Loại: Query
- Owner nguồn: IO
- Journey chính: `BJ-01`

## 3. Đầu vào nghiệp vụ

Product/filter, warehouse mặc định, `as_of?`, view mode và financial-field request.

## 4. Điều kiện trước

View permission/scope; financial permission nếu yêu cầu giá.

## 5. Quy tắc nghiệp vụ

Dùng transactional balance cho availability hiện hành; historical/report dùng projection có sequence. Reservation được đọc ở cấp Product + Warehouse và **không phân bổ giả xuống LOT** trong BJ-01. Eligibility của LOT tính tại tenant business date; khi physical > eligible phải trả breakdown lý do.

## 6. Điều kiện bắt buộc

Các constraint bắt buộc là các guard và rule nguồn ở mục 4–5; migration không bổ sung invariant mới.

## 7. Ảnh hưởng trạng thái

Product aggregate gồm physical/eligible/reserved/available; LOT detail chỉ gồm physical/eligible/expiry/eligibility; `query_as_of`/sequence, stale indicator, eligibility breakdown và drill-down IDs.

## 9. Kết quả và semantics lỗi

`FORBIDDEN_SCOPE`, `PRODUCT_NOT_FOUND`, `SNAPSHOT_NOT_AVAILABLE`.

## 10. Domain và UC sử dụng

- Entity/Read model: Read `ENT-IO-03/04/06`, `PRJ-01/02/03`; không mutation.
- Trace: `BJ-01`; `ST-01.01`, `ST-01.02`, `ST-01.03`, `ST-16.01`, `ST-16.02`; `SG-01`, `SG-11`; `API-Q-01`, `API-Q-05`, `API-Q-06`; `TST-BC-IO-01-*`.
