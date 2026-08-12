---
id: AGG-IO-08
type: aggregate
theme: theme-07
title: "ReservationGroup Aggregate"
owner: SA
status: DRAFT
source_baseline: v3.10.1
materialization: template-migration
---
# AGG-IO-08 — ReservationGroup Aggregate

## 1. Trách nhiệm

Atomic reservation scope cho một source combo line

## 2. Boundary

### 2.1 Thuộc Aggregate

- `ReservationGroup` (`ENT-IO-13`).

### 2.2 Không thuộc Aggregate

Không suy diễn thêm child/boundary ngoài nội dung source; cần SA review trước khi FROZEN.

## 3. Aggregate Root

`ReservationGroup` / `ENT-IO-13`.

## 4. Entity / Value Object bên trong

Theo Entity relation và Domain Foundation nguồn.

## 5. Lifecycle và state transition

Theo Entity/BC nguồn; không tạo transition mới trong migration.

## 6. Điều kiện bắt buộc

Theo `DOM-IO`, Entity và BC liên quan.

## 7. Domain Operations / Aggregate Behavior

Được SA materialize từ BC/UC; baseline không có file Aggregate riêng nên migration không phát minh method mới.

## 8. Concurrency và consistency

Theo `FND-TECH-01`.

## 9. Persistence boundary

Theo Entity/source technical contract; schema vật lý không được suy thêm.

## 10. Domain Events

Theo event mapping trong `FND-TECH-01`.

## 11. Dependencies

Domain/Entity/BC tương ứng.

## 12. Consumers

UC/BE Slice tham chiếu Entity/BC liên quan.

## 13. Verification

Domain invariant + BC acceptance + concurrency/finality gates.
