---
id: BC-XD-04
type: behavioral-contract
theme: theme-07
title: "Query margin comparison"
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
<a id="bc-xd-04"></a>
# BC-XD-04 — Query margin comparison

## 1. Ý định

Tách margin tại giao dịch, sau đối soát và dự kiến.

## 2. Phạm vi áp dụng

- Loại: Query
- Owner nguồn: Reporting
- Journey chính: `XREF-05 / Reporting`

## 3. Đầu vào nghiệp vụ

Product/order/period filters, as-of, financial view permission.

## 4. Điều kiện trước

Financial/report permission; consistent snapshot.

## 5. Quy tắc nghiệp vụ

Transaction margin uses initial COGS; reconciled margin adds linked true-up; projected margin uses current pricing cost basis.

## 6. Điều kiện bắt buộc

Các constraint bắt buộc là các guard và rule nguồn ở mục 4–5; migration không bổ sung invariant mới.

## 7. Ảnh hưởng trạng thái

Three labeled values with source/version/as-of; never collapsed into one accounting number.

## 9. Kết quả và semantics lỗi

`FINANCIAL_VIEW_FORBIDDEN`, `MARGIN_SOURCE_INCOMPLETE`.

## 10. Domain và UC sử dụng

- Entity/Read model: `PRJ-10`, issue/value lines, external pricing refs.
- Trace: `XREF-05`; Reporting/Analytics; outbound `SG-17`; `API-Q-03`.
