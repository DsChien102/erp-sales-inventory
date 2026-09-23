# AGG-PUR-01 — Đơn mua (`PurchaseOrder`)

**Status:** `PROPOSED_UNFROZEN`

## Mục đích

Giữ cam kết thương mại có phiên bản giữa tổ chức và một NCC, làm nguồn cho Kho biết phạm vi được nhận theo chứng từ và cho Mua hàng theo dõi fulfillment.

## Root và thành phần

- `PurchaseOrder` — logical identity xuyên các revision.
- `PurchaseOrderVersion` — snapshot điều khoản bất biến sau xác nhận.
- `PurchaseOrderLine` — product + UOM + ordered quantity + commercial price/terms.
- `PurchaseOrderTerm` — điều kiện giao/thanh toán/tham chiếu nếu cần; scope chi tiết chưa khóa.

## Lifecycle đề xuất

`Nháp → Có hiệu lực → Đã đóng` hoặc `Đã hủy`.

“Đã nhận một phần/đang giao” nên là **derived fulfillment state**, không buộc thành root lifecycle status.

## Invariant

1. Một root thuộc đúng một NCC.
2. Một version có ít nhất một line hợp lệ.
3. Quantity phải > 0; UOM phải có reference hợp lệ tại thời điểm tạo version.
4. Version đã xác nhận là bất biến; sửa tạo version mới.
5. Kho chỉ được dùng version có hiệu lực theo contract để nhận theo chứng từ.
6. Đơn mua không làm tăng tồn và không tạo payable.
7. Giảm/hủy quantity không được làm biến mất receipt đã xảy ra; chênh lệch phải đi qua quyết định/reconciliation.

## Handoff

**Ra Kho:** order_id, order_version, supplier_id, lines, product/uom, allowed/open quantity, valid state/effective info.

**Từ Kho:** receipt operation/line/version, actual quantities/classification, correction/reversal relation.

## Câu hỏi mở

- Q-10 approval/permission.
- Detail policy cho over-receive/under-receive và close line.
- Payment/shipping terms nào bắt buộc ở Phase đầu.
