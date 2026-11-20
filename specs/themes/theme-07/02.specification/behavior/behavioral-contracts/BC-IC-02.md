---
id: BC-IC-02
type: behavioral-contract
theme: theme-07
title: "Submit count or recount"
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
<a id="bc-ic-02"></a>
# BC-IC-02 — Submit count or recount

## 1. Ý định

Append immutable count/recount evidence, compute variance after blind submit và route theo actual final variance.

## 2. Phạm vi áp dụng

- Loại: Command
- Owner nguồn: IC
- Journey chính: `BJ-08`

## 3. Đầu vào nghiệp vụ

Session/version, `round_type`, base-UOM line observations, assignment version, command identity.

## 4. Điều kiện trước

Actor = assigned counter; lock active; session lifecycle; keys belong CountScopeSnapshot; quantity precision valid; FIRST only once; recount only discrepant/current requested lines.

## 5. Quy tắc nghiệp vụ

Append `StockCountSubmission` immutable → update StockCountLine projection → compute variance. FIRST/recount zero variance: complete session + release lock atomically, no ApprovalCase/adjustment. Non-zero FIRST: `RECOUNT_REQUIRED`. Non-zero RECOUNT: build/recheck CountAdjustmentBasis; missing surplus basis => `PRICE_BASIS_REQUIRED`; ready => create one pending ApprovalCase for current snapshot.

## 6. Điều kiện bắt buộc

Các constraint bắt buộc là các guard và rule nguồn ở mục 4–5; migration không bổ sung invariant mới.

## 7. Ảnh hưởng trạng thái

`RECOUNT_REQUIRED`, `PRICE_BASIS_REQUIRED`, `PENDING_APPROVAL` hoặc `COMPLETED_NO_ADJUSTMENT`.

## 8. Tính nguyên tử và kết quả cuối

`RECOUNT_REQUIRED`, `PRICE_BASIS_REQUIRED`, `PENDING_APPROVAL` hoặc `COMPLETED_NO_ADJUSTMENT`.

## 9. Kết quả và semantics lỗi

`COUNT_LINE_OUT_OF_SCOPE`, `COUNT_ALREADY_SUBMITTED`, `COUNT_ACTOR_NOT_ASSIGNED`, `COUNT_PHYSICAL_STATE_REQUIRED`, `LOT_OR_EXPIRY_REQUIRED`, `COUNT_SURPLUS_VALUE_BASIS_REQUIRED`, `LOCK_LOST`.

## 10. Domain và UC sử dụng

- Entity/Read model: `ENT-IC-04/05/09`, có thể `ENT-IC-02`; surplus/Official Cost refs.
- Trace: `BJ-08`; `T7-DR-173`, `T7-DR-174`, `T7-DR-176`, `T7-DR-177`; `API-C-15`.
