---
id: AGG-IV-01
type: aggregate
theme: theme-07
title: "ReceiptValuation Aggregate"
owner: SA
status: IN_REVIEW
source_baseline: v3.12.0
---
# AGG-IV-01 — ReceiptValuation Aggregate

## 1. Trách nhiệm nghiệp vụ

Giữ một sự thật bất biến rằng **một phạm vi lượng hàng thực nhận đã được xác lập giá trị nhập ban đầu bằng căn cứ nào và với giá trị bao nhiêu**. Aggregate không tạo giá vốn chính thức.

## 2. Boundary

**Thuộc Aggregate:** `ENT-IV-01 ReceiptValuation` và snapshot/value objects của căn cứ, covered scope, UOM conversion, component provenance.

**Không thuộc Aggregate:** receipt physical facts (`DOM-IO`), PO/invoice/commercial dispute (Theme 10), `OfficialCostVersion` (BJ14).

## 3. Aggregate Root

`ReceiptValuation` (`ENT-IV-01`).

## 4. Invariant

- Covered quantity phải còn `VALUATION_PENDING` tại commit.
- Covered scope đến từ source coverage; user không tùy ý chọn một phần lượng.
- Source/basis/scope/tax/FX/allocation version phải current tại commit.
- Theme 10 conflict chưa resolve làm request không đủ điều kiện commit.
- Commit ghi initial value + valuation-state transition + exact dirty cost scope; không bootstrap Official Cost.

## 5. Hành vi chính

- `confirmInitialValue()` — recheck basis/scope, ghi `ReceiptValuation` và value movement, phát `ReceiptValuationConfirmed`.
- Retry cùng business/command identity trả lại kết quả đã commit; không tạo valuation thứ hai.

## 6. Concurrency / finality

Quantity được bảo vệ khỏi double valuation bằng scope/version + transaction/CAS theo `BC-IV-01` và `FND-TECH-01`. Timeout chưa rõ commit trả `UNKNOWN`; recovery theo CommandReceipt/finality contract.

## 7. Trace

`BJ-03` → `UC-03-01` → `BC-IV-01/05` → `ENT-IV-01` → `T7-DR-185…190`.
