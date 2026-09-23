---
id: EVD-003
type: evidence
theme: theme-06
title: Delivery Simulation — Domain / Aggregate / Entity v2.1.2
owner: QA
status: IN_REVIEW
---
# EVD-003 — Delivery Simulation

## 1. Mục tiêu

Mô phỏng cách BA → SA → BE → QA sử dụng Domain/Entity/Aggregate candidate trên ba luồng đại diện, nhằm tìm điểm downstream buộc phải hỏi lại.

## 2. Sample A — Khởi tạo số dư đầu kỳ

1. BA dùng `OpeningBalanceBatch` + `OpeningBalanceLine` để mô tả một đợt cutover gồm nhiều khoản còn mở.
2. ApprovalPolicy/ApprovalRequest quyết định route phê duyệt; request giữ policy snapshot.
3. Sau khi đủ điều kiện, mỗi line cần tương ứng với một DebtObligation nguồn Opening Balance.
4. QA có thể kiểm: không giả Sales/Purchase; không nhập tổng net; maker-checker; retry không tạo obligation trùng.

**Điểm SA phải chốt:** atomicity/recovery toàn batch.

## 3. Sample B — Thu tiền và phân bổ

1. Payment ghi nhận một khoản thu có hiệu lực cho Partner.
2. Allocation nối Payment với một Receivable Obligation.
3. Invariant phải đồng thời giữ `allocated <= unallocated` và `allocated <= outstanding`.
4. QA có thể tạo race test với hai allocation đồng thời.

**Điểm SA phải chốt:** transaction/concurrency boundary Payment ↔ DebtObligation; có giữ Allocation là child của Payment hay nâng thành boundary riêng.

## 4. Sample C — Cấn trừ

1. DebtOffset giữ một Partner, các line RECEIVABLE/PAYABLE và requested amount.
2. ApprovalRequest dùng requested amount làm basis, không cộng hai phía.
3. Khi execute, outstanding của nhiều DebtObligation có thể thay đổi.
4. QA có thể kiểm cross-partner, lệch tổng hai phía, stale outstanding và duplicate execution.

**Điểm SA phải chốt:** locking/version/coordination nhiều obligations.

## 5. Kết luận

Bộ Domain/Entity/Aggregate hiện tại đủ làm input cho vòng BJ/UC chi tiết mà không bắt Design/BE tự tạo entity mới. Các câu hỏi còn lại đã được route đúng về SA/Architecture thay vì chôn vào UC/UI.
