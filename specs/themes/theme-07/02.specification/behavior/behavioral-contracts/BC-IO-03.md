---
id: BC-IO-03
type: behavioral-contract
theme: theme-07
title: "Reserve order quantity"
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
<a id="bc-io-03"></a>
# BC-IO-03 — Reserve order quantity

## 1. Ý định

Tạo current reservation capacity cho source line/combo mà chưa giảm physical.

## 2. Phạm vi áp dụng

- Loại: Command
- Owner nguồn: IO
- Journey chính: `BJ-04`

## 3. Đầu vào nghiệp vụ

Source document/line/version; inventory mode; `reservation_policy=NONE

## 4. Điều kiện trước

Chỉ `ADVANCED`; source/version current; no lock; product sellable/eligible; policy hợp lệ. `NONE` trả no-effect `NOT_REQUIRED`. Combo phải resolve đủ component definition/version.

## 5. Quy tắc nghiệp vụ

Lock ReservationBucket(s) deterministic → normalize source quantity → tính capacity. Single product tạo/update Reservation. Combo tạo ReservationGroup + child component reservations và commit atomically theo số nguyên combo. `ALL_OR_NOTHING` thiếu → reject toàn bộ/bucket unchanged; `PARTIAL_ALLOWED` → current hold hợp lệ + shortage. Không chọn LOT.

## 6. Điều kiện bắt buộc

Các constraint bắt buộc là các guard và rule nguồn ở mục 4–5; migration không bổ sung invariant mới.

## 7. Ảnh hưởng trạng thái

Current `reserved_base_quantity`, `consumed_base_quantity=0` khi create, `remaining_required`, shortage, group/component result và source-UOM projection. Physical unchanged.

## 8. Tính nguyên tử và kết quả cuối

Current `reserved_base_quantity`, `consumed_base_quantity=0` khi create, `remaining_required`, shortage, group/component result và source-UOM projection. Physical unchanged.

## 9. Kết quả và semantics lỗi

`RESERVATION_NOT_REQUIRED`, `BASIC_STOCK_RESERVATION_NOT_SUPPORTED`, `INSUFFICIENT_AVAILABLE`, `SOURCE_VERSION_STALE`, `COMPONENT_SHORTAGE`, `BALANCE_CONFLICT`, `UOM_SNAPSHOT_INVALID`.

## 10. Domain và UC sử dụng

- Entity/Read model: `ENT-IO-05`, `ENT-IO-08`, optional `ENT-IO-13`; read `PRJ-IO-01`.
- Trace: `BJ-04`; `ST-04.01`, `ST-04.02`, `ST-04.03`; `SG-04`; `API-C-03`; `EVT-IO-02`.
