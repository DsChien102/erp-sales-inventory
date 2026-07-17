# Vet45 Environment Manager

Melos-centric workflow to keep ERP, messaging worker, and Supabase targets aligned during development.

## Concepts

| Artifact | Purpose |
| -------- | ------- |
| [`vet45.workspace.json`](../../vet45.workspace.json) | **Committed** — environments, profiles, scan policy |
| `apps/*/vet45.target.json` | **Committed** — per-app keys + per-env bindings (auto-discovered) |
| [`config/deploy/vet45.target.json`](../../config/deploy/vet45.target.json) | **Committed** — secrets-only deploy target |
| [`config/default/*.env.example`](../../config/default/) | **Committed** — default profile examples |
| `config/<profileId>/<env>.env` | Profile secrets per environment (**gitignored**) |
| `config/<profileId>/auth.env` | Per-profile Supabase CLI token (optional, gitignored) |
| `config/deploy/deploy.env` | Shared iOS TestFlight credentials (gitignored) |
| `.vet45/state.json` | Gitignored `{ profile, environment }` |
| `.vet45/active` | Legacy environment id pointer (still updated) |
| `.vet45/bin/vet45[.exe]` | Local AOT binary from `melos run env:build` (fast CLI) |
| Generated `apps/*/.env*` | Output consumed by Flutter (`--dart-define-from-file`) and worker |

### Discovery

`vet45` loads `vet45.workspace.json`, then globs `scan.include` for `vet45.target.json` files. Each target owns its key specs and per-environment bindings (`envFile` paths are relative to the target file’s directory). Adding a new app means committing `apps/<name>/vet45.target.json` — no central registry edit.

## Configuration profiles

Use profiles when you switch between Supabase accounts or client secret bundles. Each profile is `config/<profileId>/` (directory name = profile id; no nested `secrets/` folder).

| Artifact | Scope |
| -------- | ----- |
| `config/default/` | Default profile |
| `config/<profileId>/` | Additional profiles (`vet45 profile init …`) |
| `config/deploy/deploy.env` | Shared across all profiles |

```bash
melos run profile:list
melos run profile:init -- acme --description "Client Acme"
# Preferred: switch profile + sync in one step
vet45 switch acme
# Or: melos run env:switch -- acme staging
# Lightweight (no sync): melos run profile:use -- acme  then vet45 sync
# Set SUPABASE_ACCESS_TOKEN in config/acme/auth.env
melos run supabase -- db push
```

See [config/README.md](../../config/README.md).

## Targets and key dependencies

Each **target** (registered directory/app) declares which secrets it needs. Sync and doctor only require keys for the targets in scope.

| Target | Manifest | Writes | Required secrets (canonical) |
| ------ | -------- | ------ | ---------------------------- |
| `erp` | `apps/erp/vet45.target.json` | `apps/erp/.env*` | `SUPABASE_URL` → `SUPABASE_CONNECTION_URL`, `SUPABASE_ANON_KEY` |
| `admin` | `apps/admin/vet45.target.json` | `apps/admin/.env*` | same as erp (no messaging poll flag) |
| `worker` | `apps/messaging_worker/vet45.target.json` | `apps/messaging_worker/.env*` | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `WORKER_TICK_SECRET` (+ optional tuning) |
| `deploy` | `config/deploy/vet45.target.json` | none (secrets-only) | `APP_STORE_CONNECT_*` in `config/deploy/deploy.env` |

Key specs live in each `vet45.target.json` (`required`, `default`, `from` rename, `fromManifest`, `autoGenerate`). Per-env bindings in the same file set `envFile`, `flavor`, `appEnv`, etc.

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
| `staging` | staging | `config/default/staging.env` |
| `production` | production | `config/default/production.env` |

## First-time setup

Workspace and target manifests are **committed**. Only secrets under `config/<profileId>/*.env` (and profile secrets) are local/gitignored.

```bash
melos bootstrap
melos run env:init               # copy config/<profile>/*.env.example → *.env when missing
melos run env:build              # AOT binary → .vet45/bin (skip Melos for daily CLI)
source scripts/env/activate.sh   # Windows: . .\scripts\env\activate.ps1  or activate.bat
cp config/default/development.env.example config/default/development.env
cp config/default/staging.env.example config/default/staging.env
cp config/default/production.env.example config/default/production.env
# Optional: cp config/default/auth.env.example config/default/auth.env
# Optional iOS deploy: cp config/deploy/deploy.env.example config/deploy/deploy.env
# Fill Supabase URL + keys in config/default/*.env
# Local stack only: supabase start && melos run env:local

vet45 sync                   # preferred (AOT); or: melos run env:sync
vet45 list                   # shows discovered targets + manifest paths
vet45 doctor --target erp
vet45 supabase -- db push
```

Committed examples live under `config/default/` and `config/deploy/`. `env:init` copies missing `*.env` from those examples (never overwrites filled secrets).

