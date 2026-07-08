# Vet45 Environment Manager

Melos-centric workflow to keep ERP, messaging worker, and Supabase targets aligned during development.

## Concepts

| Artifact | Purpose |
| -------- | ------- |
| [`config/environments.json`](../../config/environments.json) | Targets registry (key deps) + per-env bindings (paths, flavors) |
| `config/secrets/<env>.env` | Gitignored secrets per environment |
| `config/secrets/deploy.env` | Shared iOS TestFlight credentials (deploy target) |
| `.vet45/active` | Gitignored pointer to active environment id |
| Generated `apps/*/.env*` | Output consumed by Flutter (`--dart-define-from-file`) and worker |

## Targets and key dependencies

Each **target** (registered directory/app) declares which secrets it needs. Sync and doctor only require keys for the targets in scope.

| Target | Writes | Required secrets (canonical) |
| ------ | ------ | ---------------------------- |
| `erp` | `apps/erp/.env*` | `SUPABASE_URL` → `SUPABASE_CONNECTION_URL`, `SUPABASE_ANON_KEY` |
| `worker` | `apps/messaging_worker/.env*` | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `WORKER_TICK_SECRET` (+ optional tuning) |
| `deploy` | none (secrets-only) | `APP_STORE_CONNECT_*` in `config/secrets/deploy.env` |

Key specs live under `targets` in `environments.json` (`required`, `default`, `from` rename, `fromManifest`, `autoGenerate`). Per-env `targets.<id>` only binds paths and manifest fields (`envFile`, `flavor`, `appEnv`).

### Sync behaviour

| Command | Scope | Exit |
| ------- | ----- | ---- |
| `env:sync` | All writable targets in the active env | Partial write; **exit 1** if any target fails |
| `env:sync -- --target erp` | Only `erp` | Exit 1 only if erp fails |
| `run erp …` / `run worker …` | Syncs that target only | Missing unrelated secrets do **not** block |

Example: secrets without `SUPABASE_SERVICE_ROLE_KEY` still allow `melos run debug` (erp). Full `env:sync` writes erp, skips worker, and exits 1 so CI notices.

### Doctor behaviour

```bash
melos run env:doctor                    # all targets (incl. deploy)
melos run env:doctor -- --target erp    # erp only
melos run env:doctor -- --target deploy --offline
```

Host alignment (erp vs worker Supabase URL) runs only when both targets pass.

## Environments

| ID | ERP flavor | Supabase source |
| -- | ---------- | --------------- |
| `development` (default) | development | secrets + `supabase link` when hosted URL configured |
| `local` | development | `supabase status` only — **no** `supabase link` |
| `staging` | staging | `config/secrets/staging.env` |
| `production` | production | `config/secrets/production.env` |

## First-time setup

```bash
melos bootstrap
cp config/secrets/development.env.example config/secrets/development.env
cp config/secrets/staging.env.example config/secrets/staging.env
cp config/secrets/production.env.example config/secrets/production.env
# Optional iOS deploy: cp config/secrets/deploy.env.example config/secrets/deploy.env
# Fill Supabase URL + keys in config/secrets/*.env
# Local stack only: supabase start && melos run env:local

melos run env:sync
melos run env:doctor -- --target erp   # or full doctor once deploy.env exists
```

## Supabase CLI link (env → project ref)

When an environment has a **hosted** Supabase project (`*.supabase.co`), `env:use` and `env:sync` run:

```bash
supabase link --project-ref <ref> --yes
```

Project ref resolution order:

1. `supabaseProjectRef` in `config/environments.json`
2. `SUPABASE_PROJECT_REF` in `config/secrets/<env>.env`
3. Parsed from `SUPABASE_URL` (e.g. `https://abc123.supabase.co` → `abc123`)

`local` sets `"syncSupabaseLink": false` — keeps `supabase start` workflow without re-linking remote.

Optional: `SUPABASE_DB_PASSWORD` in secrets for first-time `supabase link`.

```bash
melos run env:use:staging    # switches .vet45/active + supabase link
melos run env:link           # link only, no .env regeneration
melos run env:doctor         # checks linked ref matches env
```

## Daily commands

```bash
melos run env:list              # show targets + environments + active (*)
melos run env:use:staging       # switch active + supabase link
melos run env:sync              # link + regenerate all writable targets
melos run env:sync -- --target erp
melos run env:doctor            # validate all targets
melos run env:doctor -- --target erp

melos run debug                 # ERP — syncs erp only, then flutter run
melos run debug:staging         # shortcut: use staging + sync + run
melos run worker:serve          # worker — syncs worker only

# Deploy (active env must be staging|production)
melos run build:ios             # build IPA only
melos run deploy:ios            # validates deploy secrets + build + TestFlight
melos run deploy:worker         # Railway worker redeploy
melos run deploy:worker -- --secrets   # push secrets + deploy
```

## Canonical secrets keys

Edit **`config/secrets/<env>.env`** only — see [config/secrets/README.md](../../config/secrets/README.md) for which target consumes each key.

