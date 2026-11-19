# Mosaic Retail Environment Manager

Melos-centric workflow to keep ERP and Supabase targets aligned during development.

## Concepts

| Artifact | Purpose |
| -------- | ------- |
| [`c45.workspace.json`](../../c45.workspace.json) | **Committed** — environments, scan policy, doctor |
| `apps/*/c45.target.json` | **Committed** — per-app keys + per-env bindings (auto-discovered) |
| [`deploy/c45.target.json`](../../deploy/c45.target.json) | **Committed** — secrets-only deploy target |
| [`.c45/templates/`](../../.c45/templates/) | **Committed** — scaffold source for `c45 init <profileId>` |
| `.c45/profiles/<profileId>/` | Local profile dir (under `.c45/`, gitignored) |
| `.c45/profiles/<profileId>/<env>.env` | Profile secrets per environment |
| `.c45/profiles/<profileId>/auth.env.example` | Scaffold only — `init` does not create `auth.env` |
| `.c45/profiles/<profileId>/auth.env` | Optional — create when you need a per-profile Supabase CLI token |
| `deploy/deploy.env` | Shared iOS TestFlight credentials (gitignored) |
| `.c45/state.json` | Gitignored `{ profile, environment }` — **required** active profile |
| `.c45/active` | Legacy environment id pointer (still updated) |
| `.c45/bin/c45[.exe]` | Local AOT binary from `melos run env:build` (fast CLI) |
| Generated `apps/*/.env*` | Output consumed by Flutter (`--dart-define-from-file`) |

### Discovery

`c45` loads `c45.workspace.json`, then globs `scan.include` for `c45.target.json` files. Profiles are **not** listed in the workspace file — they are discovered as immediate children of `.c45/profiles/`. Adding a new app means committing `apps/<name>/c45.target.json` (hoặc `packages/**` / `modules/**` cho example catalog).

## Configuration profiles

Use profiles when you switch between Supabase accounts or client secret bundles. Each profile is a local `.c45/profiles/<profileId>/` directory (directory name = profile id).

| Artifact | Scope |
| -------- | ----- |
| `.c45/templates/` | Committed scaffold |
| `.c45/profiles/<profileId>/` | Local profiles (`c45 init <id>`) |
| `deploy/deploy.env` | Shared across all profiles |

```bash
c45 init acme                  # scaffold + set active profile
# or: melos run env:init -- acme
melos run profile:list
# Preferred: switch profile + sync in one step
c45 switch acme
# Lightweight (no sync): melos run profile:use -- acme  then c45 sync
# Optional: create auth.env and set SUPABASE_ACCESS_TOKEN for multi-account CLI
# cp .c45/profiles/acme/auth.env.example .c45/profiles/acme/auth.env
melos run supabase -- db push
```

See [environments.md](environments.md).

## Targets and key dependencies

Each **target** (registered directory/app) declares which secrets it needs. Sync and doctor only require keys for the targets in scope.

| Target | Manifest | Writes | Required secrets (canonical) |
| ------ | -------- | ------ | ---------------------------- |
| `erp` | `apps/erp/c45.target.json` | `apps/erp/.env*` | `SUPABASE_URL` → `SUPABASE_CONNECTION_URL`, `SUPABASE_ANON_KEY` |
| `deploy` | `deploy/c45.target.json` | none (secrets-only) | `APP_STORE_CONNECT_*` in `deploy/deploy.env` |
| `design_system` | `packages/c45_design_system/example/c45.target.json` | none (`writeEnvFile: false`) | — |

Key specs live in each `c45.target.json` (`required`, `default`, `from` rename, `fromManifest`, `autoGenerate`). Per-env bindings in the same file set `envFile`, `flavor`, `appEnv`, etc.

### Sync behaviour

| Command | Scope | Exit |
| ------- | ----- | ---- |
| `env:sync` | All writable targets in the active env | Partial write; **exit 1** if any target fails |
| `env:sync -- --target erp` | Only `erp` | Exit 1 only if erp fails |
| `run erp …` | Syncs that target only | Missing unrelated secrets do **not** block |

