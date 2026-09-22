---
id: AGG-ARAP-06
type: aggregate
theme: theme-06
title: DebtOffset Aggregate
owner: SA
status: IN_REVIEW
---
# AGG-ARAP-06 — DebtOffset Aggregate

## 1. Trách nhiệm

Bảo vệ một nghiệp vụ cấn trừ explicit: cùng Partner/Tenant, hai phía cân bằng, giá trị không vượt outstanding và approval/result được truy vết.

## 2. Boundary
### 2.1 Thuộc Aggregate
- [ENT-ARAP-08 DebtOffset](../../02.specification/domain/entities/ENT-ARAP-08-can-tru-cong-no.md) root.
- [ENT-ARAP-09 DebtOffsetLine](../../02.specification/domain/entities/ENT-ARAP-09-dong-can-tru.md) child.

### 2.2 Không thuộc Aggregate
- DebtObligation referenced.
- ApprovalRequest.
- Partner master.

## 3. Aggregate Root

`debt_offset_id`.

## 4. Entity / Value Object bên trong

OffsetLine(obligation_id, side, amount). Tổng line hai phía xác định requested/effective value.

## 5. Lifecycle và state transition

Candidate semantic: `PREPARING → PENDING_APPROVAL? → APPROVED/REJECTED → EXECUTED`. Exact UNKNOWN/recovery states phải chốt với UC/architecture.

## 6. Điều kiện bắt buộc

- Một Partner, một Tenant.
- Có ít nhất một obligation mỗi phía.
- Tổng RECEIVABLE side = tổng PAYABLE side.
- Mỗi line <= outstanding tại commit.
- Requested value cho approval là giá trị cấn trừ, không tổng hai phía.

## 7. Domain Operations / Aggregate Behavior

| Operation | Ý nghĩa | Preconditions | State effect |
|---|---|---|---|
| `prepareOffset` | Chọn nghĩa vụ và amount | Candidate obligations hợp lệ | Mutable request |
| `submit` | Gửi duyệt/thực hiện | Invariants pass | Pending approval hoặc ready tùy policy |
| `executeApprovedOffset` | Ghi nhận cấn trừ | Approval satisfied; obligations còn đủ outstanding | Offset effective + yêu cầu settlement effects |

## 8. Concurrency và consistency

Execution chạm nhiều DebtObligation. Cần expected version/locking hoặc coordination để không over-settle khi obligation thay đổi sau lúc prepare/approve. Atomicity/recovery chưa freeze.

## 9. Persistence boundary

Root + lines + request/result metadata là một consistency set; outstanding vẫn thuộc DebtObligation.

## 10. Domain Events

Offset result event chưa freeze; accounting consumer có thể cần event sau commit theo T06-DR-038.

## 11. Dependencies

ApprovalPolicy/Request, DebtObligation, PartnerRef, Accounting integration.

## 12. Consumers

BJ-06.

## 13. Verification

Không auto-net; cross-partner bị chặn; two-side totals lệch bị chặn; stale outstanding không over-settle; maker-checker áp dụng khi policy yêu cầu.
