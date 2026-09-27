---
id: NFR-01
type: nfr
theme: theme-07
title: "Performance, capacity, durability & observability"
owner: SA
status: FROZEN
source_baseline: v3.10.1
---
# NFR-01 — Performance, capacity, durability & observability

## 1. Yêu cầu

### 12.1 SLO

- Availability `p95 ≤ 300 ms` at normal load.
- Reserve/issue `p95 ≤ 1 s`, `p99 ≤ 2 s`.
- 100 concurrent sessions/tenant; 50 inventory mutations/second; 10M movement lines/year minimum.
- Batch/report lớn chạy async với progress/cancel khi hợp đồng cho phép; **cost calculation run không có cancel trong Phase 1** và rerun dùng successor ID.

### 12.2 Metrics

`operation_started/completed/rejected/unknown`, latency by BC/error, balance lock wait/deadlock, idempotency replay/mismatch, lot conflict, approval wait, count lock duration, cost blockers/run duration, outbox lag/retry/dead-letter, reconciliation age, projection sequence lag, rebuild duration/result.

### 12.3 Trace/log

Trace attributes: `tenant_id`, `operation_id`, `bc_id`, `operation_request_id_hash`, `idempotency_key_hash`, `source_type/id/version`, `warehouse_id`, `aggregate_id/version`, `ledger_sequence`, `event_id`, `correlation_id`. Không ghi raw sensitive payload.

### `PERFORMANCE_SLO` — Mục tiêu độ trễ

- Availability ở tải chuẩn: `p95 ≤ 300 ms`.
- Giữ/xuất: `p95 ≤ 1 s`, `p99 ≤ 2 s`.
- Batch lớn chạy bất đồng bộ; không dùng timeout của client để kết luận operation thất bại.
- **Chủ trì:** Solution Architect. **Phối hợp:** Platform Lead.

<a id="nfr-nang-luc-xu-ly"></a>
### `CAPACITY_TARGET` — Mục tiêu năng lực xử lý

- Tối thiểu 100 phiên đồng thời trên mỗi tenant.
- Tối thiểu 50 operation thay đổi tồn mỗi giây.
- Tối thiểu 10 triệu movement line mỗi năm trên mỗi tenant.
- Tải cao không được gây trùng hoặc mất movement.
- **Chủ trì:** Solution Architect. **Phối hợp:** Platform Lead.

<a id="durability-rpo-va-rebuildability"></a>
### `DURABILITY_RPO` — Độ bền, RPO và khả năng dựng lại

- Operation đã Hoàn tất, ledger, số dư giao dịch và outbox đã commit có `RPO = 0`.
- Projection phải dựng lại được từ ledger; việc dựng lại không tạo authority hoặc finality mới.
- **Chủ trì:** Solution Architect. **Phối hợp:** Platform Lead.

## 2. Phạm vi áp dụng

Theme 07 runtime/API/event/projection theo source v3.10.1.

## 3. Chỉ số / ngưỡng mục tiêu

Giữ nguyên các SLO/capacity/RPO trong mục 1.

## 4. Ảnh hưởng kiến trúc

Theo technical contracts và read model/rebuild boundaries nguồn.

## 5. Cách kiểm tra

Theo quality gates/metrics của source technical contract.

## 6. Evidence mong đợi

Metrics, load/runtime test, recovery/rebuild evidence tương ứng.
