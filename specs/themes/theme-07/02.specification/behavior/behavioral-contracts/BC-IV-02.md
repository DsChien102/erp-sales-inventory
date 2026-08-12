---
id: BC-IV-02
type: behavioral-contract
theme: theme-07
title: "Calculate inventory cost"
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
<a id="bc-iv-02"></a>
# BC-IV-02 — Calculate inventory cost

## 1. Ý định

Tính hai phương pháp trên cùng ordered valuation timeline, materialize ProductCostResult theo Product và tạo immutable run có blocker/evidence.

## 2. Phạm vi áp dụng

- Loại: Command
- Owner nguồn: IV
- Journey chính: `BJ-14`

## 3. Đầu vào nghiệp vụ

`run_type`, `calculation_period_id`, `posting_period_id`, `scope_origin`, immutable product scope + `scope_hash`; dirty run kèm `dirty_scope_snapshot/version/hash` + cause IDs; `cutoff_valuation_sequence`; locked method-policy version; `supersedes_run_id?`. Quantity/value cursor riêng chỉ là audit cursors.

## 4. Điều kiện trước

Financial permission; calculation/posting period hợp lệ; dirty scope/cause version còn current; một run chỉ có một posting period; deterministic input snapshot; không reuse/cancel started run.

## 5. Quy tắc nghiệp vụ

Snapshot ordered quantity/value facts bằng `valuation_sequence + within_transaction_ordinal` tới cutoff → detect blocker theo Product → tính moving/periodic weighted average trên cùng fact set → materialize immutable `ProductCostResult` gồm target cumulative COGS/carrying value, authoritative baseline và proposed incremental deltas → áp explicit zero/negative edge-case policy → aggregate run totals → mark `BLOCKED` hoặc `READY_FOR_REVIEW`.

## 6. Điều kiện bắt buộc

Các constraint bắt buộc là các guard và rule nguồn ở mục 4–5; migration không bổ sung invariant mới.

## 7. Ảnh hưởng trạng thái

`CostCalculationRun` + immutable `ProductCostResult[]` + blocker snapshot/result hashes; **không ledger mutation**.

## 9. Kết quả và semantics lỗi

`INPUT_SNAPSHOT_INCONSISTENT`, `DIRTY_SCOPE_STALE`, `CALCULATION_FAILED`, `PERIOD_NOT_CALCULABLE`, `NEGATIVE_QUANTITY`, `NEGATIVE_VALUATION_RESULT`.

## 10. Domain và UC sử dụng

- Entity/Read model: `ENT-IV-03`, `ENT-IV-09`; read `ENT-IO-03`, `ENT-IV-02/04`, valuation/period facts.
- Trace: `BJ-14`; `UC-14-01/02`; `API-C-21`; `T7-DR-164…170`.
