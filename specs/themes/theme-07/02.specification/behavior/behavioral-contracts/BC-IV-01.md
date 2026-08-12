---
id: BC-IV-01
type: behavioral-contract
theme: theme-07
title: "Confirm direct receipt cost and release"
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
<a id="bc-iv-01"></a>
# BC-IV-01 — Confirm direct receipt cost and release

## 1. Ý định

Ghi direct cost cho **identified valuation scope**, chuyển đúng lượng từ `VALUATION_PENDING` sang `VALUATION_CONFIRMED` trong khi giữ nguyên physical state; sau đó tính lại availability theo toàn bộ blocker hiện hành.

## 2. Phạm vi áp dụng

- Loại: Command
- Owner nguồn: IV + IO
- Journey chính: `BJ-03`

## 3. Đầu vào nghiệp vụ

Một hoặc nhiều selected scope `{receipt_operation_line_id, receipt_item_ref, valuation_basis_key, basis_version, basis_hash, scope_key, scope_version, confirm_quantity}`; preview calculation hash; explicit complete-basis choice + reason khi conflict.

## 4. Điều kiện trước

Financial permission; receipt completed/owned; scope còn `VALUATION_PENDING`; `0 < confirm_quantity <= pending_quantity`; từng selected `basis_hash/version + scope_version` còn current; selected-set không overlap/duplicate. LOT hết hạn/blocked **không chặn valuation**; nó chỉ có thể làm availability delta bằng 0. Nếu một selected scope stale, reject toàn command nguyên tử.

## 5. Quy tắc nghiệp vụ

Server re-derive DirectCostBasis + allocation/rounding → tính authoritative allocated amount bằng cumulative partial method → persist ReceiptValuation với transaction-UOM/conversion/base normalization → append value movement dùng `business_date=receipt_business_date`, `recorded_at=commit time`, period của receipt business date → chuyển đúng balance valuation axis → authoritative availability evaluation → compare-and-create initial OfficialCostVersion theo tenant+product nếu chưa có → outbox atomically.

## 6. Điều kiện bắt buộc

Các constraint bắt buộc là các guard và rule nguồn ở mục 4–5; migration không bổ sung invariant mới.

## 7. Ảnh hưởng trạng thái

Value recorded cho exact scope; physical state không đổi; availability delta authoritative; bootstrap status theo product `INITIALIZED

## 8. Tính nguyên tử và kết quả cuối

Value recorded cho exact scope; physical state không đổi; availability delta authoritative; bootstrap status theo product `INITIALIZED

## 9. Kết quả và semantics lỗi

`PRICE_EVIDENCE_REQUIRED`, `VALUATION_BASIS_STALE`, `VALUATION_SCOPE_STALE`, `VALUATION_QUANTITY_EXCEEDS_PENDING`, `VALUATION_BASIS_CONFLICT`, `CONFIRMATION_ALREADY_APPLIED`, `CURRENCY_MISMATCH`, `ORIGINAL_PERIOD_LOCKED`.

## 10. Domain và UC sử dụng

- Entity/Read model: `ENT-IV-01/02/04`, `ENT-IO-01…04`.
- Trace: `BJ-03`; `ST-03.03`; `SG-03`; `API-C-20`; `EVT-IV-03`.
