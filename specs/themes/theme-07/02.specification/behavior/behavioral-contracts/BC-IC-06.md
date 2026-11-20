---
id: BC-IC-06
type: behavioral-contract
theme: theme-07
title: "Decide approval"
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
<a id="bc-ic-06"></a>
# BC-IC-06 — Decide approval

## 1. Ý định

Ghi quyết định duyệt/từ chối theo immutable approval subject, policy snapshot và quyền hiện hành.

## 2. Phạm vi áp dụng

- Loại: Command
- Owner nguồn: IC
- Journey chính: Cross-cutting

## 3. Đầu vào nghiệp vụ

Approval case/version/scope (`OPERATION`, `LINE_EXCEPTION`, `STOCK_COUNT_VARIANCE` hoặc `STATE_CHANGE`), immutable `subject_snapshot` + `subject_snapshot_hash`, decision, mandatory rejection reason, actor. Với `STATE_CHANGE`, snapshot bắt buộc chứa `state_change_basis_id + basis_hash`.

## 4. Điều kiện trước

Actor còn quyền/phạm vi và có level ≥ `required_approval_level` đã chụp; không phải maker; case còn `PENDING`; subject snapshot/hash vẫn current; commit hợp lệ đầu tiên thắng. Với `STATE_CHANGE`, exact `StateChangeBasis`/policy/source-slice hash phải còn current tại decision; stale subject không được duyệt tiếp.

## 5. Quy tắc nghiệp vụ

Append một quyết định. Với `OPERATION`, approve/reject cập nhật operation theo policy. Với `LINE_EXCEPTION`, quyết định chỉ khóa exception của subject line. Với `STATE_CHANGE`, **APPROVE/REJECT chỉ ghi decision trên exact basis; không gọi BC-IO-10 và không mutate balance trong transaction approval**. Subject/basis đổi làm case cũ `SUPERSEDED`; system executor sau đó recheck basis độc lập ngay trước commit. Ghi audit/outbox.

## 6. Điều kiện bắt buộc

Các constraint bắt buộc là các guard và rule nguồn ở mục 4–5; migration không bổ sung invariant mới.

## 7. Ảnh hưởng trạng thái

New case/subject status; operation chỉ `READY` khi mọi required current approval đều đạt; no inventory mutation.

## 8. Tính nguyên tử và kết quả cuối

New case/subject status; operation chỉ `READY` khi mọi required current approval đều đạt; no inventory mutation.

## 9. Kết quả và semantics lỗi

`APPROVER_NOT_ELIGIBLE`, `SELF_APPROVAL_NOT_ALLOWED`, `APPROVAL_ALREADY_DECIDED`, `REJECTION_REASON_REQUIRED`.

## 10. Domain và UC sử dụng

- Entity/Read model: `ENT-IC-01/02`, `ENT-IO-01`.
- Trace: Cross-cutting `ST-02.05`, `ST-17.01`, `ST-17.02`, `ST-17.03`, `ST-17.04`; `SG-10`; `API-C-19`; `EVT-IC-04`.
