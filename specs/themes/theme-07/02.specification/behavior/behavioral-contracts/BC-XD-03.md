---
id: BC-XD-03
type: behavioral-contract
theme: theme-07
title: "Review pricing basis after cost publication"
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
<a id="bc-xd-03"></a>
# BC-XD-03 — Review pricing basis after cost publication

## 1. Ý định

Route review by current source type after new official cost.

## 2. Phạm vi áp dụng

- Loại: Command
- Owner nguồn: Pricing
- Journey chính: `XREF-04 / Theme 2`

## 3. Đầu vào nghiệp vụ

Official cost event/version, product set, decisions (`UPDATE`, `KEEP`, `USE_OFFICIAL`, `RECALCULATE_SCENARIO`).

## 4. Điều kiện trước

Pricing permission; current basis provenance available; event idempotent.

## 5. Quy tắc nghiệp vụ

Group official-source items for selectable bulk update; require per-item decision for projected-source items; create basis versions/drafts only.

## 6. Điều kiện bắt buộc

Các constraint bắt buộc là các guard và rule nguồn ở mục 4–5; migration không bổ sung invariant mới.

## 7. Ảnh hưởng trạng thái

Review decisions and new drafts; selling price unchanged.

## 9. Kết quả và semantics lỗi

`PRICING_PROVENANCE_MISSING`, `PROJECTED_SOURCE_DECISION_REQUIRED`, `REVIEW_ALREADY_APPLIED`.

## 10. Domain và UC sử dụng

- Entity/Read model: External review/basis/draft; read `ENT-IV-04`.
- Trace: `XREF-04`; Theme 2 — Sản phẩm; `T2-UC-PR-01…04`; outbound `SG-17`; `API-X-03`; `EVT-XD-02`.
