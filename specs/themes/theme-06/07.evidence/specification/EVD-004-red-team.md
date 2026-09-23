---
id: EVD-004
type: evidence
theme: theme-06
title: Red-team Review — Domain / Aggregate / Entity v2.1.2
owner: QA
status: IN_REVIEW
---
# EVD-004 — Red-team Review

## 1. Các tình huống đối kháng đã rà

| Tình huống | Kỳ vọng | Coverage hiện tại |
|---|---|---|
| Hai allocation đồng thời dùng cùng Payment | Không vượt payment amount | AGG-ARAP-05 nêu version/concurrency; mechanism chưa freeze |
| Hai settlement đồng thời vào cùng obligation | Outstanding không âm | AGG-ARAP-04 nêu expected version/locking; mechanism chưa freeze |
| Offset được duyệt nhưng obligation thay đổi trước execute | Không over-settle; phải revalidate | AGG-ARAP-06 yêu cầu kiểm outstanding tại commit |
| Policy đổi khi request đang chờ | Pending request không đổi route | Policy snapshot trong AGG-ARAP-02 |
| Maker tự approve | Bị chặn | T06-DR-022 / AGG-ARAP-02 |
| Duplicate source payment/handoff retry | Không tạo khoản tiền trùng | ENT-ARAP-02 / T06-DR-007,037 |
| Source correction nhỏ hơn phần đã settle | Không auto refund/reverse/adjust | T06-DR-039 / AGG-ARAP-04 `Cần xử lý` |
| Reconciliation chênh lệch | Không sửa obligation | ENT-ARAP-10 / AGG-ARAP-07 |
| UI/read model hiển thị net position | Không được coi là offset đã xảy ra | T06-DR-016 / Entity Catalog |
| Future reversal/re-allocation bị gọi ở Phase 1 | Không expose | T06-DR-015,028 |

## 2. Findings

Không phát hiện duplicate authority hoặc out-of-scope capability bị mô tả như đã triển khai. Các race/partial-commit case liên quan Payment/Obligation/Offset vẫn là finding Architecture `IN_REVIEW` và phải được đóng bằng UC/BC + technical contract trước implementation.

## 3. Verdict theo scope

Không có BLOCKER/HIGH trong phạm vi **static Domain/Entity/Aggregate candidate review**. Không suy rộng verdict này sang runtime/integration/E2E.
