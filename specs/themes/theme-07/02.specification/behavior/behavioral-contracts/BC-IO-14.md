---
id: BC-IO-14
type: behavioral-contract
theme: theme-07
title: "Query low stock suggestions"
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
<a id="bc-io-14"></a>
# BC-IO-14 — Query low stock suggestions

## 1. Ý định

Hiển thị low/out-of-stock và lượng gợi ý đơn giản.

## 2. Phạm vi áp dụng

- Loại: Query
- Owner nguồn: IO
- Journey chính: `BJ-01`

## 3. Đầu vào nghiệp vụ

Product filters, warehouse mặc định, threshold/target config, sort/page.

## 4. Điều kiện trước

View permission; config non-negative and target coherent.

## 5. Quy tắc nghiệp vụ

Read Product-level availability. `stock_level_status`: `OUT` if 0, `LOW` if `0<available≤threshold`, `NORMAL` otherwise, hoặc `NOT_CONFIGURED` khi thiếu policy. `expiry_attention` được derive độc lập từ LOT (`NONE/NEAR_EXPIRY_WARN/NEAR_EXPIRY_BLOCKED/HAS_EXPIRED_STOCK`). Suggestion = `max(0,target−available)` chỉ khi cấu hình hợp lệ.

## 6. Điều kiện bắt buộc

Các constraint bắt buộc là các guard và rule nguồn ở mục 4–5; migration không bổ sung invariant mới.

## 7. Ảnh hưởng trạng thái

Derived rows + `query_as_of`; stock-level và expiry attention không bị ép vào một enum duy nhất; không proposal ID hoặc mutation.

## 9. Kết quả và semantics lỗi

`REPLENISHMENT_CONFIG_INVALID`; missing config marked `NOT_CONFIGURED`, threshold/target không được tự điền mặc định.

## 10. Domain và UC sử dụng

- Entity/Read model: `PRJ-08`, reference product/warehouse config.
- Trace: `BJ-01`; `SG-12`; `API-Q-02`.
