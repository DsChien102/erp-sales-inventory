---
id: EVD-002
type: evidence
theme: theme-06
title: Senior BA / Domain Review — Công nợ v2.1.1
owner: QA
status: IN_REVIEW
---
# EVD-002 — Senior BA / Domain Review

## 1. Perspective

Review ở góc Senior BA/Domain: có thể tái dựng được owner, boundary, ubiquitous language, lifecycle, invariant và negative scope mà không cần tự phát minh thêm Domain con hay Entity nguồn.

## 2. Kết quả

### PASS — Domain boundary

- Snapshot chỉ có một Domain canonical: `DOM-ARAP — Công nợ`.
- Nghĩa vụ/số dư, thu-chi/phân bổ, số dư đầu kỳ, cấn trừ, đối chiếu, phê duyệt và tra cứu được mô hình hóa là capability.
- Bán hàng, Mua hàng, Quản lý đối tác và Kế toán giữ ownership nguồn tương ứng.

### PASS — Entity ownership

- Partner và SourceDocument là reference, không bị tái tạo thành owner entity.
- Customer/Supplier không bị tách thành hai identity công nợ.
- Net position/read model không bị biến thành nghĩa vụ mới.
- Đối chiếu không tạo DebtAdjustment trong Phase 1.

### PASS — Business invariant

Các invariant chính truy được về Decision Register: source finality; same Partner/tenant/direction khi allocation; no over-allocation; explicit offset; maker-checker; opening balance theo từng khoản; reconciliation difference không auto-adjust; single currency Phase 1.

## 3. Findings còn mở

Không có BLOCKER/HIGH về semantic nghiệp vụ. Các điểm còn mở là Architecture `IN_REVIEW`:

1. Payment + Allocation boundary với DebtObligation.
2. Consistency khi DebtOffset chạm nhiều DebtObligation.
3. Atomicity/recovery khi finalization OpeningBalanceBatch nhiều dòng.
4. Exact lifecycle/command names sẽ được kiểm chứng khi viết UC/BC.

Các finding này không được tự giải quyết bằng persistence schema trong snapshot hiện tại.
