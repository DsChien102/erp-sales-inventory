---
id: BC-IO-12
type: behavioral-contract
theme: theme-07
title: "Cancel pending operation"
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
<a id="bc-io-12"></a>
# BC-IO-12 — Cancel pending operation

## 1. Ý định

Hủy operation trước execution mà không ảnh hưởng tồn.

## 2. Phạm vi áp dụng

- Loại: Command
- Owner nguồn: IO
- Journey chính: `BJ-11`

## 3. Đầu vào nghiệp vụ

Operation ID/version, source version, reason.

## 4. Điều kiện trước

Status in `DRAFT/PENDING_APPROVAL/READY`; permission; first valid transition wins.

## 5. Quy tắc nghiệp vụ

Mark `CANCELLED`, release operation-owned locks/approval work, write audit/outbox.

## 6. Điều kiện bắt buộc

Các constraint bắt buộc là các guard và rule nguồn ở mục 4–5; migration không bổ sung invariant mới.

## 7. Ảnh hưởng trạng thái

Terminal cancelled; no movement/value effect.

## 8. Tính nguyên tử và kết quả cuối

Terminal cancelled; no movement/value effect.

## 9. Kết quả và semantics lỗi

`OPERATION_NOT_CANCELLABLE`, `VERSION_CONFLICT`; `PROCESSING/UNKNOWN` yêu cầu reconciliation, `COMPLETED` yêu cầu reversal.

## 10. Domain và UC sử dụng

- Entity/Read model: `ENT-IO-01`, approval/locks.
- Trace: `BJ-11`; `ST-12.01`, `ST-12.02`; `SG-10`; `API-C-12`; `EVT-IO-09`.
