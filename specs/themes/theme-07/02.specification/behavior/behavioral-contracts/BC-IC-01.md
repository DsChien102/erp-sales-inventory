---
id: BC-IC-01
type: behavioral-contract
theme: theme-07
title: "Open stock count"
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
<a id="bc-ic-01"></a>
# BC-IC-01 — Open stock count

## 1. Ý định

Tạo frozen scope và exact book cut-off dưới một atomic count barrier.

## 2. Phạm vi áp dụng

- Loại: Command
- Owner nguồn: IC
- Journey chính: `BJ-08`

## 3. Đầu vào nghiệp vụ

Warehouse, scope type/filter, count reason, assigned counter context/version, idempotency identity.

## 4. Điều kiện trước

Permission; no conflicting lock/session; scope valid/non-empty; assigned counter valid; không physical key nào có `VALUATION_PENDING`/mixed valuation-state quantity.

## 5. Quy tắc nghiệp vụ

Normalize/resolve `CountScopeSnapshot` → acquire scope barrier → serialize/chờ in-flight mutation thuộc scope → chốt cutoff ledger sequence → materialize PhysicalCountKey/book snapshot tại cutoff → persist scope/session/lines/lock + receipt atomically.

## 6. Điều kiện bắt buộc

Các constraint bắt buộc là các guard và rule nguồn ở mục 4–5; migration không bổ sung invariant mới.

## 7. Ảnh hưởng trạng thái

`OPEN/LOCKED`, immutable `scope_hash`, cutoff, lock identity và count lines theo base UOM.

## 8. Tính nguyên tử và kết quả cuối

`OPEN/LOCKED`, immutable `scope_hash`, cutoff, lock identity và count lines theo base UOM.

## 9. Kết quả và semantics lỗi

`COUNT_SCOPE_EMPTY`, `LOCK_CONFLICT`, `COUNT_ALREADY_ACTIVE`, `COUNT_SCOPE_HAS_UNRESOLVED_VALUATION`, `COUNT_ACTOR_NOT_ASSIGNED`.

## 10. Domain và UC sử dụng

- Entity/Read model: `ENT-IC-03/04/05/08`, read balances.
- Trace: `BJ-08`; `T7-DR-171…173`; `API-C-14`.
