---
id: BC-IV-03
type: behavioral-contract
theme: theme-07
title: "Publish valuation and official cost"
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
<a id="bc-iv-03"></a>
# BC-IV-03 — Publish valuation and official cost

## 1. Ý định

Publish incremental COGS/ending-inventory reconciliation và forward-effective Official Cost versions từ immutable ProductCostResult.

## 2. Phạm vi áp dụng

- Loại: Command
- Owner nguồn: IV
- Journey chính: `BJ-14`

## 3. Đầu vào nghiệp vụ

Ready run/version, `run_input_hash`, `cutoff_valuation_sequence`, scope/dirty version+hash, selected ProductCostResult hashes, reviewer confirmation, requested effective time.

## 4. Điều kiện trước

Financial role; no blockers at recheck; run not published/stale; locked policy matches run; one posting period; posting period open/allowed; ProductCostResult hashes current; requested Official Cost effective time không nằm trước publication commit; totals/deltas reconcile.

## 5. Quy tắc nghiệp vụ

Re-derive freshness/baseline → với mỗi Product tính `target cumulative COGS - authoritative COGS already posted` và `target ending inventory value - current authoritative carrying value` → create only non-zero adjustment lines/value movements → create non-overlapping OfficialCostVersion only where a valid new basis exists, with effective time at commit or allowed future time → clear exactly reconciled Product+posting-period dirty causes → mark run published → outbox atomically. Rerun cùng facts phải delta 0.

## 6. Điều kiện bắt buộc

Các constraint bắt buộc là các guard và rule nguồn ở mục 4–5; migration không bổ sung invariant mới.

## 7. Ảnh hưởng trạng thái

Published run, per-Product reconciliation result, adjustment batch/value movements, Official Cost versions actually created, exact dirty causes cleared; original transaction history unchanged.

## 8. Tính nguyên tử và kết quả cuối

Published run, per-Product reconciliation result, adjustment batch/value movements, Official Cost versions actually created, exact dirty causes cleared; original transaction history unchanged.

## 9. Kết quả và semantics lỗi

`COST_RUN_BLOCKED`, `COST_RUN_STALE`, `DIRTY_SCOPE_STALE`, `COST_RUN_ALREADY_PUBLISHED`, `ADJUSTMENT_TOTAL_MISMATCH`, `COST_EFFECTIVE_INTERVAL_OVERLAP`, `COST_EFFECTIVE_TIME_IN_PAST`.

## 10. Domain và UC sử dụng

- Entity/Read model: `ENT-IV-02…06`, `ENT-IV-09`; links to predecessor cost/publication and issue/value facts.
- Trace: `BJ-14`; `UC-14-04`; `API-C-22`; `EVT-IV-04`; `T7-DR-164…170`.