## Supabase CLI link (env → project ref)

When an environment has a **hosted** Supabase project (`*.supabase.co`), `env:use` and `env:sync` run:

```bash
supabase link --project-ref <ref> --yes
```

Project ref resolution order:

1. `supabaseProjectRef` in `vet45.workspace.json` (per environment)
2. `SUPABASE_PROJECT_REF` in `config/<profileId>/<env>.env`
3. Parsed from `SUPABASE_URL` (e.g. `https://abc123.supabase.co` → `abc123`)

`local` sets `"syncSupabaseLink": false` — keeps `supabase start` workflow without re-linking remote.

Optional: `SUPABASE_DB_PASSWORD` in secrets for first-time `supabase link`.

```bash
melos run env:use:staging    # switches .vet45/active + supabase link
melos run env:link           # link only, no .env regeneration
melos run env:doctor         # checks linked ref matches env
```

## Shell activate (venv-style prompt)

Shows active **profile/environment** on the shell prompt and exports session vars.

| Shell | Activate | Deactivate |
| ----- | -------- | ---------- |
| bash / zsh | `source scripts/env/activate.sh` | `deactivate` |
| PowerShell | `. .\scripts\env\activate.ps1` | `deactivate` |
| CMD | `scripts\env\activate.bat` | `deactivate` |

Exports: `VET45_ROOT`, `VET45_PROFILE`, `VET45_ENV_ID`, `VET45_ACTIVE_LABEL` (e.g. `(default/staging)`).

Also prepends `.vet45/bin` to `PATH` so `vet45` / `vet45.exe` runs the AOT binary (after `melos run env:build`).

bash/zsh/PowerShell re-read `.vet45/state.json` on each prompt, so after `melos run env:use:staging` / `vet45 switch staging` the label updates automatically. CMD keeps a static prompt — run `activate.bat` again to refresh.

## TUI (lazygit-style)

`vet45` with no arguments (or `vet45 tui`) opens an interactive nocterm TUI:

```text
Profiles | Environments
Status / Doctor
Log
```

Environments panel only lists ids that have a real secrets file for the
**selected profile** (`config/<profileId>/<env>.env` or `config/<profileId>/<env>.env`).
`*.env.example` alone does not appear.

| Key | Action |
| --- | --- |
| `Enter` | Switch to selected profile + environment (link + sync) |
| `s` | Sync active workspace |
| `d` | Run doctor |
| `r` | Reload manifest/state from disk |
| `Tab` | Cycle focus panels |
| `↑↓` / `jk` | Move cursor in focused list |
| `q` | Quit |

Requires an interactive TTY. Non-TTY (CI/pipes) falls back to CLI subcommands.

After TUI source changes, rebuild AOT: `melos run env:build`.

## Switch profile / environment (recommended)

Use `vet45 switch` when changing profile or environment — it updates state, runs `supabase link`, and syncs app `.env` files in one step. This avoids mismatches when running `vet45 supabase reset --linked` or other Supabase CLI commands.

```bash
vet45 switch                    # print active profile + environment
vet45 switch acme               # change profile, keep current environment
vet45 switch acme staging       # change both profile and environment
vet45 switch --env staging      # change environment only
vet45 switch acme staging --target erp
scripts/env/switch.sh acme staging   # thin wrapper → vet45 switch
```

| Command | Link | Sync | Notes |
| ------- | ---- | ---- | ----- |
| `vet45 switch …` | yes | yes | **Recommended** after profile/env change |
| `vet45 profile use <id>` | no | no | Lightweight; run `vet45 sync` before Supabase |
| `vet45 use <env>` | yes | no | Sets env only |
| `vet45 use-and-sync <env>` | yes | yes | Same as `switch` with required env arg |
| `vet45 supabase …` | yes (preflight) | no | Auto `ensureLinked` before delegate |

## Fast CLI (AOT)

Daily env commands should **bypass Melos** when possible:

```bash
melos run env:build          # once per clone / after vet45 CLI source changes
source scripts/env/activate.sh
vet45                        # interactive TUI
vet45 list
vet45 switch acme staging
vet45 sync --target erp
vet45 supabase -- db push
```

| Entry | When |
| ----- | ---- |
| `vet45 …` (PATH) | Preferred — native AOT, no Melos / no `dart run` |
| `scripts/env/vet45.sh|.bat|.ps1 …` | Same shim without activate |
| `melos run env:…` | Optional discoverability; uses `run.dart` which spawns AOT if built |

## Daily commands

```bash
# Preferred after activate + env:build
vet45 list
vet45 switch staging
vet45 switch acme staging
vet45 sync
vet45 sync --target erp
vet45 doctor --target erp
vet45 supabase -- db push

# Melos still works (slower launcher)
melos run env:list
melos run env:use:staging
melos run env:sync
melos run debug                 # ERP — syncs erp only, then flutter run
melos run debug:staging
melos run worker:serve
melos run supabase -- db push

# Deploy (active env must be staging|production)
melos run build:ios
melos run deploy:ios
melos run deploy:worker
melos run deploy:worker -- --secrets
```

