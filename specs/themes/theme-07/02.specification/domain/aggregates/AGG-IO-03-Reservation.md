---
id: AGG-IO-03
type: aggregate
theme: theme-07
title: "Reservation Aggregate"
owner: SA
status: DRAFT
source_baseline: v3.10.1
materialization: template-migration
---
# AGG-IO-03 — Reservation Aggregate

## 1. Trách nhiệm

Cam kết lượng theo source order line

## 2. Boundary

### 2.1 Thuộc Aggregate

- `Reservation` (`ENT-IO-05`).

### 2.2 Không thuộc Aggregate

Không suy diễn thêm child/boundary ngoài nội dung source; cần SA review trước khi FROZEN.

## 3. Aggregate Root

`Reservation` / `ENT-IO-05`.

## 4. Entity / Value Object bên trong

Theo Entity relation và Domain Foundation nguồn.

## 5. Lifecycle và state transition

Theo Entity/BC nguồn; không tạo transition mới trong migration.

## 6. Điều kiện bắt buộc

Theo `DOM-IO`, Entity và BC liên quan.

## 7. Domain Operations / Aggregate Behavior

Được SA materialize từ BC/UC; baseline không có file Aggregate riêng nên migration không phát minh method mới.

## 8. Concurrency và consistency

Concurrency và consistency của outcome được ghi trong work slice lúc review để implement.

## 9. Persistence boundary

Theo Entity. Schema vật lý và contract thực thi thuộc work slice lúc review để implement; không suy thêm trong Aggregate.

## 10. Domain Events

Event mapping (wire name, version) của outcome được ghi trong work slice lúc review để implement.

## 11. Dependencies

Domain/Entity/BC tương ứng.

## 12. Consumers

UC/BE Slice tham chiếu Entity/BC liên quan.

## 13. Verification

Domain invariant + BC acceptance + concurrency/finality gates.
