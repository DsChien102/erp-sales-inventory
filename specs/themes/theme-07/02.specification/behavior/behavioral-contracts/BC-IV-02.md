---
id: BC-IV-02
type: behavioral-contract
theme: theme-07
title: "Tính và rà soát giá vốn"
owner: BA
status: FROZEN
source_baseline: v3.12.0
---
# BC-IV-02 — Tính và rà soát giá vốn

## 1. Ý định

Tạo một `CostCalculationRun` bất biến trên cùng valuation timeline, tính song song hai phương pháp bình quân và xác định kết quả nào **được phép công bố theo cấu hình tenant**. BC này chỉ tính/rà soát; không ghi adjustment hoặc Official Cost.

## 2. Phạm vi áp dụng

- **Loại:** Command tính toán có materialized result, **không** ledger mutation.
- **Owner:** `DOM-IV`.
- **Journey / UC:** `BJ-14` / `UC-14-01`.

## 3. Đầu vào nghiệp vụ

- `run_type = PERIOD_CLOSE | AD_HOC`;
- calculation/posting period;
- `scope_origin`, immutable Product scope + hash;
- với dirty run: exact Product+posting-period snapshot/version/cause IDs;
- `cutoff_valuation_sequence`;
- costing-policy version của tenant, bao gồm **phương pháp được công bố**;
- predecessor/superseded run nếu là rerun.

## 4. Điều kiện trước

Actor có quyền tính giá vốn; period hợp lệ; dirty scope current; một run có đúng một posting period; input snapshot deterministic. Người dùng **không** chọn lại costing method cho run.

## 5. Quy tắc nghiệp vụ

1. Khóa ordered quantity/value fact set tới cutoff bằng `valuation_sequence + within_transaction_ordinal`.
2. Phát hiện blocker theo Product và period.
3. Tính **bình quân gia quyền liên hoàn** và **bình quân gia quyền cuối kỳ** trên cùng fact set.
4. Dùng tenant policy version để đánh dấu phương pháp nào là `publishable`, phương pháp còn lại là `comparison_only`.
5. Materialize immutable `ProductCostResult` gồm target COGS/carrying value, authoritative baseline, proposed incremental deltas, blocker và comparison result.
6. Aggregate run thành `BLOCKED` hoặc `READY_FOR_REVIEW`.

## 6. Điều kiện bắt buộc

- Dirty/ad-hoc scope là source-owned; user không tùy ý bỏ Product.
- Period-close scope được khóa khi tạo run.
- Phương pháp không được chọn bởi tenant **không** được tự ghi sổ.
- Run đã bắt đầu không bị sửa/hủy; rerun tạo successor.
- Cùng facts/policy/cutoff phải cho deterministic result.

## 7. Ảnh hưởng trạng thái

Tạo `CostCalculationRun` + immutable `ProductCostResult[]` + blocker/input snapshot. Không tạo `InventoryValueMovement`, `ValuationAdjustmentBatch` hoặc `OfficialCostVersion`.

## 8. Tính nguyên tử và kết quả cuối

Run/result snapshot phải tự nhất quán; nếu calculation fail trước materialization thì không để half-run có vẻ sẵn sàng. Query/read timeout sau đó chỉ refetch run đã có.

## 9. Kết quả và semantics lỗi

`INPUT_SNAPSHOT_INCONSISTENT`, `DIRTY_SCOPE_STALE`, `CALCULATION_FAILED`, `PERIOD_NOT_CALCULABLE`, `NEGATIVE_QUANTITY`, `NEGATIVE_VALUATION_RESULT`.

## 10. Domain và UC sử dụng

- **Domain / Entity:** `ENT-IV-03`, `ENT-IV-09`; đọc ledger/value/cost policy facts.
- **UC:** `UC-14-01`.
- **API trace:** `API-C-21`.
- **Decision:** `T7-DR-049`, `164…170`, `194…195`.
