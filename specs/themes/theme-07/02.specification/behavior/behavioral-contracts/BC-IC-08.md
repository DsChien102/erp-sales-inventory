---
id: BC-IC-08
type: behavioral-contract
theme: theme-07
title: "Cancel stock count"
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
<a id="bc-ic-08"></a>
# BC-IC-08 — Cancel stock count

## 1. Ý định

Cancel đúng session context mà không điều chỉnh tồn; giữ toàn immutable evidence và release lock.

## 2. Phạm vi áp dụng

- Loại: Command
- Owner nguồn: IC
- Journey chính: `BJ-08`

## 3. Đầu vào nghiệp vụ

Session/version, cancellation reason, command identity.

## 4. Điều kiện trước

Authorized canceller; reason bắt buộc; session chưa final; không có approval/adjustment mutation UNKNOWN đang cần reconciliation.

## 5. Quy tắc nghiệp vụ

Set session `CANCELLED` + release owned lock + persist CommandReceipt/outbox atomically; không xóa CountScopeSnapshot/Submission/ApprovalCase; không tạo adjustment.

## 6. Điều kiện bắt buộc

Các constraint bắt buộc là các guard và rule nguồn ở mục 4–5; migration không bổ sung invariant mới.

## 7. Ảnh hưởng trạng thái

`CANCELLED`, effect inventory = NONE, lock released.

## 8. Tính nguyên tử và kết quả cuối

`CANCELLED`, effect inventory = NONE, lock released.

## 9. Kết quả và semantics lỗi

`COUNT_NOT_CANCELLABLE`, `CANCELLATION_REASON_REQUIRED`, `LOCK_OWNERSHIP_MISMATCH`.

## 10. Domain và UC sử dụng

- Trace: `BJ-08`; `T7-DR-174`; `API-C-27`; `EVT-IC-05`.
