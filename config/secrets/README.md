# Vet45 secrets layout

All runtime configuration is edited in `config/secrets/` (gitignored `*.env`), then applied with `melos run env:sync`.

Key **dependencies per target** are declared in [`config/environments.json`](../environments.json) (`targets.*.keys`). Each target only receives the keys it declares — missing worker secrets do not block ERP, and vice versa.

| File | Purpose |
| ---- | ------- |
| `development.env` | Remote dev — shared canonical secrets for erp + worker |
| `local.env` | Optional overrides when using `supabase start` |
| `staging.env` | Staging Supabase + worker tuning |
| `production.env` | Production Supabase + worker tuning |
| `deploy.env` | Shared iOS TestFlight (`APP_STORE_CONNECT_*`) — deploy target only |

Generated outputs (do not edit):

- `apps/erp/.env*` — Flutter `--dart-define-from-file` (target `erp`)
- `apps/messaging_worker/.env*` — worker process env (target `worker`)

## Keys by target

### `erp` → `apps/erp/.env*`

| Canonical key | Output key | Required | Default |
| ------------- | ---------- | -------- | ------- |
| (manifest `appEnv`) | `APP_ENV` | yes | — |
| `SUPABASE_URL` | `SUPABASE_CONNECTION_URL` | yes | — |
| `SUPABASE_ANON_KEY` | `SUPABASE_ANON_KEY` | yes | — |
| `LOG_LEVEL` | `LOG_LEVEL` | no | `INFO` |
| `MESSAGING_CLIENT_POLL_ENABLED` | same | no | `false` |

### `worker` → `apps/messaging_worker/.env*`

| Key | Required | Default | Description |
| --- | -------- | ------- | ----------- |
| `SUPABASE_URL` | yes | — | Service-role Supabase URL |
| `SUPABASE_SERVICE_ROLE_KEY` | yes | — | Worker only (never ERP) |
| `WORKER_TICK_SECRET` | yes | auto-generated on worker sync | `POST /tick` auth |
| `WORKER_LOG_LEVEL` | no | `WARNING` | `FINE`/`INFO` for debug |
| `WORKER_TENANT_BATCH_SIZE` | no | `20` | Tenants per discovery round |
| `WORKER_MODULE_BATCH_SIZE` | no | `10` | Messages per module batch |
| `WORKER_MAX_ROUNDS_PER_TICK` | no | `5` | Inner loop cap per tick |
| `WORKER_TICK_ACTIVE_SECONDS` | no | `3` | Poll interval when backlog |
| `WORKER_TICK_IDLE_SECONDS` | no | `15` | Poll interval when idle |
| `WORKER_TICK_MAX_IDLE_SECONDS` | no | `30` | Max backoff when idle |
| `PORT` | no | `8080` | HTTP port (`--serve`); Railway sets `PORT` |

Tick summary lines (`tick {...}`) always print; `WORKER_LOG_LEVEL=WARNING` suppresses verbose RPC/command `INFO` logs.

### `deploy` → `config/secrets/deploy.env` (not synced to apps)

| Key | Required |
| --- | -------- |
| `APP_STORE_CONNECT_ISSUER_ID` | yes |
| `APP_STORE_CONNECT_KEY_IDENTIFIER` | yes |

## Commands

```bash
melos run env:sync                      # all writable targets; exit 1 if any fail
melos run env:sync -- --target erp      # erp only
melos run env:sync -- --target worker   # worker only (auto-fills WORKER_TICK_SECRET)
melos run env:doctor -- --target erp
melos run debug                         # syncs erp only, then flutter run
melos run worker:serve                  # syncs worker only
```
