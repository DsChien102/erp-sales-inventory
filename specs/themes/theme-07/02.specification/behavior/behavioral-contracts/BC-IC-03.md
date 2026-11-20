---
id: BC-IC-03
type: behavioral-contract
theme: theme-07
title: "Approve variance and adjust"
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
<a id="bc-ic-03"></a>
# BC-IC-03 — Approve variance and adjust

## 1. Ý định

Independent approver quyết định exact non-zero count snapshot; APPROVE tạo adjustment nguyên tử, REQUEST_RECOUNT giữ lock và mở round mới.

## 2. Phạm vi áp dụng

- Loại: Command
- Owner nguồn: IC + IO + IV
- Journey chính: `BJ-08`

## 3. Đầu vào nghiệp vụ

Session/version, approval_case_id/version, decision `APPROVE

## 4. Điều kiện trước

Latest round non-zero; case subject=STOCK_COUNT_SESSION/current snapshot; approver eligible và không nằm `excluded_actor_ids`; lock active; policy/basis/cost/scope/cutoff/round hashes còn hiện hành.

## 5. Quy tắc nghiệp vụ

`REQUEST_RECOUNT`: quyết định case bất biến → session `RECOUNT_REQUIRED`, giữ lock, successor lineage. `APPROVE`: rederive/recheck CountAdjustmentBasis/risk; create one adjustment operation + quantity/value movements → complete session → release lock → outbox, cùng transaction.

## 6. Điều kiện bắt buộc

Các constraint bắt buộc là các guard và rule nguồn ở mục 4–5; migration không bổ sung invariant mới.

## 7. Ảnh hưởng trạng thái

`RECOUNT_REQUIRED` hoặc `COMPLETED` với adjustment authoritative.

## 8. Tính nguyên tử và kết quả cuối

`RECOUNT_REQUIRED` hoặc `COMPLETED` với adjustment authoritative.

## 9. Kết quả và semantics lỗi

`SELF_APPROVAL_NOT_ALLOWED`, `COUNT_NOT_READY`, `LOCK_LOST`, `RISK_LEVEL_INSUFFICIENT`, `COUNT_APPROVAL_SNAPSHOT_STALE`, `COUNT_VALUE_BASIS_STALE`.

## 10. Domain và UC sử dụng

- Entity/Read model: `ENT-IC-02…05/09`, `ENT-IO-01…04`, `ENT-IV-02/04` và value-basis refs.
- Trace: `BJ-08`; `T7-DR-175…177`; `API-C-16`; `EVT-IC-01`.
