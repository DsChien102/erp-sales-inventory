# AGG-PUR-03 — Hồ sơ trả nhà cung cấp (`SupplierReturnCase`)

**Status:** `PROPOSED_UNFROZEN`

## Mục đích

Giữ quyết định thương mại về hàng cần trả NCC và đối chiếu hai luồng kết quả độc lập: vật lý từ Kho và thương mại từ NCC/Công nợ.

## Root và thành phần

- `SupplierReturnCase` — root hồ sơ.
- `SupplierReturnLine` — product/UOM/quantity và nguồn hàng đã nhận.
- `ReturnSourceAllocation` — relation tới receipt/product/UOM/LOT khi cần bàn giao Kho.
- `PhysicalHandoverReference` — reference kết quả Kho, không phải stock movement.
- `CommercialOutcome` — NCC accepted/rejected/partial + evidence/value.
- `PayableAdjustmentReference` — acknowledgement/reference downstream khi có.

## Hai trục trạng thái

**Physical:** `Chưa bàn giao → Đang xử lý → Đã bàn giao | Không thể bàn giao | Đã đảo`.

**Commercial:** `Chờ NCC → Đã chấp nhận | Chấp nhận một phần | Từ chối | Tranh chấp`.

Overall case state được suy ra từ hai trục + policy; không ép một state machine tuyến tính làm mất thông tin.

## Invariant

1. Một case thuộc một NCC.
2. Hàng đề nghị trả phải truy được về nguồn hàng có thật hoặc policy cho phép khác.
3. Kho không tự sửa quantity/lô thương mại sau khi request đã có hiệu lực; thay đổi tạo version/source mới.
4. `PhysicalHandover = completed` không tự tạo `CommercialOutcome = accepted`.
5. Giá trị xuất kho không mặc nhiên bằng commercial credit.
6. Điều chỉnh payable chỉ từ source thương mại đủ điều kiện theo contract được chốt.

## Blocker

Q-06 và Q-10.
