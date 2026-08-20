# Messaging worker scaling

Playbook vận hành cho `apps/messaging_worker`. Kiến trúc tổng quan: [architecture/07-integration-and-messaging.md](../architecture/07-integration-and-messaging.md).

## P1 — đã triển khai

### Module binding registry

Worker host đăng ký từng module qua `MessagingModuleBinding`:

| Thành phần | Vai trò |
| ---------- | ------- |
| `moduleSchema` | Khớp `platform.messaging_backlog_stats.module_schema` (vd. `iam`) |
| `mediator` | `IModuleMediator` của module — execute `ProcessOutbox` / `ProcessInbox` / `ProcessInternalCommands` |
| `commands` | `IMessagingCommandFactory` — map `queue_type` → `ICommand<bool>` |

IAM hôm nay: `IamMessagingCommandFactory` + mediator từ `IamStartup.initialize`. Module mới = thêm binding trong bootstrap, **không** sửa `MessagingWorkerLoop`.

### Discovery filter (`p_modules`)

RPC `platform.list_tenants_with_pending_messaging(p_limit, p_modules)`:

| `p_modules` | Hành vi |
| ----------- | ------- |
| `null` | Mọi module trong backlog view (ops/debug) |
| `['iam']` | Chỉ hàng backlog của module đã bind |

Worker truyền `p_modules` từ `context.boundModuleSchemas` mỗi tick — tránh poll backlog module chưa wire handler.

Draft migration: `supabase/migrations/_drafts/001_platform_list_pending_messaging_queues.sql`.

### Partition pool (`WORKER_CONCURRENCY`)

Partition key: `(tenant_id, module_schema, queue_type)`.

- **Cùng key:** xử lý tuần tự trong một tick (tránh double-claim cùng queue).
- **Khác key:** chạy song song, giới hạn `WORKER_CONCURRENCY` (default `4`, max `16`).

Claim SQL (`claimed_at` / `claim_token` + `SKIP LOCKED`) vẫn là safety net; pool in-process là hàng rào thêm.

### Knobs P1

| Env | Default | Max | Mô tả |
| --- | ------- | --- | ----- |
| `WORKER_CONCURRENCY` | `4` | `16` | Số partition group song song mỗi tick |
| `WORKER_TENANT_BATCH_SIZE` | `20` | `500` | Số hàng discovery tối đa mỗi round |
| `WORKER_MODULE_BATCH_SIZE` | `10` | `100` | Batch size truyền vào `Process*` |
| `WORKER_MAX_ROUNDS_PER_TICK` | `5` | `50` | Số round discovery lặp trong một tick |

Khai báo env: [`apps/messaging_worker/vet45.target.json`](../../apps/messaging_worker/vet45.target.json).

### Khi nào tăng `WORKER_CONCURRENCY`

- CPU worker còn headroom nhưng tick duration cao do nhiều tenant/queue khác nhau.
- Supabase connection pool chưa bão hòa (mỗi partition có thể mở RPC claim).
- **Không** tăng vô hạn: mỗi partition vẫn giữ ordering; quá nhiều connection có thể saturate Postgres.

### Verify local

```bash
cd apps/messaging_worker && dart test
melos run worker:once   # một tick với env đã sync
```

## P3 — replica shard (chưa triển khai)

> **Trạng thái:** chỉ tài liệu. Không có `WORKER_REPLICA_*` trong code hay `vet45.target.json` tại thời điểm này.

### Mục tiêu

Scale ngang khi **một process** không đủ (CPU, connection, hoặc tick latency) dù đã tối ưu P1.

### Mô hình đề xuất

```text
N replica messaging-worker (Railway)
  replica_index ∈ [0, replica_count)
  shard(tenant_id) = hashtext(tenant_id::text) % replica_count
  replica chỉ discovery/process tenant có shard == replica_index
```

Discovery RPC (tương lai) có thể thêm `p_replica_index` / `p_replica_count` hoặc filter phía worker sau khi RPC trả về.

`SKIP LOCKED` trên claim vẫn đảm bảo an toàn nếu hai replica vô tình cùng shard — nhưng **không** nên dựa vào đó làm chiến lược chính (lãng phí connection, contention).

### Env đề xuất (P3)

| Env | Ví dụ | Mô tả |
| --- | ----- | ----- |
| `WORKER_REPLICA_COUNT` | `3` | Tổng số replica |
| `WORKER_REPLICA_INDEX` | `0`, `1`, `2` | Index replica (0-based) |

### Railway checklist (khi implement P3)

1. Deploy `N` service replica cùng image, khác `WORKER_REPLICA_INDEX`.
2. Giữ `WORKER_CONCURRENCY` đồng nhất hoặc giảm per-replica để tổng connection ≤ pool budget.
3. Monitor `platform.messaging_backlog_stats` — `pending_count` không giảm → shard skew hoặc thiếu replica.
4. Rollout: tăng `N` từ 2, quan sát claim rate và DB load trước khi scale thêm.

### Rủi ro nếu thiếu shard filter

- Mọi replica discovery cùng backlog → claim contention, duplicate effort.
- Vẫn **không** double-process nhờ claim token — nhưng latency và DB load tăng.

## Liên kết

- [messaging_schema.md](messaging_schema.md) — RPC và view backlog
- [apps/messaging_worker/README.md](../../apps/messaging_worker/README.md) — deploy và local dev
- [environment-manager.md](environment-manager.md) — sync env profile
