---
id: BC-IV-03
type: behavioral-contract
theme: theme-07
title: "Công bố giá vốn chính thức"
owner: BA
status: FROZEN
source_baseline: v3.12.0
---
# BC-IV-03 — Công bố giá vốn chính thức

## 1. Ý định

Công bố các reconciliation delta cần thiết và `OfficialCostVersion` mới từ một `CostCalculationRun` đã sẵn sàng, **chỉ theo phương pháp được cấu hình ở cấp tenant**.

## 2. Phạm vi áp dụng

- **Loại:** Command.
- **Owner:** `DOM-IV`.
- **Journey / UC:** `BJ-14` / `UC-14-04`.

## 3. Đầu vào nghiệp vụ

Ready run/version, input/scope hashes, cutoff sequence, `ProductCostResult` hashes, tenant costing-policy version đã bind vào run, reviewer confirmation và requested effective time nếu policy cho phép future-effective.

## 4. Điều kiện trước

- Actor có quyền công bố.
- Run `READY_FOR_REVIEW`, chưa published/stale và không có blocker mới.
- Costing policy hiện hành còn phù hợp với policy version đã khóa trong run.
- Posting period hợp lệ.
- ProductCostResult/current baseline reconcile.
- Effective time không backdate trước publication commit theo Phase 1.

## 5. Quy tắc nghiệp vụ

1. Recheck freshness của run, scope, causes, policy và authoritative baseline.
2. Với mỗi Product, tính **incremental** COGS delta và ending-inventory delta so với amount đã authoritative-posted cùng cutoff.
3. Chỉ tạo adjustment line/value movement cho delta khác 0.
4. Chỉ dùng result của phương pháp `publishable` theo tenant policy để tạo Official Cost; comparison method không tự ghi sổ.
5. Tạo non-overlapping `OfficialCostVersion` khi có valid new basis; `effective_from` tại commit hoặc future time hợp lệ.
6. Clear đúng dirty causes đã được reconcile; cause mới không được clear ngầm.
7. Mark run `PUBLISHED` và phát outbox facts atomically.

## 6. Điều kiện bắt buộc

- BJ14 là **owner duy nhất** tạo/cập nhật `OfficialCostVersion`.
- Publication không sửa receipt, issue, sale, PO, invoice hoặc movement lịch sử.
- Rerun cùng facts/baseline phải cho delta 0.
- Stale/blocker trước commit phải dừng publication và tạo successor run qua UC-14-01 khi cần.

## 7. Ảnh hưởng trạng thái

Run `PUBLISHED`; adjustment batch/value movements nếu có; Official Cost versions thực sự tạo; exact dirty causes được clear; original transaction history giữ nguyên.

## 8. Tính nguyên tử và kết quả cuối

Publication mutation, adjustment, Official Cost, dirty-cause clearing và outbox cùng commit hoặc rollback. Timeout/finality chưa rõ phải route recovery với cùng command identity.

## 9. Kết quả và semantics lỗi

`COST_RUN_BLOCKED`, `COST_RUN_STALE`, `DIRTY_SCOPE_STALE`, `COST_RUN_ALREADY_PUBLISHED`, `ADJUSTMENT_TOTAL_MISMATCH`, `COST_EFFECTIVE_INTERVAL_OVERLAP`, `COST_EFFECTIVE_TIME_IN_PAST`.

## 10. Domain và UC sử dụng

- **Domain / Entity:** `ENT-IV-02…06`, `ENT-IV-09`, `ENT-IV-04`.
- **UC:** `UC-14-04`.
- **API/Event trace:** `API-C-22`, `EVT-IV-04`.
- **Decision:** `T7-DR-052/053`, `164…170`, `194…195`.
