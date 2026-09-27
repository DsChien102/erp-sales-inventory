---
id: BC-IO-07
type: behavioral-contract
theme: theme-07
title: "Receive customer return"
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
<a id="bc-io-07"></a>
# BC-IO-07 — Receive customer return

## 1. Ý định

Tăng physical ở `RETURN_PENDING` theo **hàng thực nhận**, trong phạm vi return intent hiện hành.

## 2. Phạm vi áp dụng

- Loại: Command
- Owner nguồn: IO
- Journey chính: `BJ-06`

## 3. Đầu vào nghiệp vụ

Return request/source version, ReturnExchangeLine/source line identity, `authorized_return_quantity`, declared `ReturnCondition`, transaction UOM + precision/snapshot; với combo: component line/snapshot; actual quantity, resolved actual LOT/LOT attributes, value basis; evidence refs khi có exception.

## 4. Điều kiện trước

`0 ≤ actual_received_quantity ≤ remaining_authorized_quantity`; cumulative return cap atomically trên từng original component issue; source/version current; actual LOT resolve được và matches issued LOT hoặc line-exception approval exact snapshot; LOT data-integrity conflict không approval override; request có ít nhất một actual quantity > 0.

## 5. Quy tắc nghiệp vụ

Lock source return lines + original component return aggregates theo thứ tự xác định → recheck authorized quantity/cumulative cap/UOM precision/source version/LOT resolution → append toàn bộ actual quantity movement `RETURN_PENDING` và value movement kỳ mở hiện tại → update cumulative returned/balance/outbox trong một transaction. Commercial quantity chưa thực nhận vẫn thuộc source owner.

## 6. Điều kiện bắt buộc

Các constraint bắt buộc là các guard và rule nguồn ở mục 4–5; migration không bổ sung invariant mới.

## 7. Ảnh hưởng trạng thái

Physical/value tăng đúng actual quantity, available không tăng; result linked to source return request + original issue; server trả `recorded_at`. Không tự tạo business “return receipt number” riêng.

## 8. Tính nguyên tử và kết quả cuối

Physical/value tăng đúng actual quantity, available không tăng; result linked to source return request + original issue; server trả `recorded_at`. Không tự tạo business “return receipt number” riêng.

## 9. Kết quả và semantics lỗi

`RETURN_AUTHORIZED_QUANTITY_EXCEEDED`, `RETURN_LIMIT_EXCEEDED`, `ORIGINAL_ISSUE_NOT_FOUND`, `RETURN_SOURCE_STALE`, `RETURN_LOT_MISMATCH`, `LOT_ATTRIBUTE_REQUIRED`, `LOT_DATA_CONFLICT`, `COMBO_COMPONENT_MISMATCH`, `RETURN_VALUE_BASIS_MISSING`.

## 10. Domain và UC sử dụng

- Entity/Read model: `ENT-IO-01/02/03/04/06`, `ENT-IV-02`; return aggregate và original cost reference snapshot.
- Trace: `BJ-06`; `ST-08.01`, `ST-08.02`, `ST-08.03`; `SG-07`; `API-C-07`; `EVT-IO-06`.
