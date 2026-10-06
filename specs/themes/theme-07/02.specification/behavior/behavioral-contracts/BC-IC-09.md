---
id: BC-IC-09
type: behavioral-contract
theme: theme-07
title: "Prepare opening balance batch"
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
<a id="bc-ic-09"></a>
# BC-IC-09 — Prepare opening balance batch

## 1. Ý định

Nạp, chuẩn hóa, kiểm tra và gửi duyệt opening batch trước commit.

## 2. Phạm vi áp dụng

- Loại: Command
- Owner nguồn: IC
- Journey chính: `BJ-12`

## 3. Đầu vào nghiệp vụ

Baseline/cut-off, source file/hash, normalized lines, control totals, command idempotency key.

## 4. Điều kiện trước

Permission; activation `PREPARING`; no completed batch; master/UOM/tracking valid; mutation freeze active.

## 5. Quy tắc nghiệp vụ

Persist staging/version → validate all lines/control totals → on valid submit create approval snapshot; không ledger/value/unlock.

## 6. Điều kiện bắt buộc

Các constraint bắt buộc là các guard và rule nguồn ở mục 4–5; migration không bổ sung invariant mới.

## 7. Ảnh hưởng trạng thái

`VALIDATION_FAILED`, `DRAFT`, hoặc `PENDING_APPROVAL/APPROVED` qua generic approval route.

## 8. Tính nguyên tử và kết quả cuối

`VALIDATION_FAILED`, `DRAFT`, hoặc `PENDING_APPROVAL/APPROVED` qua generic approval route.

## 9. Kết quả và semantics lỗi

`CONTROL_TOTAL_MISMATCH`, `MASTER_NOT_FOUND`, `LOT_OR_EXPIRY_REQUIRED`, `MIGRATION_VALIDATION_FAILED`.

## 10. Domain và UC sử dụng

- Entity/Read model: `ENT-IC-06`, `ENT-IC-01/02`, `ENT-IO-10`; staging only.
- Trace: `BJ-12`; `ST-13.01`, `ST-13.02`; `SG-13`; `API-C-28`; synchronous result.
