---
id: BC-IO-04
type: behavioral-contract
theme: theme-07
title: "Complete online POS checkout"
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
<a id="bc-io-04"></a>
# BC-IO-04 — Complete online POS checkout

## 1. Ý định

Hoàn tất bán tại quầy online, xuất lượng và ghi initial COGS nguyên tử.

## 2. Phạm vi áp dụng

- Loại: Command
- Owner nguồn: IO + IV
- Journey chính: `BJ-05 / UC-05-05` provider; `XREF-01` consumer

## 3. Đầu vào nghiệp vụ

Checkout/version/request ID, product/component lines, sold quantity, price context from Sales, lot scan optional/required by mode.

## 4. Điều kiện trước

Server reachable; enough current availability; valid lot/FEFO override; permission; official cost version exists or defined safe rule for new product.

## 5. Quy tắc nghiệp vụ

Lock sorted keys → allocate lot FEFO/FIFO → append issue movements → update balance → append value issue with official cost snapshot → outbox.

## 6. Điều kiện bắt buộc

Các constraint bắt buộc là các guard và rule nguồn ở mục 4–5; migration không bổ sung invariant mới.

## 7. Ảnh hưởng trạng thái

Completed checkout inventory result, lot allocation, initial COGS references.

## 8. Tính nguyên tử và kết quả cuối

Completed checkout inventory result, lot allocation, initial COGS references.

## 9. Kết quả và semantics lỗi

`INSUFFICIENT_AVAILABLE`, `LOT_NOT_ELIGIBLE`, `LOT_REQUIRED`, `COST_VERSION_MISSING`, `IDEMPOTENCY_PAYLOAD_MISMATCH`.

## 10. Domain và UC sử dụng

- Entity/Read model: `ENT-IO-01/02/03/04/06`, `ENT-IV-02/04`.
- Trace: `BJ-05 / UC-05-05` là provider authority; `XREF-01 / T5-BJ-CHECKOUT-POS` là consumer; UI active `SG-06`, UI outbound `SG-05`; `API-C-04`; `EVT-IO-03`.
