---
id: ENT-ARAP-04
type: business-entity
theme: theme-06
title: Chính sách phê duyệt
owner: BA/SA
status: IN_REVIEW
---
# ENT-ARAP-04 — Chính sách phê duyệt

## 1. Ý nghĩa nghiệp vụ

Cấu hình theo từng tổ chức quyết định một loại thao tác Công nợ có cần phê duyệt hay không và nếu cần thì role nào phê duyệt theo dải giá trị.

## 2. Domain sở hữu

Domain Công nợ sở hữu chính sách phê duyệt cho các thao tác thuộc Công nợ trong phạm vi hiện tại. Nếu platform sau này có Approval Domain dùng chung, ownership có thể được refactor bằng contract rõ ràng; snapshot này không giả định điều đó.

## 3. Identity

`approval_policy_id` theo tenant; policy cần version/effective identity để ApprovalRequest có thể giữ snapshot áp dụng.

## 4. Thuộc tính nghiệp vụ chính

| Thuộc tính | Ý nghĩa | Bắt buộc | Ghi chú |
|---|---|---:|---|
| `approval_policy_id` | Định danh policy | Có | Theo tổ chức |
| `tenant_id` | Tổ chức | Có | Policy không dùng chung tenant |
| `policy_version` | Phiên bản policy | Có | Phục vụ snapshot |
| `action_rules` | Quy tắc theo loại thao tác | Có | Bật/tắt + dải giá trị |
| `effective_from` | Mốc áp dụng | Khi cần | Exact time semantics do SA chốt |

`ApprovalBand` là child/value object candidate gồm `min_amount`, `max_amount`, `approver_role`; các band active của một action không được chồng lấn và phải đủ để resolve giá trị cần duyệt.

## 5. Quan hệ

Một ApprovalPolicy được nhiều ApprovalRequest tham chiếu qua policy snapshot/version; policy thay đổi không làm đổi request đang chờ.

## 6. Lifecycle / trạng thái

Có thể có nhiều version theo thời gian; lifecycle/versioning chi tiết sẽ chốt khi UC-01-01 được đặc tả.

## 7. Quy tắc và Điều kiện bắt buộc

- Theo tenant.
- Có thể bật/tắt theo action type.
- Hỗ trợ 1..N dải giá trị.
- Dải active không chồng lấn và resolve được giá trị cần duyệt.
- Tắt approval không bỏ permission check.

## 8. Behavioral Contract / Use Case liên quan

UC-01-01 dự kiến. Aggregate candidate: [AGG-ARAP-01](../../../04.architecture/aggregates/AGG-ARAP-01-ApprovalPolicy.md).
