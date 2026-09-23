# Aggregate Catalog — Theme 10 Mua hàng

> Đây là **semantic aggregate catalog của BA**. SA có thể tách/gộp transaction boundary vật lý sau khi giữ nguyên invariant và ownership đã được BA khóa.

| ID | Root | Bên trong | Không sở hữu | Invariant chính |
|---|---|---|---|---|
| AGG-PUR-01 | `PurchaseOrder` | versions, lines, commercial terms | receipt/stock, Supplier/Product master | một NCC; confirmed revision bất biến; line qty > 0 |
| AGG-PUR-02 | `SupplierInvoice` | versions/lines, source links, qualification, payable-source reference | payable balance, stock cost ledger | upload ≠ qualified; qualified source phát đúng một lần theo version |
| AGG-PUR-03 | `SupplierReturnCase` | return lines, physical refs, commercial outcome | stock movement, payable adjustment ledger | physical ≠ commercial; one supplier; source goods traceable |
| AGG-PUR-04 | `PurchaseDiscountProgram` | program versions, scope, thresholds, benefit rules | receipts, inventory valuation | terms versioned/effective-dated; forecast không nằm trong terms |
| AGG-PUR-05 | `DiscountAssessment` | assessment versions, input refs, progress, scenarios, allocations | official cost/payable | actual vs forecast tách; no double count; traceable assumptions |

## Projection/reference catalog

- `PurchaseFulfillmentProjection` — view của BJ-02 từ receipt facts.
- `SupplierSnapshot` — snapshot tên/mã/thông tin cần thiết trên chứng từ, không phải master.
- `ProductSnapshot` / `UomSnapshot` — snapshot trình bày/đối chiếu, không phải master.
- `ReceiptReference` — pointer tới operation/line/version của Kho.
- `PayableSourceReference` / `PayableAdjustmentReference` — acknowledgement/reference từ Công nợ, không phải balance.
- `ExpectedCostSimulationReference` — kết quả mô phỏng từ Kho/Giá vốn, không phải cost owner.
