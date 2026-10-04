---
id: PRJ-07
type: read-model
theme: theme-07
title: ValuationWorkbenchView
owner: SA
status: IN_REVIEW
source_baseline: v3.12.0
---
# PRJ-07 — ValuationWorkbenchView

## 1. Mục đích

Projection phục vụ công việc valuation/costing mà không buộc UI đọc trực tiếp aggregate kỹ thuật. Read model trả lời ba câu hỏi:

1. Hàng nào còn chờ xác lập giá trị ban đầu và vì sao?
2. Điều chỉnh giá trị nào đã/đang cần xử lý và ảnh hưởng Product/kỳ nào?
3. Product/kỳ nào cần tính lại hoặc đang có cost run/blocker nào?

Read model không phải nguồn authority để commit.

## 2. Các nhóm dữ liệu

### 2.1 Initial-value work item

- mục hàng nhận / Product / transaction UOM / quantity còn `VALUATION_PENDING`;
- Phiếu nhận hàng type: document hoặc Quick;
- basis readiness: `READY`, `NEEDS_RECONCILIATION`, `MISSING_BASIS`;
- source summary đủ để người dùng hiểu việc cần làm; không expose `basis_hash` như product copy;
- current scope/basis version token cho command recheck.

### 2.2 Value-adjustment work item

- source component, signed amount, source/evidence summary;
- target phiếu nhận hàng/value exposure;
- allocation readiness/method/result;
- original/posting period;
- exact Product + posting-period dirty consequence.

### 2.3 Cost work item

- run type, calculation/posting period, scope origin/hash;
- tenant costing method snapshot (read-only) và comparison method result;
- Product count, blocker count, dirty-scope count;
- run status, successor relationship, calculated/published time;
- ProductCostResult summaries khi cần drill-down.

## 3. Nguồn dữ liệu

- `ReceiptValuation`, valuation-state balances và phiếu nhận hàng references.
- `ValueAdjustmentSource/Allocation`, `ValuationAdjustmentBatch/Line`.
- `CostCalculationRun`, `ProductCostResult`, `OfficialCostVersion`.
- Tenant policy/reference chỉ được project theo version đã bind; projection không sở hữu policy.

## 4. Projection rules

- `MISSING_BASIS` không đồng nghĩa “thiếu hóa đơn”; Quick có thể dùng direct price basis.
- `NEEDS_RECONCILIATION` chỉ khi nguồn hợp lệ nhưng có conflict cần owner xử lý; commercial dispute Theme 10 phải giữ owner Theme 10.
- Costing method hiển thị là policy fact, không phải selectable option.
- Dirty scope là system-owned; projection không cho client suy quyền bỏ Product khỏi scope.
- `OfficialCostVersion` chỉ xuất hiện sau BJ14 publication.

## 5. Consistency và freshness

Mọi mutation dùng token/version từ source aggregate và recheck trong command transaction. Projection có thể eventual; UI phải refresh khi server trả stale/conflict.

## 6. Query và paging

Query worklist theo tenant, BJ/task type, status, Product/supplier/reference và period. Cursor/paging ổn định; filter không thay đổi authority của scope.

## 7. Rebuild

Projection phải dựng lại được từ ledger/aggregate facts theo `PROC-01`. Rebuild không tạo ReceiptValuation, ValueAdjustment hoặc Official Cost mới.

## 8. Verification

- Quick initial-value task tồn tại khi không có Theme 10 source.
- Không có task copy “thiếu hóa đơn” thành blocker bắt buộc BJ03.
- Signed negative adjustment hiển thị đúng.
- Tenant costing method luôn read-only.
- Projection stale bị command layer từ chối, không silently commit.
