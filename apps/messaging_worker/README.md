# Messaging Worker

Server-side messaging processor for VET45. Runs adaptive self-loop ticks (~3s when backlog, 15–30s idle) and exposes `GET /health` plus `POST /tick` for manual smoke tests.

## Architecture

| Component | Role |
|-----------|------|
| `messaging-worker` | HTTP + adaptive tick loop. **P1:** module binding registry + partition pool (`WORKER_CONCURRENCY`). IAM: `IamMessagingCommandFactory` → `Process{Outbox,Inbox,InternalCommands}`. |
| Supabase `platform` schema | Tenant discovery RPC (`p_limit`, `p_modules`) + backlog stats view |

Scaling playbook: [docs/operations/messaging_worker_scaling.md](../../docs/operations/messaging_worker_scaling.md).

Docker build context is the monorepo root (`apps/messaging_worker/Dockerfile`).

**Runtime env:** edit `.vet45/profiles/<profileId>/<env>.env` (not `apps/messaging_worker/.env*`), then `melos run env:sync -- --target worker` (or full `env:sync`). Key deps for the `worker` target are declared in [`vet45.target.json`](vet45.target.json). See [environment-manager.md](../../docs/operations/environment-manager.md).

**Version / changelog:** [`CHANGELOG.md`](CHANGELOG.md) — bump with [`scripts/bump_version.sh`](scripts/bump_version.sh) (see [app_versioning.md](../../docs/operations/app_versioning.md)). Tag: `messaging_worker-vX.Y.Z`.

## Prerequisites

1. Messaging migrations applied on the target Supabase project; expose `platform` schema in API settings — [messaging_schema.md](../../docs/operations/messaging_schema.md).

## Publish image

Build `linux/amd64` và push lên registry bạn chọn (chưa cấu hình hosting):

```bash
export WORKER_IMAGE=ghcr.io/<owner>/messaging-worker
./apps/messaging_worker/scripts/publish.sh --env staging            # thêm --verify để compile trước
```

Chạy local thay vì deploy: `melos run worker:serve` hoặc `melos run worker:docker`.

## Validate

```bash
curl -sf "http://localhost:8080/health"   # hoặc URL nơi bạn deploy worker
```

Expect tick log lines like:

```text
tick {"tenantsProcessed":0,"rounds":0,"durationMs":12,"errorsCount":0,"hadBacklog":false}
```

Manual `POST /tick` (ops only — do not embed secret in the ERP app):

```bash
curl -sf -X POST "https://<worker-host>/tick" \
  -H "Authorization: Bearer $WORKER_TICK_SECRET"
```

## Local development

```bash
# From repo root (recommended)
supabase start
melos run env:local
melos run env:doctor
melos run worker:serve    # dart on host
melos run worker:docker   # docker compose (AOT; tag = active env)
melos run worker:once
```

Environment manager: [docs/operations/environment-manager.md](../../docs/operations/environment-manager.md)

Verify build without deploy:

```bash
./apps/messaging_worker/scripts/verify_build.sh
```

## Deploy

Chưa cấu hình CI/CD hay hosting (GitLab/Railway/CircleCI của dự án cũ đã gỡ). Publish image thủ công: `WORKER_IMAGE=<registry>/messaging-worker ./apps/messaging_worker/scripts/publish.sh --env staging`.

### Biến môi trường (per environment)

Set in `.vet45/profiles/<profileId>/<env>.env`:

| Variable | Notes |
|----------|--------|
| `SUPABASE_URL` | Staging or production URL |
| `SUPABASE_SERVICE_ROLE_KEY` | Worker only; never ship to ERP |
| `WORKER_TICK_SECRET` | Manual `/tick` auth |
| `RESEND_API_KEY` | Required to send mail |
| `RESEND_FROM_DOMAIN` | Optional; sender domain for Resend |
| `APP_LINK_BASE_URL` | Optional; links in outbound mail |

## Đồng bộ với ERP

| Worker `--env` | ERP flavor | Supabase project |
|---|---|---|
| `staging` | `staging` (`com.dschien.erp.staging`) | Staging |
| `production` | `production` (`com.dschien.erp`) | Production |

Chỉ set `MESSAGING_CLIENT_POLL_ENABLED=false` trên ERP khi đã có worker chạy cho môi trường đó.

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/publish.sh` | Docker build `linux/amd64`, push registry only |
| `scripts/deploy.sh` | Wrapper around `publish.sh` |
| `scripts/verify_supabase.sh` | Check platform RPC + view |
| `scripts/verify_build.sh` | Local AOT compile (+ optional Docker) |
