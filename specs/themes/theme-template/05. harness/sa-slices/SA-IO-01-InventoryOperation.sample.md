---
id: SA-IO-01
type: sa-slice
theme: theme-07
title: Khóa ranh giới InventoryOperation Aggregate
owner: SA
status: DRAFT
sample_of: SA-SLICE.template.md
sample_status: DERIVED_SAMPLE
---
# SA-IO-01 — Khóa ranh giới InventoryOperation Aggregate

## 1. Mục tiêu

Khóa một ranh giới kiến trúc ổn định cho InventoryOperation để nhiều Use Case có thể dùng lại cùng lifecycle, invariant và Domain Operations mà không thiết kế Aggregate theo từng UC.

## 2. Loại Slice

`Aggregate`

## 3. Scope

### 3.1 Owns

- Aggregate Root và consistency boundary của InventoryOperation.
- Child entity/VO bên trong boundary.
- Lifecycle và Domain Operations.
- Optimistic concurrency và persistence boundary ở mức kiến trúc.
- Quan hệ với Foundation Idempotency và Approval capability.

### 3.2 Does not own

- Application Command/Query của từng UC.
- HTTP endpoint.
- Screen/UI.
- ApprovalPolicy/ApprovalCase internals.
- Product/Supplier master.

## 4. Nguồn đầu vào

- Domain `IO — Inventory Operations`.
- `ENT-IO-01`, `ENT-IO-02`.
- `BC-IO-16`, `BC-IC-07`.
- Invariant `INV-IO-01/02/03/09/12`, `INV-IC-12`, LOT rules liên quan.
- Decisions `T7-DR-027`, `T7-DR-072`, `T7-DR-103`, `T7-DR-104`, `T7-DR-118`, `T7-DR-121`.
- Existing Foundation `FND-01`.

## 5. Thiết kế / thay đổi kiến trúc

Tạo/khóa `AGG-IO-01 — InventoryOperation Aggregate`, làm rõ:

- `CommandReceipt` được dùng qua Foundation thay vì trở thành child của Aggregate.
- Receipt business item và technical line nằm ở đâu trong consistency boundary.
- Hành vi draft/submit nào là Aggregate behavior; orchestration approval nằm ngoài Aggregate.

## 6. Đầu ra

- `architecture/aggregates/AGG-IO-01-InventoryOperation.md`.
- Architecture tests cho lifecycle/invariant.
- Dependency contract để BE Slice consume Aggregate + FND-01.

## 7. Dependencies

- `FND-01 — Inventory Idempotency`.
- Product/UOM/tracking read dependency.
- Approval integration/capability cho submit.

## 8. Ranh giới công bố

Không công bố HTTP từ SA Slice này. Public adapter thuộc BE/Application delivery khi cần.

## 9. Verification

- Aggregate có một consistency responsibility rõ.
- Không chứa Application Command/Query theo UC.
- Quick Receipt không bypass approval lifecycle.
- Draft mutation không tạo movement.
- Version/invariant test được độc lập với UI/API.

## 10. Delivery

Sample chưa gắn branch/MR; mục tiêu là minh họa cách SA Slice đứng cạnh Architecture và được nhiều BE Slice dùng lại.
