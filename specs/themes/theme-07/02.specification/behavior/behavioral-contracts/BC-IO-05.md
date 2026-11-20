---
id: BC-IO-05
type: behavioral-contract
theme: theme-07
title: "Pick and hand over fulfillment"
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
<a id="bc-io-05"></a>
# BC-IO-05 — Pick and hand over fulfillment

## 1. Ý định

Gắn lô khi pick và giảm physical/consume reservation tại handover.

## 2. Phạm vi áp dụng

- Loại: Command
- Owner nguồn: IO + IV
- Journey chính: `BJ-05`

## 3. Đầu vào nghiệp vụ

Fulfillment/source version + `partial_handover_allowed` version, reservation IDs, `allocation_set_id`, `allocation_version`, actual handover quantity per allocation, source/base UOM conversion snapshot, handover actor assertion.

## 4. Điều kiện trước

Reservation active; đúng active allocation set/version; selected LOT/current `lot_pickable_quantity` revalidate hợp lệ; physical correction không còn `PENDING`; actual base quantity `<= picked_base_quantity - consumed_base_quantity`; source/version và partial policy còn current; handover assertion valid.

## 5. Quy tắc nghiệp vụ

Handover khóa active allocation set/version → revalidate source/LOT/quantity → tăng `consumed_base_quantity` mà không rewrite `allocated_base_quantity`/`picked_base_quantity`/source requested → consume reservation đúng lượng → append issue/value movement + update balance atomically → ghi immutable `ENT-IO-11 HandoverEvidence`. Việc lưu pick thuộc `BC-IO-15`.

## 6. Điều kiện bắt buộc

Các constraint bắt buộc là các guard và rule nguồn ở mục 4–5; migration không bổ sung invariant mới.

## 7. Ảnh hưởng trạng thái

Handover completed/partial, immutable handover evidence, consumed quantity, remaining-to-handover derived, reservation consumption, initial COGS. `UNKNOWN` giữ cùng operation identity và fulfillment chuyển `INVENTORY_CONFIRMATION_PENDING/Đang xác minh bàn giao`.

## 8. Tính nguyên tử và kết quả cuối

Handover completed/partial, immutable handover evidence, consumed quantity, remaining-to-handover derived, reservation consumption, initial COGS. `UNKNOWN` giữ cùng operation identity và fulfillment chuyển `INVENTORY_CONFIRMATION_PENDING/Đang xác minh bàn giao`.

## 9. Kết quả và semantics lỗi

`RESERVATION_NOT_ACTIVE`, `PICK_ALLOCATION_CONFLICT`, `PICK_ALLOCATION_ALREADY_CONSUMED`, `LOT_NOT_ELIGIBLE`, `HANDOVER_ASSERTION_REQUIRED`, `INSUFFICIENT_AT_EXECUTION`.

## 10. Domain và UC sử dụng

- Entity/Read model: `ENT-IO-01…06`, `ENT-IO-08/09`, `ENT-IV-02/04`.
- Trace: `BJ-05`; `ST-06.02`; `SG-06`; `API-C-05`; `EVT-IO-04`.
