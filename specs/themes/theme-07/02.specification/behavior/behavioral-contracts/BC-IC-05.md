---
id: BC-IC-05
type: behavioral-contract
theme: theme-07
title: "Reconcile and rebuild projection"
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
<a id="bc-ic-05"></a>
# BC-IC-05 — Reconcile and rebuild projection

## 1. Ý định

Giải quyết `UNKNOWN`/source/projection mismatch bằng bằng chứng, rebuild từ ledger và mở khóa an toàn.

## 2. Phạm vi áp dụng

- Loại: Command
- Owner nguồn: IC
- Journey chính: `BJ-16`, `PROC-01`

## 3. Đầu vào nghiệp vụ

Case type/scope, evidence refs, operation ID/source identity, target projection/cut-off.

## 4. Điều kiện trước

Reconciliation permission; case active; scope lock; ledger integrity available.

## 5. Quy tắc nghiệp vụ

Collect evidence → resolve/continue same operation if UNKNOWN → compare ledger → rebuild projection → validate hash/counts → resolve case and unlock only when proof passes.

## 6. Điều kiện bắt buộc

Các constraint bắt buộc là các guard và rule nguồn ở mục 4–5; migration không bổ sung invariant mới.

## 7. Ảnh hưởng trạng thái

Resolved or remains unresolved/UNKNOWN; audit and rebuild evidence retained.

## 8. Tính nguyên tử và kết quả cuối

Resolved or remains unresolved/UNKNOWN; audit and rebuild evidence retained.

## 9. Kết quả và semantics lỗi

`INSUFFICIENT_EVIDENCE`, `LEDGER_INTEGRITY_FAILED`, `REBUILD_VALIDATION_FAILED`, `CASE_NOT_ACTIVE`.

## 10. Domain và UC sử dụng

- Entity/Read model: `ENT-IC-03/07`, operation/ledger/projection.
- Trace: `BJ-16`, `BJ-17`, `PROC-01`; `SG-15`; `API-C-18`.
