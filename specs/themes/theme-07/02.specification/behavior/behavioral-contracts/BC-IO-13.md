---
id: BC-IO-13
type: behavioral-contract
theme: theme-07
title: "Reverse or correct completed operation"
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
<a id="bc-io-13"></a>
# BC-IO-13 — Reverse or correct completed operation

## 1. Ý định

Tạo operation bù/sửa có liên kết, không sửa operation/ledger gốc.

## 2. Phạm vi áp dụng

- Loại: Command
- Owner nguồn: IO + IV
- Journey chính: `BJ-11`

## 3. Đầu vào nghiệp vụ

Original operation, correction type, replacement payload, reason/evidence, original period.

## 4. Điều kiện trước

Original completed; no duplicate active correction; source/permission/approval; accounting-period rule.

## 5. Quy tắc nghiệp vụ

Create new operation ID and CorrectionChain → revalidate current state → append delta/reversal movements/value → update balances atomically.

## 6. Điều kiện bắt buộc

Các constraint bắt buộc là các guard và rule nguồn ở mục 4–5; migration không bổ sung invariant mới.

## 7. Ảnh hưởng trạng thái

Original retained; new linked result; open-period accounting effect.

## 8. Tính nguyên tử và kết quả cuối

Original retained; new linked result; open-period accounting effect.

## 9. Kết quả và semantics lỗi

`CORRECTION_ALREADY_ACTIVE`, `ORIGINAL_NOT_COMPLETED`, `CORRECTION_NOT_FEASIBLE`, `PERIOD_POLICY_VIOLATION`.

## 10. Domain và UC sử dụng

- Entity/Read model: `ENT-IO-01…07`, `ENT-IV-02/05/06` as needed.
- Trace: `BJ-11`; `ST-12.03`, `ST-12.04`; `SG-10`; `API-C-13`; `EVT-IO-10`.