> `admin` và `worker` đã bỏ khỏi workspace (8-D). `SUPABASE_SERVICE_ROLE_KEY` không còn khai báo trong target nào, nên `c45 init` không scaffold key này; chỉ `c45 admin …` dùng nó (xem [Platform admin bootstrap](#platform-admin-bootstrap)).

### Doctor behaviour

```bash
melos run env:doctor                    # all targets (incl. deploy)
melos run env:doctor -- --target erp    # erp only
melos run env:doctor -- --target deploy --offline
```

Host alignment (`doctor.alignHosts` trong `c45.workspace.json`) chạy khi mọi target liệt kê đều qua; hiện chỉ còn `erp`.

## Environments

| ID | ERP flavor | Supabase source |
| -- | ---------- | --------------- |
| `development` (default) | development | secrets + `supabase link` when hosted URL configured |
| `local` | development | `supabase status` only — **no** `supabase link` |
| `staging` | staging | `.c45/profiles/<profileId>/staging.env` |
| `production` | production | `.c45/profiles/<profileId>/production.env` |

## First-time setup

Workspace, target manifests, and `.c45/templates/` are **committed**. Profile dirs under `.c45/profiles/` are local (covered by `.c45/` gitignore).

```bash
melos bootstrap
melos run env:init -- mylocal    # or: c45 init mylocal
melos run env:build              # AOT binary → .c45/bin (skip Melos for daily CLI)
source scripts/env/activate.sh   # Windows: . .\scripts\env\activate.ps1  or activate.bat
# Fill Supabase URL + keys in .c45/profiles/mylocal/*.env
# Optional iOS deploy: fill deploy/deploy.env (scaffolded by init)
# Local stack only: supabase start && melos run env:local

c45 sync                   # preferred (AOT); or: melos run env:sync
c45 list                   # shows discovered profiles + targets
c45 doctor --target erp
c45 supabase -- db push
```

`c45 init <profileId>` copies `.c45/templates/*.env.example` into `.c45/profiles/<profileId>/` (and creates matching `*.env`), then sets the active profile. Never overwrites filled secrets unless `--force` and the file is empty of values.

## Supabase CLI link (env → project ref)

When an environment has a **hosted** Supabase project (`*.supabase.co`), `env:use` and `env:sync` run:

```bash
supabase link --project-ref <ref> --yes
```

Project ref resolution order:

1. `supabaseProjectRef` in `c45.workspace.json` (per environment)
2. `SUPABASE_PROJECT_REF` in `.c45/profiles/<profileId>/<env>.env`
3. Parsed from `SUPABASE_URL` (e.g. `https://abc123.supabase.co` → `abc123`)

`local` sets `"syncSupabaseLink": false` — keeps `supabase start` workflow without re-linking remote.

Optional: `SUPABASE_DB_PASSWORD` in secrets for first-time `supabase link`.

```bash
melos run env:use:staging    # switches .c45/active + supabase link
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

Exports: `C45_ROOT`, `C45_PROFILE`, `C45_ENV_ID`, `C45_ACTIVE_LABEL` (e.g. `(default/staging)`).

Also prepends `.c45/bin` to `PATH` so `c45` / `c45.exe` runs the AOT binary (after `melos run env:build`).

bash/zsh/PowerShell re-read `.c45/state.json` on each prompt, so after `melos run env:use:staging` / `c45 switch staging` the label updates automatically. CMD keeps a static prompt — run `activate.bat` again to refresh.

## TUI (lazygit-style)

`c45` with no arguments (or `c45 tui`) opens an interactive nocterm TUI:

```text
Profiles | Environments
Status / Doctor
Log
```

Environments panel only lists ids that have a real secrets file for the
**selected profile** (`.c45/profiles/<profileId>/<env>.env` or `.c45/profiles/<profileId>/<env>.env`).
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

Use `c45 switch` when changing profile or environment — it updates state, runs `supabase link`, and syncs app `.env` files in one step. This avoids mismatches when running `c45 supabase reset --linked` or other Supabase CLI commands.

```bash
c45 switch                    # print active profile + environment
c45 switch acme               # change profile, keep current environment
c45 switch acme staging       # change both profile and environment
c45 switch --env staging      # change environment only
c45 switch acme staging --target erp
scripts/env/switch.sh acme staging   # thin wrapper → c45 switch
```

| Command | Link | Sync | Notes |
| ------- | ---- | ---- | ----- |
| `c45 switch …` | yes | yes | **Recommended** after profile/env change |
| `c45 profile use <id>` | no | no | Lightweight; run `c45 sync` before Supabase |
| `c45 use <env>` | yes | no | Sets env only |
| `c45 use-and-sync <env>` | yes | yes | Same as `switch` with required env arg |
| `c45 supabase …` | yes (preflight) | no | Auto `ensureLinked` before delegate |

## Fast CLI (AOT)

Daily env commands should **bypass Melos** when possible:

```bash
melos run env:build          # once per clone / after c45 CLI source changes
source scripts/env/activate.sh
c45                        # interactive TUI
c45 list
c45 switch acme staging
c45 sync --target erp
c45 supabase -- db push
```

| Entry | When |
| ----- | ---- |
| `c45 …` (PATH) | Preferred — native AOT, no Melos / no `dart run` |
| `scripts/env/c45.sh|.bat|.ps1 …` | Same shim without activate |
| `melos run env:…` | Optional discoverability; uses `run.dart` which spawns AOT if built |

## Daily commands

```bash
# Preferred after activate + env:build
c45 list
c45 switch staging
c45 switch acme staging
c45 sync
c45 sync --target erp
c45 doctor --target erp
c45 supabase -- db push

# Melos still works (slower launcher)
melos run env:list
melos run env:use:staging
melos run env:sync
melos run debug                 # ERP — syncs erp only, then flutter run
melos run debug:staging
melos run supabase -- db push

# Deploy (active env must be staging|production)
melos run build:ios
melos run deploy:ios
```

## Canonical secrets keys

Edit **`.c45/profiles/<profileId>/<env>.env`** only — see [environments.md](environments.md).

```dotenv
SUPABASE_URL=
SUPABASE_PROJECT_REF=       # optional; derived from URL if omitted
SUPABASE_DB_PASSWORD=       # optional; for supabase link
SUPABASE_ANON_KEY=          # erp
SUPABASE_SERVICE_ROLE_KEY=  # chỉ cho `c45 admin …` (local lấy từ `supabase status`; remote điền tay)
LOG_LEVEL=INFO              # erp
MESSAGING_CLIENT_POLL_ENABLED=false

# Deploy-only (shared) — deploy/deploy.env
APP_STORE_CONNECT_ISSUER_ID=
APP_STORE_CONNECT_KEY_IDENTIFIER=
```

`env:sync` maps only the keys declared for each target:

- ERP: `SUPABASE_CONNECTION_URL`, `SUPABASE_ANON_KEY`, `APP_ENV`, …
- Deploy: not written to apps; `deploy-ios.sh` reads `DEPLOY_SECRETS_FILE`

## Tooling layout

```
c45.workspace.json       # Committed — environments, scan, doctor
apps/*/c45.target.json   # Committed — per-target keys + bindings
deploy/c45.target.json
tools/c45_env/           # Dart package (entry: bin/c45_env.dart → AOT name `c45`)
scripts/env/c45.sh|.bat|.ps1   # Prefer AOT `.c45/bin/c45`, else dart run
.c45/bin/c45[.exe]     # AOT binary (`melos run env:build`)
```

Preferred CLI (git-style subcommands):

```bash
c45 list
c45 switch acme staging   # profile + env + link + sync
c45 sync --target erp
c45 run erp debug
c45 supabase -- db push
```

Shell completion (zsh/bash):

```bash
eval "$(c45 completion zsh)"   # add to ~/.zshrc
eval "$(c45 completion bash)"  # add to ~/.bashrc
```

Fallback without AOT / PATH:

```bash
dart run tools/c45_env/bin/c45_env.dart list
dart run tools/c45_env/bin/c45_env.dart sync --target erp
```

Melos scripts call `dart run …/run.dart` (spawns AOT if built).

### Windows notes

| Requirement | Notes |
| ----------- | ----- |
| Dart SDK + Flutter in `PATH` | Required for `melos run debug`; c45 resolves `flutter.bat` via `where` / `FLUTTER_ROOT` on Windows |
| Supabase CLI | `supabase` on PATH for `env:local` |
| Git Bash | Optional; needed for legacy `.sh` scripts via `bash` |
| Prompt activate | `scripts\env\activate.bat` (CMD) or `. .\scripts\env\activate.ps1` (PowerShell) |
| iOS build/deploy | macOS only — `debug:ios`, `build:ios`, `deploy:ios` exit with clear message on Windows |

On Windows CMD: `scripts\env\c45.bat sync --target erp`

VS Code `preLaunchTask` uses `dart run tools/c45_env/... use-and-sync` (see `.vscode/tasks.json`).

Low-level CLI (from repo root, without activate):

```bash
c45 list
c45 sync --env development
c45 sync --target erp
c45 doctor --target erp --offline
# or: dart run tools/c45_env/bin/c45_env.dart …
```

## Troubleshooting

| Symptom | Fix |
| ------- | --- |
| `Missing SUPABASE_SERVICE_ROLE_KEY` | Local: `supabase start`; remote: điền key vào `.c45/profiles/<profileId>/<env>.env` |
| Doctor fails on deploy | Add `deploy/deploy.env`, or `env:doctor -- --target erp` |
| Switch remote dev/staging project | `melos run env:use:<env>` or `melos run env:link` |
| `supabase cli link` mismatch | `melos run env:sync` then `melos run env:doctor` |
| Edited generated `.env` lost | Edit `.c45/profiles/<profileId>/<env>.env` then re-sync |
| `supabase status failed` | Start CLI stack or add `.c45/profiles/<profileId>/local.env` override |

See also: [environments.md](environments.md)
