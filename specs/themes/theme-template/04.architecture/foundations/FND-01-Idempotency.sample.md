---
id: FND-01
type: foundation
theme: theme-07
title: Inventory Idempotency
owner: SA
status: FROZEN_FOR_SAMPLE
sample_of: FOUNDATION.template.md
sample_status: DERIVED_FROM_S01
---
# FND-01 — Inventory Idempotency

> Sample này chuyển cấu trúc của `S01-FND — Foundation Idempotency` cũ sang template mới; không thay đổi cơ chế đã mô tả trong S01.

## 1. Vấn đề cần giải quyết

Cho phép mọi inventory mutation an toàn dưới client/worker retry: cùng thao tác logic không tạo side effect trùng; cùng key nhưng payload khác bị từ chối.

## 2. Scope

### 2.1 Owns

- Idempotency record theo `(tenant, command_scope, idempotency_key)`.
- Begin/complete protocol trong transaction của owning mutation.
- Replay cùng key+hash.
- Conflict khi cùng key khác hash.
- `in_progress` / `uncertain` semantics.

### 2.2 Does not own

- Business Aggregate của Inventory.
- `operation_request_id`.
- Business movement/balance/outbox payload.
- Public Begin/Complete command riêng.

## 3. Execution protocol

1. Owning mutation gọi begin với idempotency key + payload hash.
2. `new` → chạy business mutation.
3. `replay` → trả result snapshot cũ.
4. `conflict` → `IDEMPOTENCY_CONFLICT`, không mutation.
5. `in_progress/uncertain` → không chạy lại như command mới.
6. Complete record cùng commit set với business result.

## 4. Technical model / state

`in_progress → succeeded | failed | uncertain`.

Record giữ tenant, command scope, key, payload hash, status, result identity/snapshot, correlation và timestamps/TTL.

## 5. Shared boundary / usage contract

Mọi mutation inventory dùng Foundation này; consumer không tự tạo cơ chế idempotency riêng.

## 6. Failure và recovery

- `IDEMPOTENCY_CONFLICT` — same key, different hash.
- `in_progress` — wait/poll, không double-execute.
- `uncertain` — tiếp tục bằng cùng identity; không coi là failed.

## 7. Concurrency / transaction semantics

Begin → business mutation → complete phải nằm trong owning transaction khi kết quả authoritative được commit. Không mark `succeeded` trước business commit.

## 8. Consumers

Mọi BE Slice mutation inventory, bao gồm maintain/submit Quick Receipt.

## 9. Verification

- Same key + same hash → replay.
- Same key + different hash → conflict.
- Concurrent begin không tạo hai business effects.
- `uncertain` không bị xử lý như request mới.
- Foundation status và business result không bị commit lệch nhau.
