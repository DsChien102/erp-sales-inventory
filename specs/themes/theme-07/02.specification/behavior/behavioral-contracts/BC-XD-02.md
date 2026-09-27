---
id: BC-XD-02
type: behavioral-contract
theme: theme-07
title: "Publish pricing cost basis and draft"
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
<a id="bc-xd-02"></a>
# BC-XD-02 — Publish pricing cost basis and draft

## 1. Ý định

Publish basis source official/projected and create floor/list price draft.

## 2. Phạm vi áp dụng

- Loại: Command
- Owner nguồn: Pricing
- Journey chính: `XREF-03 / Theme 2`

## 3. Đầu vào nghiệp vụ

Product, source type/version/value, effective time, pricing policy version.

## 4. Điều kiện trước

Pricing permission; source exists/not stale; source type allowed.

## 5. Quy tắc nghiệp vụ

Create basis version with provenance → calculate draft floor/list → no price publication.

## 6. Điều kiện bắt buộc

Các constraint bắt buộc là các guard và rule nguồn ở mục 4–5; migration không bổ sung invariant mới.

## 7. Ảnh hưởng trạng thái

PricingCostBasisVersion and pricing draft.

## 9. Kết quả và semantics lỗi

`PRICING_SOURCE_INVALID`, `PRICING_SOURCE_VERSION_STALE`, `PRICING_POLICY_MISSING`.

## 10. Domain và UC sử dụng

- Entity/Read model: External `REF-12/13/14`; read official cost `ENT-IV-04`.
- Trace: `XREF-03`; Theme 2 — Sản phẩm; outbound `SG-16`; `API-X-02`; `EVT-XD-01`.
