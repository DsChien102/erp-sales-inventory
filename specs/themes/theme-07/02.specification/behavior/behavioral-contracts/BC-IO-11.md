---
id: BC-IO-11
type: behavioral-contract
theme: theme-07
title: "Dispose inventory"
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
<a id="bc-io-11"></a>
# BC-IO-11 — Dispose inventory

## 1. Ý định

Giảm physical/value cho hàng hỏng/hết hạn đã xử lý thực tế.

## 2. Phạm vi áp dụng

- Loại: Command
- Owner nguồn: IO + IV
- Journey chính: `BJ-09`

## 3. Đầu vào nghiệp vụ

Product/lot/state quantity, disposal reason/evidence, completion assertion.

## 4. Điều kiện trước

Non-sellable state; enough quantity; approval by quantity/value; confirmation.

## 5. Quy tắc nghiệp vụ

Append issue movement + value movement at effective official cost + update balance + outbox.

## 6. Điều kiện bắt buộc

Các constraint bắt buộc là các guard và rule nguồn ở mục 4–5; migration không bổ sung invariant mới.

## 7. Ảnh hưởng trạng thái

Physical/value giảm; immutable disposal trail.

## 9. Kết quả và semantics lỗi

`DISPOSAL_NOT_APPROVED`, `DISPOSAL_CONFIRMATION_REQUIRED`, `INSUFFICIENT_STOCK`.

## 10. Domain và UC sử dụng

- Entity/Read model: `ENT-IO-01…06`, `ENT-IV-02/04`, approval.
- Trace: `BJ-09`; `ST-11.03`; `SG-08`; `API-C-11`; `EVT-IV-02`.
