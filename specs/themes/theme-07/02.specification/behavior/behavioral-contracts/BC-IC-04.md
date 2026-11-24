---
id: BC-IC-04
type: behavioral-contract
theme: theme-07
title: "Commit opening balance"
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
<a id="bc-ic-04"></a>
# BC-IC-04 — Commit opening balance

## 1. Ý định

Commit một opening batch đã chuẩn bị và duyệt, nguyên tử.

## 2. Phạm vi áp dụng

- Loại: Command
- Owner nguồn: IC + IO + IV
- Journey chính: `BJ-12`

## 3. Đầu vào nghiệp vụ

Prepared batch ID/version, approved source/control hash, commit idempotency key.

## 4. Điều kiện trước

Batch `APPROVED`; validation/control snapshot unchanged; one-store/warehouse context; activation `PREPARING`; mutation freeze; no completed batch.

## 5. Quy tắc nghiệp vụ

Recheck approved hash → create opening operation(s) → movements/balances/value/initial cost → immutable report/hash → chuyển activation sang `ACTIVE` và unlock trong cùng transaction.

## 6. Điều kiện bắt buộc

Các constraint bắt buộc là các guard và rule nguồn ở mục 4–5; migration không bổ sung invariant mới.

## 7. Ảnh hưởng trạng thái

One `COMPLETED` batch; operations/report traceable; activation `ACTIVE`; normal mutation unlocked.

## 8. Tính nguyên tử và kết quả cuối

One `COMPLETED` batch; operations/report traceable; activation `ACTIVE`; normal mutation unlocked.

## 9. Kết quả và semantics lỗi

`OPENING_BATCH_ALREADY_EXISTS`, `INVENTORY_NOT_ACTIVATED`, `CONTROL_TOTAL_MISMATCH`, `MASTER_NOT_FOUND`, `LOT_OR_EXPIRY_REQUIRED`, `MIGRATION_VALIDATION_FAILED`.

## 10. Domain và UC sử dụng

- Entity/Read model: `ENT-IC-06`, `ENT-IO-01…06`, `ENT-IV-02/04`.
- Trace: `BJ-12`; `ST-13.03`, `ST-13.04`; `SG-13`; `API-C-17`; `EVT-IC-02`.
