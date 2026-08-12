---
id: BC-IC-07
type: behavioral-contract
theme: theme-07
title: "Submit inventory operation"
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
<a id="bc-ic-07"></a>
# BC-IC-07 — Submit inventory operation

## 1. Ý định

Khóa payload draft, tính policy/risk và chuyển sang chờ duyệt hoặc sẵn sàng.

## 2. Phạm vi áp dụng

- Loại: Command
- Owner nguồn: IC + IO
- Journey chính: Cross-cutting

## 3. Đầu vào nghiệp vụ

Operation ID/version, submit idempotency key, requested execution context.

## 4. Điều kiện trước

Draft valid; source/ownership/evidence current; price/FX basis đủ cho mọi dòng. Risk quantity của receipt dùng accepted physical đã chuẩn hóa base UOM; price basis là authoritative price per base UOM. Với `operation_type=QUICK_RECEIPT`, luôn phải có ApprovalPolicy active và eligible approver; không có cấu hình hoặc nhánh bỏ qua duyệt.

## 5. Quy tắc nghiệp vụ

Hash/lock payload → snapshot per-line risk và policy. Với `STATE_CHANGE`, resolve exact source balance slices + immutable `StateTransitionPolicyVersion`, tạo `StateChangeBasis`/basis hash trước khi route; source-slice ambiguous hoặc policy stale phải reject trước approval. Nếu policy state-change yêu cầu duyệt, tạo `ApprovalCase(STATE_CHANGE)` bind exact basis hash và chuyển `PENDING_APPROVAL`; nếu không cần duyệt, operation có thể `READY` nhưng **việc ghi state movement vẫn do system executor BC-IO-10**, không phải CTA riêng. `QUICK_RECEIPT` luôn tạo ApprovalCase và chuyển `PENDING_APPROVAL`; hệ thống không hỏi người dùng có cần duyệt và không được đi thẳng `READY`. CommandReceipt được ghi cùng transaction.

## 6. Điều kiện bắt buộc

Các constraint bắt buộc là các guard và rule nguồn ở mục 4–5; migration không bổ sung invariant mới.

## 7. Ảnh hưởng trạng thái

Immutable submitted payload và route/status xác định.

## 9. Kết quả và semantics lỗi

`DRAFT_VALIDATION_FAILED`, `APPROVAL_PRICE_BASIS_REQUIRED`, `APPROVER_CONFIGURATION_MISSING`, `OPERATION_NOT_DRAFT`.

## 10. Domain và UC sử dụng

- Entity/Read model: `ENT-IO-01/02/10`, `ENT-IC-01/02`.
- Trace: Cross-cutting `ST-02.05`, `ST-17.01`, `ST-20.01`; `SG-10`; `API-C-26`; synchronous result; [T7-DR-027](../../../01.knowledge/decisions/decision-register.md#33-g03-nh%E1%BA%ADn-h%C3%A0ng-v%C3%A0-x%C3%A1c-nh%E1%BA%ADn-gi%C3%A1-tr%E1%BB%8B).
