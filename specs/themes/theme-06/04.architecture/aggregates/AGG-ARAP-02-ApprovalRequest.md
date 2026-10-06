---
id: AGG-ARAP-02
type: aggregate
theme: theme-06
title: ApprovalRequest Aggregate
owner: SA
status: IN_REVIEW
---
# AGG-ARAP-02 — ApprovalRequest Aggregate

> Candidate boundary; semantic nghiệp vụ tại [ENT-ARAP-05](../../02.specification/domain/entities/ENT-ARAP-05-yeu-cau-phe-duyet.md).

## 1. Trách nhiệm

Bảo vệ maker-checker, policy snapshot và final decision của một yêu cầu phê duyệt cho đúng subject/content version.

## 2. Boundary
### 2.1 Thuộc Aggregate
- `ApprovalRequest` root.
- `PolicySnapshot` value object.
- `ApprovalDecision` record/value candidate.

### 2.2 Không thuộc Aggregate
- Live ApprovalPolicy.
- Subject Aggregate.
- User/Role master.

## 3. Aggregate Root

`approval_request_id`.

## 4. Entity / Value Object bên trong

PolicySnapshot giữ action, band, approver role và policy version áp dụng. ApprovalDecision giữ outcome, approver, thời điểm và lý do nếu nghiệp vụ yêu cầu.

## 5. Lifecycle và state transition

`PENDING → APPROVED | REJECTED` là semantic tối thiểu. Cancel/resubmit/supersede chưa freeze.

## 6. Điều kiện bắt buộc

- Maker != approver.
- Approver role khớp snapshot.
- Subject/version phải đúng cái đã submit.
- Request đã final không được quyết định lần hai.
- Không có approver hợp lệ không được auto-approve/auto-execute.

## 7. Domain Operations / Aggregate Behavior

| Operation | Ý nghĩa | Preconditions | State effect |
|---|---|---|---|
| `createRequest` | Tạo request từ subject + policy snapshot | Subject submit hợp lệ | `PENDING` |
| `approve` | Duyệt | Pending; khác maker; role phù hợp | `APPROVED` |
| `reject` | Từ chối | Pending; khác maker; role phù hợp | `REJECTED` |

## 8. Concurrency và consistency

Decision cần compare-and-set/version để hai approver đồng thời không tạo hai kết quả final.

## 9. Persistence boundary

Root + snapshot + decision audit cùng persistence boundary logic.

## 10. Domain Events

Event approval result chưa freeze; consumer subject cần idempotent/recovery contract.

## 11. Dependencies

ApprovalPolicy snapshot, User/Role reference, subject reference/version.

## 12. Consumers

OpeningBalanceBatch, DebtOffset; tương lai có thể thêm operation nếu policy bật.

## 13. Verification

Maker tự duyệt bị chặn; stale subject không được thực thi; policy live thay đổi không tác động pending request; duplicate decision bị chặn.
