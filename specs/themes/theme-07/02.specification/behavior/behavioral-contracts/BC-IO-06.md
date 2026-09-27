---
id: BC-IO-06
type: behavioral-contract
theme: theme-07
title: "Adjust reservation capacity"
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
<a id="bc-io-06"></a>
# BC-IO-06 — Adjust reservation capacity

## 1. Ý định

Amend/release/expire/re-evaluate **current held reservation capacity** mà không sở hữu LOT allocation.

## 2. Phạm vi áp dụng

- Loại: Command
- Owner nguồn: IO
- Journey chính: `BJ-04`

## 3. Đầu vào nghiệp vụ

Reservation/group ID + source version; trigger/reason; new requested quantity/UOM snapshot when source amended; affected eligibility change or explicit re-evaluate; source-owned expiry when applicable.

## 4. Điều kiện trước

Reservation/group current; source version monotonic; same warehouse; no cross-warehouse routing; consumed history không được giảm/ghi đè.

## 5. Quy tắc nghiệp vụ

Lock affected reservations/buckets/balances. Apply source delta hoặc re-evaluate capacity. Khi capacity giảm across reservations, phân deterministic theo `reservation_priority` → `source_confirmed_at` → stable `source_line_id`. Update **current held** + shortage. Không auto top-up khi capacity tăng nếu không có source command mới. Nếu active PickAllocation có thể bị ảnh hưởng, phát `allocation_review_required` nhưng **không mutate/supersede/release PickAllocation**.

## 6. Điều kiện bắt buộc

Các constraint bắt buộc là các guard và rule nguồn ở mục 4–5; migration không bổ sung invariant mới.

## 7. Ảnh hưởng trạng thái

Current held/consumed/remaining-required/shortage + release reason + `allocation_review_required` when relevant; no physical movement.

## 9. Kết quả và semantics lỗi

`RESERVATION_NOT_ACTIVE`, `SOURCE_VERSION_STALE`, `UOM_SNAPSHOT_INVALID`, `WAREHOUSE_ROUTING_NOT_AVAILABLE`, `RESERVATION_CONSUMED_HISTORY_CONFLICT`.

## 10. Domain và UC sử dụng

- Entity/Read model: `ENT-IO-05/08`, optional `ENT-IO-13`; read `PRJ-IO-01`, `ENT-IO-09`.
- Trace: `BJ-04`; `ST-07.01`, `ST-07.02`; `SG-04`; `API-C-06`; `EVT-IO-05`.
