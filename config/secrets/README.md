# Vet45 secrets layout

All runtime configuration is edited in `config/secrets/` (gitignored `*.env`), then applied with `melos run env:sync`.

| File | Purpose |
| ---- | ------- |
| `development.env` | Remote dev — Supabase + worker + ERP keys for sync |
| `local.env` | Optional overrides when using `supabase start` |
| `staging.env` | Staging Supabase + worker tuning |
| `production.env` | Production Supabase + worker tuning |
| `deploy.env` | Shared iOS TestFlight (`APP_STORE_CONNECT_*`) |

Generated outputs (do not edit):

- `apps/erp/.env*` — Flutter `--dart-define-from-file`
- `apps/messaging_worker/.env*` — worker process env

## Messaging worker keys (in each `<env>.env`)

Set in `config/secrets/<env>.env`; `env:sync` writes `apps/messaging_worker/.env*`.

| Key | Default | Description |
| --- | ------- | ----------- |
| `SUPABASE_URL` | — | Service-role Supabase URL |
| `SUPABASE_SERVICE_ROLE_KEY` | — | Worker only (never ERP) |
| `WORKER_TICK_SECRET` | auto-generated if empty | `POST /tick` auth |
| `WORKER_LOG_LEVEL` | `WARNING` | `FINE`/`INFO` for debug; `WARNING` for quiet prod logs |
| `WORKER_TENANT_BATCH_SIZE` | `20` | Tenants per discovery round |
| `WORKER_MODULE_BATCH_SIZE` | `10` | Messages per module batch |
| `WORKER_MAX_ROUNDS_PER_TICK` | `5` | Inner loop cap per tick |
| `WORKER_TICK_ACTIVE_SECONDS` | `3` | Poll interval when backlog |
| `WORKER_TICK_IDLE_SECONDS` | `15` | Poll interval when idle |
| `WORKER_TICK_MAX_IDLE_SECONDS` | `30` | Max backoff when idle |
| `PORT` | `8080` | HTTP port (`--serve`); Railway sets `PORT` |

Tick summary lines (`tick {...}`) always print; `WORKER_LOG_LEVEL=WARNING` suppresses verbose RPC/command `INFO` logs.
