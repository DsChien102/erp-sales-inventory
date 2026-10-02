---
id: BC-IC-07
type: behavioral-contract
theme: theme-07
title: "Submit inventory operation"
owner: BA
status: FROZEN
source_baseline: v4.6.7
---
<a id="bc-ic-07"></a>
# BC-IC-07 — Submit inventory operation

## 1. Ý định

Xác lập payload submitted và định tuyến operation sang chờ duyệt hoặc sẵn sàng. Với operation risk-based, contract tính/snapshot risk theo policy. Với `QUICK_RECEIPT`, contract đồng thời **tạo receipt và submit trong một command**, luôn route sang phê duyệt và **không yêu cầu price/FX basis tại BJ02**; không yêu cầu receipt/operation đã tồn tại trước đó.

## 2. Phạm vi áp dụng

- Loại: Command
- Owner nguồn: IC + IO
- Journey chính: Cross-cutting
- Quick Receipt: create-and-submit nguyên tử; không qua BC-IO-16.

## 3. Đầu vào nghiệp vụ

### 3.1 Operation đã tồn tại

Operation ID/version, submit `idempotencyKey`, requested execution context.

### 3.2 `QUICK_RECEIPT`

Một command đầy đủ gồm:

- `idempotencyKey`;
- Supplier;
- receipt items (Product + transaction UOM + quantity classifications + LOT/HSD theo policy);
- evidence refs / ownership assertion;
- tenant/warehouse/actor context theo envelope.

**Không có `receiptId`/operation ID trong precondition.** `receiptId` chỉ được cấp sau khi command thành công.

## 4. Điều kiện trước

- Với operation đã tồn tại: lifecycle/state hiện hành cho phép submit; source/ownership/evidence current; permission/scope hợp lệ.
- Với `QUICK_RECEIPT`: Supplier/Product/UOM/LOT/evidence/ownership hợp lệ; có ít nhất một item; không duplicate Product+UOM; accepted physical > 0; ApprovalPolicy active và có eligible approver; maker–checker hợp lệ. **Price/FX basis không phải precondition.**

## 5. Quy tắc nghiệp vụ

### 5.1 Nhánh operation đã tồn tại

Khóa payload hiện hành → snapshot risk/policy → route sang `PENDING_APPROVAL` hoặc `READY` theo policy của loại operation. Các semantics draft/state hiện hành của loại operation đó giữ nguyên.

### 5.2 Nhánh `QUICK_RECEIPT`

1. Validate toàn bộ command **trước khi tạo receipt**.
2. Nếu validation/routing không đạt, reject toàn bộ command; không tạo `GoodsReceipt`, không tạo `receiptId`, không để lại business draft.
3. Nếu hợp lệ, trong cùng transaction:
   - tạo `GoodsReceipt` với immutable submitted payload;
   - cấp `receiptId`;
   - snapshot Quick Receipt policy, maker/evidence/ownership và dữ liệu nhận hàng cần cho quyết định;
   - tạo `ApprovalCase(QUICK_RECEIPT)` bind đúng payload/basis hash;
   - đặt trạng thái receipt đầu tiên = `PENDING_APPROVAL`;
   - ghi `CommandReceipt` để bảo đảm idempotency/finality.
4. Quick Receipt luôn cần approval; không hỏi người dùng có cần duyệt và không được đi thẳng `READY`.
5. Retry/recovery cùng `idempotencyKey` phải trả lại đúng outcome đã commit; không tạo receipt thứ hai.

## 6. Điều kiện bắt buộc

Các constraint bắt buộc là các guard và rule nguồn ở mục 4–5. `receiptId` của Quick Receipt không được allocate như một business receipt trước khi command create-and-submit commit thành công.

## 7. Ảnh hưởng trạng thái

- Existing operation: immutable submitted payload và route/status theo lifecycle hiện hành.
- Quick Receipt success: **non-existent → `PENDING_APPROVAL`** trong một transaction.
- Quick Receipt rejection: **non-existent → non-existent**; không có business state `DRAFT`.

## 9. Kết quả và semantics lỗi

### Quick Receipt

- `APPROVER_CONFIGURATION_MISSING` — không resolve được approver phù hợp; không tạo receipt.
- `APPROVAL_PRICE_BASIS_REQUIRED` **không thuộc nhánh Quick Receipt**; thiếu price/FX không chặn create-and-submit tại BJ02.
- Thiếu dòng/UOM/LOT/evidence hoặc duplicate Product+UOM → validation rejection của toàn command; **không trả `DRAFT_VALIDATION_FAILED`, `OPERATION_NOT_DRAFT` hoặc bất kỳ mã `DRAFT_*` nào** cho nhánh Quick Receipt.

### Operation có draft lifecycle

Các mã draft/state hiện hành của loại operation khác vẫn có thể áp dụng theo contract sở hữu; thay đổi này không sửa UC-02-01 hoặc các operation ngoài Quick Receipt.

## 10. Domain và UC sử dụng

- Entity/Read model: `ENT-IO-01/02/10`, `ENT-IC-01/02`.
- Trace: Cross-cutting `ST-02.05`, `ST-17.01`, `ST-20.01`; `SG-10`; `API-C-26`; synchronous result; [T7-DR-027](../../../01.knowledge/decisions/decision-register.md#33-g03-nh%E1%BA%ADn-h%C3%A0ng-v%C3%A0-x%C3%A1c-nh%E1%BA%ADn-gi%C3%A1-tr%E1%BB%8B).