```dotenv
SUPABASE_URL=
SUPABASE_PROJECT_REF=       # optional; derived from URL if omitted
SUPABASE_DB_PASSWORD=       # optional; for supabase link
SUPABASE_ANON_KEY=          # erp
SUPABASE_SERVICE_ROLE_KEY=  # worker
WORKER_TICK_SECRET=         # worker (auto-generated on worker sync if empty)
LOG_LEVEL=INFO              # erp
MESSAGING_CLIENT_POLL_ENABLED=false

# Messaging worker (synced to apps/messaging_worker/.env*)
WORKER_LOG_LEVEL=WARNING
WORKER_TENANT_BATCH_SIZE=20
WORKER_MODULE_BATCH_SIZE=10
WORKER_MAX_ROUNDS_PER_TICK=5
WORKER_TICK_ACTIVE_SECONDS=3
WORKER_TICK_IDLE_SECONDS=15
WORKER_TICK_MAX_IDLE_SECONDS=30
PORT=8080

# Deploy-only (shared) — config/secrets/deploy.env
APP_STORE_CONNECT_ISSUER_ID=
APP_STORE_CONNECT_KEY_IDENTIFIER=
```

`env:sync` maps only the keys declared for each target:

- ERP: `SUPABASE_CONNECTION_URL`, `SUPABASE_ANON_KEY`, `APP_ENV`, …
- Worker: `WORKER_*` + `SUPABASE_URL` / service role
- Deploy: not written to apps; `deploy-ios.sh` reads `DEPLOY_SECRETS_FILE`

## Tooling layout

```
config/environments.json
tools/vet45_env/           # Dart CLI (list, use, sync, doctor, run, resolve-shell)
scripts/env/vet45_env.sh   # Unix shim → dart run (optional)
scripts/env/vet45_env.bat  # Windows CMD shim → dart run
```

Cross-platform entry (Windows, macOS, Linux):

```bash
dart run tools/vet45_env/bin/vet45_env.dart list
dart run tools/vet45_env/bin/vet45_env.dart sync --target erp
dart run tools/vet45_env/bin/vet45_env.dart run erp debug
dart run tools/vet45_env/bin/vet45_env.dart use-sync-run staging erp debug
```

Melos scripts call `dart run` directly (no bash `&&` chains).

### Windows notes

| Requirement | Notes |
| ----------- | ----- |
| Dart SDK + Flutter in `PATH` | Required for `melos run debug`; vet45_env resolves `flutter.bat` via `where` / `FLUTTER_ROOT` on Windows |
| Supabase CLI | `supabase` on PATH for `env:local` |
| Git Bash | Optional; needed for `deploy:worker` / legacy `.sh` deploy scripts via `bash` |
| iOS build/deploy | macOS only — `debug:ios`, `build:ios`, `deploy:ios` exit with clear message on Windows |
| Docker Desktop | For `melos run worker:docker`; uses `host.docker.internal` |

On Windows CMD: `scripts\env\vet45_env.bat sync --target erp`

VS Code `preLaunchTask` uses `dart run tools/vet45_env/... use-and-sync` (see `.vscode/tasks.json`).

Low-level CLI (from repo root):

```bash
dart run tools/vet45_env/bin/vet45_env.dart list
dart run tools/vet45_env/bin/vet45_env.dart sync --env development
dart run tools/vet45_env/bin/vet45_env.dart sync --target erp
dart run tools/vet45_env/bin/vet45_env.dart doctor --target erp --offline
```

## Docker worker

```bash
melos run env:development   # or env:local for Supabase CLI only
melos run worker:docker
```

Compose reads `WORKER_ENV_FILE` (set by `vet45_env.sh run worker docker`) and overrides `SUPABASE_URL` to `host.docker.internal:54321` for local Supabase.

## Railway deploy

Deploy scripts read worker config from **`config/secrets/<env>.env`** (via `SECRETS_FILE` / `env:sync --target worker`):

```bash
./apps/messaging_worker/scripts/deploy.sh --env staging --secrets
```

`WORKER_LOG_LEVEL=WARNING` in secrets keeps Railway logs quiet (RPC/command `INFO` suppressed). Tick summary lines still print.

## Troubleshooting

| Symptom | Fix |
| ------- | --- |
| Full `env:sync` exit 1 but erp works | Fill worker keys, or use `env:sync -- --target erp` / `melos run debug` |
| `Missing SUPABASE_SERVICE_ROLE_KEY` on worker | `supabase start` then `melos run env:sync -- --target worker` |
| Doctor fails on deploy | Add `config/secrets/deploy.env`, or `env:doctor -- --target erp` |
| Switch remote dev/staging project | `melos run env:use:<env>` or `melos run env:link` |
| `supabase cli link` mismatch | `melos run env:sync` then `melos run env:doctor` |
| Edited generated `.env` lost | Edit `config/secrets/<env>.env` then re-sync |
| `supabase status failed` | Start CLI stack or add `config/secrets/local.env` override |

See also: [environments.md](environments.md)
