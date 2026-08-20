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

1. Migration `supabase/migrations/20260621100001_platform_messaging_discovery.sql` applied; expose `platform` schema in Supabase API settings.
2. [Railway CLI](https://docs.railway.com/develop/cli): `railway login`
3. Repo linked once: `railway link --project VET45`

## First-time setup (staging)

From the repo root:

```bash
cp .vet45/profiles/<profileId>/staging.env.example .vet45/profiles/<profileId>/staging.env
# Điền Supabase URL + keys

melos run env:use:staging
melos run env:sync
./apps/messaging_worker/scripts/deploy.sh --env staging --verify --secrets
```

## Redeploy (daily)

Code-only redeploy (no secret push) — active env phải là `staging` hoặc `production`:

```bash
melos run env:use:staging
melos run deploy:worker
```

Hoặc:

```bash
./apps/messaging_worker/scripts/deploy.sh
./apps/messaging_worker/scripts/deploy.sh --env production
```

Push **secrets** when they change (Supabase, tick secret, Resend). Worker knobs are owned by IaC — do not set them via `set_secrets.sh`:

```bash
melos run deploy:worker -- --secrets
./apps/messaging_worker/scripts/deploy.sh --env production --secrets
```

Infra-only change (no image rebuild):

```bash
npm install                          # once: railway TypeScript SDK
./scripts/railway-config.sh plan     # Node 22
./scripts/railway-config.sh apply    # staging linked environment
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

See [`.gitlab-ci.yml`](../../.gitlab-ci.yml). Jobs:

- `verify:messaging_worker` — runs on relevant MR changes (AOT compile).
- `deploy:messaging_worker:staging` / `production` — **manual** deploy.

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

Trước khi set `MESSAGING_CLIENT_POLL_ENABLED=false` trên ERP staging/production, deploy worker tương ứng:

```bash
./apps/messaging_worker/scripts/deploy.sh --env staging --secrets
```

## Rollback

| Situation | Action |
|-----------|--------|
| Bad deploy | Redeploy previous commit: `./scripts/deploy.sh --env <env>` |
| Disable worker | `railway down --service messaging-worker --environment <env> -y` |
| Wrong secrets | `./scripts/deploy.sh --env <env> --secrets` |

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/set_secrets.sh` | Push secrets only to Railway (`--ci` for CircleCI) |
| `scripts/verify_supabase.sh` | Check platform RPC + view |
| `scripts/verify_build.sh` | Local AOT compile (+ optional Docker) |
| `scripts/deploy.sh` | Code deploy (`railway up`) |
| [`scripts/railway-config.sh`](../../scripts/railway-config.sh) | `railway config plan` / `apply` (Node 22) |
