---
id: AGG-ARAP-01
type: aggregate
theme: theme-06
title: ApprovalPolicy Aggregate
owner: SA
status: IN_REVIEW
---
# AGG-ARAP-01 — ApprovalPolicy Aggregate

> Candidate boundary; semantic nghiệp vụ dựa trên [ENT-ARAP-04](../../02.specification/domain/entities/ENT-ARAP-04-chinh-sach-phe-duyet.md) và T06-DR-018..020.

## 1. Trách nhiệm

Bảo vệ tính nhất quán của chính sách phê duyệt Công nợ theo một tenant: bật/tắt theo action, các dải giá trị và role duyệt có thể resolve được mà không chồng lấn.

## 2. Boundary
### 2.1 Thuộc Aggregate
- `ApprovalPolicy` — Aggregate Root.
- `ActionRule` — child/value object candidate.
- `ApprovalBand` — child/value object candidate.

### 2.2 Không thuộc Aggregate
- ApprovalRequest cụ thể.
- User/Role master.
- Subject cần phê duyệt (OpeningBalanceBatch, DebtOffset).

## 3. Aggregate Root

`ApprovalPolicy`, identity theo `approval_policy_id` + tenant; version cần để request snapshot chính sách áp dụng.

## 4. Entity / Value Object bên trong

`ActionRule(action_type, enabled, bands[])`; `ApprovalBand(min_amount, max_amount, approver_role)`.

## 5. Lifecycle và state transition

Version policy thay đổi theo lần cấu hình có hiệu lực. Exact draft/publish workflow chưa được UC-01-01 chốt.

## 6. Điều kiện bắt buộc

- Theo tenant.
- Band active của cùng action không chồng lấn.
- Khi action bật approval, một requested value hợp lệ phải resolve được band.
- Thay policy không retroactively thay ApprovalRequest đang chờ.

## 7. Domain Operations / Aggregate Behavior

| Operation | Ý nghĩa | Preconditions | State effect |
|---|---|---|---|
| `configureActionRule` | Cấu hình bật/tắt cho action | Có quyền cấu hình | Tạo version policy mới/cập nhật candidate state |
| `setBands` | Cấu hình dải giá trị và role | Bands hợp lệ | Thay band set |
| `resolveApprovalRule` | Xác định rule áp dụng cho action/value | Policy effective | Không đổi state; trả rule snapshot |

Tên command/API chưa freeze.

## 8. Concurrency và consistency

Cần optimistic version để tránh hai lần cấu hình ghi đè. Request phải snapshot đúng version/rule tại thời điểm submit.

## 9. Persistence boundary

Persist root + rule/band như một consistency set; không suy DB schema từ tài liệu này.

## 10. Domain Events

Chưa freeze event. Nếu cần phát `PolicyChanged`, schema/delivery thuộc architecture sau.

## 11. Dependencies

Permission/User/Role reference ngoài Domain; money scale theo tenant currency.

## 12. Consumers

BJ-01; AGG-ARAP-02 dùng policy để tạo snapshot khi submit request.

## 13. Verification

Band overlap bị chặn; gap ngoài chủ ý bị chặn; policy change không đổi pending request; permission luôn được kiểm tra dù approval disabled.
