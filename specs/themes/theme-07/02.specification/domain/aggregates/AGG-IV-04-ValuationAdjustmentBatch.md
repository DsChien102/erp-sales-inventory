---
id: AGG-IV-04
type: aggregate
theme: theme-07
title: "ValuationAdjustmentBatch Aggregate"
owner: SA
status: IN_REVIEW
source_baseline: v3.12.0
---
# AGG-IV-04 — ValuationAdjustmentBatch Aggregate

## 1. Trách nhiệm nghiệp vụ

Gom các **delta giá trị** phải ghi trong cùng posting period và cùng cause/baseline để bảo đảm tổng điều chỉnh cân bằng, truy vết được và commit nhất quán.

Aggregate dùng cho cả:
- điều chỉnh giá trị hàng nhập từ BJ13;
- COGS/ending-inventory reconciliation khi BJ14 công bố.

## 2. Boundary

**Thuộc Aggregate:** `ENT-IV-05 ValuationAdjustmentBatch`, `ENT-IV-06 ValuationAdjustmentLine`.

**Không thuộc Aggregate:** economic source (`ENT-IV-07 ValueAdjustmentSource`), ProductCostResult (`AGG-IV-02`), quantity movement (`DOM-IO`).

## 3. Invariant

- Mỗi batch có đúng một posting period.
- Tổng `deltaAmountVnd` của lines bằng total batch.
- Original period có thể khác posting period nhưng phải giữ ở line để truy vết.
- Batch chỉ ghi phần delta; không re-post toàn lịch sử và không sửa movement gốc.
- Source/baseline/hash phải current ngay trước commit.

## 4. Hành vi chính

- `commitReceiptValueAdjustment()` — ghi signed BJ13 allocations/value movements.
- `publishCostReconciliation()` — ghi COGS/ending-value delta đi cùng BJ14 publication.

## 5. Trace

`BJ-13`, `BJ-14` → `UC-13-01`, `UC-14-04` → `BC-IV-04/03` → `ENT-IV-05/06`.
