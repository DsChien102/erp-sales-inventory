# Messaging Worker

Server-side messaging processor for VET45. Runs adaptive self-loop ticks (~3s when backlog, 15–30s idle) and exposes `GET /health` plus `POST /tick` for manual smoke tests.

## Architecture

| Component | Role |
|-----------|------|
| `messaging-worker` (Railway) | HTTP + adaptive tick loop. **P1:** module binding registry + partition pool (`WORKER_CONCURRENCY`). IAM: `IamMessagingCommandFactory` → `Process{Outbox,Inbox,InternalCommands}`. |
| Supabase `platform` schema | Tenant discovery RPC (`p_limit`, `p_modules`) + backlog stats view |

Scaling playbook: [docs/operations/messaging_worker_scaling.md](../../docs/operations/messaging_worker_scaling.md).

Infra is versioned in [`.railway/railway.ts`](../../.railway/railway.ts) (Railway IaC). Docker build context remains the monorepo root (`apps/messaging_worker/Dockerfile`). See [`.railway/README.md`](../../.railway/README.md).

**Runtime env:** edit `.vet45/profiles/<profileId>/<env>.env` (not `apps/messaging_worker/.env*`), then `melos run env:sync -- --target worker` (or full `env:sync`). Key deps for the `worker` target are declared in [`vet45.target.json`](vet45.target.json). See [environment-manager.md](../../docs/operations/environment-manager.md).

**Version / changelog:** [`CHANGELOG.md`](CHANGELOG.md) — bump with [`scripts/bump_version.sh`](scripts/bump_version.sh) (see [app_versioning.md](../../docs/operations/app_versioning.md)). Tag: `messaging_worker-vX.Y.Z`.

## Prerequisites

1. Messaging migrations applied on the target Supabase project; expose `platform` schema in API settings — [messaging_schema.md](../../docs/operations/messaging_schema.md).
2. [Railway CLI](https://docs.railway.com/develop/cli): `railway login`
3. Repo linked once: `railway link --project VET45`

**Project Railway sạch** (chưa có project/service): làm theo [railway_messaging_worker.md](../../docs/operations/railway_messaging_worker.md) trước khi `publish`.

## First-time setup (staging)

Khi project `VET45` + service `messaging-worker` đã tồn tại. Greenfield: [railway_messaging_worker.md](../../docs/operations/railway_messaging_worker.md).

From the repo root:

```bash
cp .vet45/profiles/<profileId>/staging.env.example .vet45/profiles/<profileId>/staging.env
# Điền Supabase URL + keys

vet45 use staging
vet45 run worker publish
vet45 run railway sync-env
vet45 run railway rollout
```

First publish can also pass verify: `./apps/messaging_worker/scripts/publish.sh --env staging --verify`.

## Publish (daily)

App target only builds and pushes. Tag version comes from `pubspec.yaml`; the script also pushes the `:staging` / `:production` pointer that IaC pulls. No `railway up`, no secret push.

```bash
vet45 use staging
vet45 run worker publish
vet45 run railway rollout
```

Or:

```bash
./apps/messaging_worker/scripts/publish.sh --env staging
./apps/messaging_worker/scripts/publish.sh --env production
```

Push **secrets** from the profile (not from the worker deploy script). Knobs stay in `.railway/railway.ts`:

```bash
vet45 run railway sync-env
```

Infra-only change (no image rebuild):

```bash
cd .railway && npm install          # once: railway TypeScript SDK
vet45 run railway plan              # Node 22; active env staging/production
vet45 run railway apply
```

## Validate

```bash
curl -sf "https://messaging-worker-staging.up.railway.app/health"
railway logs --service messaging-worker --environment staging --lines 50
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

## GitLab CI (draft)

CI (khi có file) gọi `deploy.sh`: build/push registry rồi `redeploy --from-source`. File `.gitlab-ci.yml` **không** có trên branch này.

Jobs dự kiến:

- `verify:messaging_worker` — AOT compile trên thay đổi liên quan.
- `deploy:messaging_worker:staging` / `production` — **manual** deploy.

Hướng **Accepted:** GitLab build/push, Railway pull — [ADR 12](../../docs/architecture/12-railway-image-source.md). [`.railway/railway.ts`](../../.railway/railway.ts) đã `source: image`. Không `railway up` service này.

### CI/CD variables (per environment)

Set in `.vet45/profiles/<profileId>/<env>.env`; `set_secrets.sh --ci` expects the same names:

| Variable | Notes |
|----------|--------|
| `RAILWAY_TOKEN` | Project-scoped token; protected |
| `SUPABASE_URL` | Staging or production URL |
| `SUPABASE_SERVICE_ROLE_KEY` | Worker only; never ship to ERP |
| `WORKER_TICK_SECRET` | Manual `/tick` auth |
| `RESEND_API_KEY` | Optional in CI; required on Railway to send mail |
| `RESEND_FROM_DOMAIN` | Optional; sender domain for Resend |
| `APP_LINK_BASE_URL` | Optional; links in outbound mail |

Use CircleCI **contexts** `vet45-staging` / `vet45-production` for staging vs production (see [docs/operations/environments.md](../../docs/operations/environments.md)).

## Đồng bộ với ERP

| Worker `--env` | ERP flavor | Supabase project |
|---|---|---|
| `staging` | `staging` (`com.agapi.vet45.staging`) | Staging |
| `production` | `production` (`com.agapi.vet45`) | Production |

Trước khi set `MESSAGING_CLIENT_POLL_ENABLED=false` trên ERP staging/production, publish và rollout worker:

```bash
vet45 run worker publish
vet45 run railway rollout
```

## Rollback

| Situation | Action |
|-----------|--------|
| Bad deploy | Publish image version trước, rồi `vet45 run railway rollout` |
| Disable worker | `railway down --service messaging-worker --environment <env> -y` |
| Wrong secrets | `vet45 run railway sync-env` |

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/publish.sh` | Docker build `linux/amd64`, push registry only |
| `scripts/deploy.sh` | Wrapper around `publish.sh` (no Railway redeploy) |
| `scripts/set_secrets.sh` | Wrapper → `.railway/scripts/sync-env.sh` |
| `scripts/verify_supabase.sh` | Check platform RPC + view |
| `scripts/verify_build.sh` | Local AOT compile (+ optional Docker) |
| [`.railway/scripts/sync-env.sh`](../../.railway/scripts/sync-env.sh) | Profile → Railway shared + service secrets |
| [`.railway/scripts/rollout.sh`](../../.railway/scripts/rollout.sh) | Pull published images (`services.txt`) |
| [`.railway/scripts/config.sh`](../../.railway/scripts/config.sh) | `railway config plan` / `apply` via `vet45 run railway plan\|apply` |
