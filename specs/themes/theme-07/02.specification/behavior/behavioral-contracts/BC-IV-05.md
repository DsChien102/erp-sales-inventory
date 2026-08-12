---
id: BC-IV-05
type: behavioral-contract
theme: theme-07
title: "Build direct receipt valuation preview"
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
<a id="bc-iv-05"></a>
# BC-IV-05 — Build direct receipt valuation preview

## 1. Ý định

Trả worklist/identified scope và preview direct cost có provenance để user chọn/đối chiếu trước commit; không ghi ledger/balance.

## 2. Phạm vi áp dụng

- Loại: Query/preview
- Owner nguồn: IV + IO
- Journey chính: `BJ-03`

## 3. Đầu vào nghiệp vụ

Receipt/worklist filter hoặc selected `{receipt_item_ref/valuation_basis_key, scope_key, confirm_quantity}`; complete-basis choice/reason draft khi conflict.

## 4. Điều kiện trước

Financial permission/field masking; receipt thuộc tenant; scope tồn tại/còn pending; source components có identity/version; query không mutation.

## 5. Quy tắc nghiệp vụ

Đọc receipt commercial item + technical scopes → dựng 1..N candidate `DirectCostBasis` có component provenance → normalize VND/UOM → phân bổ discount/cost/tax/FX deterministic theo policy/version + stable scope order → tính cumulative partial preview → authoritative availability preview → trả `basis_version/basis_hash`, `scope_version`, calculation hash và normalized Official-Cost consequence.

## 6. Điều kiện bắt buộc

Các constraint bắt buộc là các guard và rule nguồn ở mục 4–5; migration không bổ sung invariant mới.

## 7. Ảnh hưởng trạng thái

Read-only worklist/scope/preview; `READY`, `CONFLICT` hoặc `WAITING_EVIDENCE`; conflict dựa complete basis, không chỉ unit price. Không tạo CommandReceipt, movement hay value; query timeout chỉ refetch an toàn.

## 8. Tính nguyên tử và kết quả cuối

Read-only worklist/scope/preview; `READY`, `CONFLICT` hoặc `WAITING_EVIDENCE`; conflict dựa complete basis, không chỉ unit price. Không tạo CommandReceipt, movement hay value; query timeout chỉ refetch an toàn.

## 9. Kết quả và semantics lỗi

`VALUATION_SCOPE_NOT_FOUND`, `PRICE_EVIDENCE_REQUIRED`, `VALUATION_BASIS_CONFLICT`, `FINANCIAL_FIELD_FORBIDDEN`.

## 10. Domain và UC sử dụng

- Entity/Read model: Read `ENT-IO-02/04/06`, staged receipt evidence và `ENT-IV-01` để biết phần đã xác nhận.
- Trace: `BJ-03`; `ST-03.01`, `ST-03.02`; `API-Q-11`.