## Canonical secrets keys

Edit **`config/<profileId>/<env>.env`** only — see [config/default/README.md](../../config/default/README.md) for which target consumes each key.

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

# Deploy-only (shared) — config/deploy/deploy.env
APP_STORE_CONNECT_ISSUER_ID=
APP_STORE_CONNECT_KEY_IDENTIFIER=
```

`env:sync` maps only the keys declared for each target:

- ERP: `SUPABASE_CONNECTION_URL`, `SUPABASE_ANON_KEY`, `APP_ENV`, …
- Worker: `WORKER_*` + `SUPABASE_URL` / service role
- Deploy: not written to apps; `deploy-ios.sh` reads `DEPLOY_SECRETS_FILE`

## Tooling layout

```
vet45.workspace.json       # Committed — environments, profiles, scan
apps/*/vet45.target.json   # Committed — per-target keys + bindings
config/deploy/vet45.target.json
tools/vet45_env/           # Dart package (entry: bin/vet45_env.dart → AOT name `vet45`)
scripts/env/vet45.sh|.bat|.ps1   # Prefer AOT `.vet45/bin/vet45`, else dart run
.vet45/bin/vet45[.exe]     # AOT binary (`melos run env:build`)
```

Preferred CLI (git-style subcommands):

```bash
vet45 list
vet45 switch acme staging   # profile + env + link + sync
vet45 sync --target erp
vet45 run erp debug
vet45 supabase -- db push
```

Shell completion (zsh/bash):

```bash
eval "$(vet45 completion zsh)"   # add to ~/.zshrc
eval "$(vet45 completion bash)"  # add to ~/.bashrc
```

Fallback without AOT / PATH:

```bash
dart run tools/vet45_env/bin/vet45_env.dart list
dart run tools/vet45_env/bin/vet45_env.dart sync --target erp
```

Melos scripts call `dart run …/run.dart` (spawns AOT if built).

### Windows notes

| Requirement | Notes |
| ----------- | ----- |
| Dart SDK + Flutter in `PATH` | Required for `melos run debug`; vet45 resolves `flutter.bat` via `where` / `FLUTTER_ROOT` on Windows |
| Supabase CLI | `supabase` on PATH for `env:local` |
| Git Bash | Optional; needed for `deploy:worker` / legacy `.sh` deploy scripts via `bash` |
| Prompt activate | `scripts\env\activate.bat` (CMD) or `. .\scripts\env\activate.ps1` (PowerShell) |
| iOS build/deploy | macOS only — `debug:ios`, `build:ios`, `deploy:ios` exit with clear message on Windows |
| Docker Desktop | For `melos run worker:docker`; uses `host.docker.internal` |

On Windows CMD: `scripts\env\vet45.bat sync --target erp`

VS Code `preLaunchTask` uses `dart run tools/vet45_env/... use-and-sync` (see `.vscode/tasks.json`).

Low-level CLI (from repo root, without activate):

```bash
vet45 list
vet45 sync --env development
vet45 sync --target erp
vet45 doctor --target erp --offline
# or: dart run tools/vet45_env/bin/vet45_env.dart …
```

## Docker worker

```bash
melos run env:development   # or env:local for Supabase CLI only
melos run worker:docker
```

Compose reads `WORKER_ENV_FILE` (set by `vet45.sh run worker docker`) and overrides `SUPABASE_URL` to `host.docker.internal:54321` for local Supabase.

## Railway deploy

Deploy scripts read worker config from **`config/<profileId>/<env>.env`** (via `SECRETS_FILE` / `env:sync --target worker`):

```bash
./apps/messaging_worker/scripts/deploy.sh --env staging --secrets
```

`WORKER_LOG_LEVEL=WARNING` in secrets keeps Railway logs quiet (RPC/command `INFO` suppressed). Tick summary lines still print.

## Troubleshooting

| Symptom | Fix |
| ------- | --- |
| Full `env:sync` exit 1 but erp works | Fill worker keys, or use `env:sync -- --target erp` / `melos run debug` |
| `Missing SUPABASE_SERVICE_ROLE_KEY` on worker | `supabase start` then `melos run env:sync -- --target worker` |
| Doctor fails on deploy | Add `config/deploy/deploy.env`, or `env:doctor -- --target erp` |
| Switch remote dev/staging project | `melos run env:use:<env>` or `melos run env:link` |
| `supabase cli link` mismatch | `melos run env:sync` then `melos run env:doctor` |
| Edited generated `.env` lost | Edit `config/<profileId>/<env>.env` then re-sync |
| `supabase status failed` | Start CLI stack or add `config/default/local.env` override |

See also: [environments.md](environments.md)
