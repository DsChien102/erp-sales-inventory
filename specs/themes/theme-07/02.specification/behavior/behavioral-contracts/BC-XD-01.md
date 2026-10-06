---
id: BC-XD-01
type: behavioral-contract
theme: theme-07
title: "Calculate purchase-discount scenario"
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
<a id="bc-xd-01"></a>
# BC-XD-01 — Calculate purchase-discount scenario

## 1. Ý định

Tính projected cost theo sản phẩm trước PO/goods receipt.

## 2. Phạm vi áp dụng

- Loại: Command
- Owner nguồn: Purchase planning
- Journey chính: `XREF-02 / Theme 10`

## 3. Đầu vào nghiệp vụ

Scenario period/version, projected quantities, base purchase prices, percent/amount/free-goods rules.

## 4. Điều kiện trước

Planning permission; product/currency valid; assumptions complete.

## 5. Quy tắc nghiệp vụ

Normalize benefit → calculate per-product projected cost → persist version/input hash.

## 6. Điều kiện bắt buộc

Các constraint bắt buộc là các guard và rule nguồn ở mục 4–5; migration không bổ sung invariant mới.

## 7. Ảnh hưởng trạng thái

Scenario version and projected cost; no inventory/AP/accounting mutation.

## 9. Kết quả và semantics lỗi

`SCENARIO_INPUT_INVALID`, `BENEFIT_RULE_AMBIGUOUS`, `SCENARIO_VERSION_CONFLICT`.

## 10. Domain và UC sử dụng

- Entity/Read model: External `REF-12`; not owned by inventory.
- Trace: `XREF-02`; Theme 10 — Mua hàng; `T10-UC-DS-01…04`; outbound `SG-16`; `API-X-01`.
