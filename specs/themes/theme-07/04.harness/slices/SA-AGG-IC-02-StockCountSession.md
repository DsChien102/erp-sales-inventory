---
id: SA-AGG-IC-02
type: sa-slice
theme: theme-07
title: "StockCountSession Aggregate"
owner: SA
status: DRAFT
source_baseline: v3.10.1
materialization: template-migration
---
# SA-AGG-IC-02 — StockCountSession Aggregate

## 1. Mục tiêu

Materialize/verify architecture boundary của `AGG-IC-02` từ nguồn Domain/Entity hiện có.

## 2. Loại Slice

Aggregate

## 3. Scope

### 3.1 Owns

Aggregate architecture và invariants kỹ thuật.

### 3.2 Does not own

Business semantics của Domain/Entity/UC.

## 4. Nguồn đầu vào

- `DOM-IC`
- `ENT-IC-04`
- `FND-TECH-01`

## 5. Thiết kế / thay đổi kiến trúc

Xem `AGG-IC-02`.

## 6. Đầu ra

Aggregate architecture artifact + implementation boundary khi triển khai.

## 7. Dependencies

`FND-TECH-01`.

## 8. Ranh giới công bố

Theo BC/API/Event nguồn; không phát minh interface mới.

## 9. Verification

Invariant/concurrency/finality tests tương ứng.

## 10. Delivery

Chưa implementation trong baseline; Slice được materialize theo template.
