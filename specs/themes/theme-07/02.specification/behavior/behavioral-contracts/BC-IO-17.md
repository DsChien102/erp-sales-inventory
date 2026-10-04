---
id: BC-IO-17
type: behavioral-contract
theme: theme-07
title: "Synchronize supplier-return authorization"
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
<a id="bc-io-17"></a>
# BC-IO-17 — Synchronize supplier-return authorization

## 1. Ý định

System-owned intake/update của supplier-return intent đã được Purchase/source authorize; materialize exact current source allocations vào `RTV_PENDING` mà không yêu cầu warehouse mutation CTA.

## 2. Phạm vi áp dụng

- Loại: Command/System sync
- Owner nguồn: IO
- Journey chính: `BJ-07`

## 3. Đầu vào nghiệp vụ

`source_request_id`, monotonic `source_version`, stable `source_line_id/source_allocation_id`, Product, transaction UOM + conversion/precision snapshot, authorized quantity, LOT allocation, source goods receipt lineage khi có; delta add/change/remove/cancel.

## 4. Điều kiện trước

Source authority/version hợp lệ; stable allocation identity không collision; warehouse scope hợp lệ; exact balance/LOT đủ lượng; completed handover quantity không bị rewrite; source slice deterministic hoặc đã được Warehouse xác nhận khi có nhiều stock-state composition hợp lệ.

## 5. Quy tắc nghiệp vụ

Mỗi source allocation resolve/materialize `1..N` source slices bằng `InventoryOperationLine` (`source_allocation_id`, `source_balance_id`, `origin_stock_state`) → chuyển exact quantity từ original state sang `RTV_PENDING`; source update chỉ reset affected verification; remove/cancel release exact unhanded quantity về original state; preserve unaffected evidence. Không giảm physical/value ở bước này.

## 6. Điều kiện bắt buộc

Các constraint bắt buộc là các guard và rule nguồn ở mục 4–5; migration không bổ sung invariant mới.

## 7. Ảnh hưởng trạng thái

Current pending snapshot/task có stable allocation identity, exact source slices và business delta cụ thể; availability loại trừ quantity ở `RTV_PENDING`.

## 9. Kết quả và semantics lỗi

`SOURCE_VERSION_CONFLICT`, `SOURCE_ALLOCATION_ID_CONFLICT`, `INSUFFICIENT_STOCK`, `LOT_MISMATCH`, `SOURCE_STATE_AMBIGUOUS`, `SOURCE_CANCELLED`.

## 10. Domain và UC sử dụng

- Entity/Read model: `ENT-IO-01/02/03/04/10`; `ENT-IO-12` observation có thể trigger source amendment nhưng không tự mutate source.
- Trace: `BJ-07`; `UC-07-01/02/03`; `IN-EVT-01`; `EVT-IO-11`.
