---
id: AGG-ARAP-03
type: aggregate
theme: theme-06
title: OpeningBalanceBatch Aggregate
owner: SA
status: IN_REVIEW
---
# AGG-ARAP-03 — OpeningBalanceBatch Aggregate

## 1. Trách nhiệm

Bảo vệ tính nhất quán của một đợt khởi tạo số dư đầu kỳ và các dòng trước khi chúng được xác lập thành DebtObligation.

## 2. Boundary
### 2.1 Thuộc Aggregate
- [ENT-ARAP-06 OpeningBalanceBatch](../../02.specification/domain/entities/ENT-ARAP-06-dot-so-du-dau-ky.md) root.
- [ENT-ARAP-07 OpeningBalanceLine](../../02.specification/domain/entities/ENT-ARAP-07-dong-so-du-dau-ky.md) child.

### 2.2 Không thuộc Aggregate
- Partner master.
- ApprovalRequest.
- DebtObligation được tạo sau finalization.

## 3. Aggregate Root

`opening_balance_batch_id`.

## 4. Entity / Value Object bên trong

OpeningBalanceLine gồm Partner, direction, amount, basis date, reference/description.

## 5. Lifecycle và state transition

Candidate semantic: `PREPARING → PENDING_APPROVAL? → APPROVED → FINALIZED` hoặc `REJECTED`. Exact states phụ thuộc UC-02; không dùng diagram này làm contract UI/API.

## 6. Điều kiện bắt buộc

- Có ít nhất một line hợp lệ trước submit/finalize.
- Mỗi line là một khoản còn mở; amount > 0.
- Không giả lập Sales/Purchase document.
- Sau finalization không sửa trực tiếp các line đã dùng tạo obligation.

## 7. Domain Operations / Aggregate Behavior

| Operation | Ý nghĩa | Preconditions | State effect |
|---|---|---|---|
| `maintainLines` | Chuẩn bị các khoản mở đầu kỳ | Còn mutable | Cập nhật child lines |
| `submit` | Gửi xác lập/phê duyệt | Lines hợp lệ | Chờ approval nếu policy yêu cầu |
| `finalize` | Xác lập batch và yêu cầu tạo obligations | Approval satisfied hoặc không cần approval | Finalized |

## 8. Concurrency và consistency

Root cần version khi mutable. **Chưa chốt** finalization nhiều line all-or-nothing hay saga/recovery theo line; phải có idempotency để retry không tạo obligation trùng.

## 9. Persistence boundary

Batch + lines là một consistency set trước finalization. DebtObligation là Aggregate khác.

## 10. Domain Events

Event/command tạo obligations chưa freeze; cần correlation từ line tới obligation.

## 11. Dependencies

ApprovalPolicy/Request, Partner reference, DebtObligation creation capability.

## 12. Consumers

BJ-02.

## 13. Verification

Không net Partner thành một dòng; retry finalization không tạo duplicate; rejected request không tạo obligation; line finalized không bị sửa lén.
