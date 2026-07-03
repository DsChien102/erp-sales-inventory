# Vet45 Environment Manager

Melos-centric workflow to keep ERP, messaging worker, and Supabase targets aligned during development.

## Concepts

| Artifact | Purpose |
| -------- | ------- |
| [`config/environments.json`](../../config/environments.json) | Versioned manifest — flavors, env file paths, Supabase source |
| `config/secrets/<env>.env` | Gitignored secrets per environment |
| `.vet45/active` | Gitignored pointer to active environment id |
| Generated `apps/*/.env*` | Output consumed by Flutter (`--dart-define-from-file`) and worker |

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
# Fill Supabase URL + keys in config/secrets/*.env
# Local stack only: supabase start && melos run env:local

melos run env:sync
melos run env:doctor
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
melos run env:list              # show environments + active (*)
melos run env:use:staging       # switch active + supabase link
melos run env:sync              # link + regenerate ERP + worker .env files
melos run env:doctor            # validate keys + link + Supabase reachability

melos run debug                 # ERP — active env
melos run debug:staging         # shortcut: use staging + sync + run
melos run worker:serve          # worker — active env

# Deploy (active env must be staging|production)
melos run build:ios             # build IPA only
melos run deploy:ios            # build + upload TestFlight
melos run deploy:worker         # Railway worker redeploy
melos run deploy:worker -- --secrets   # push secrets + deploy
```

## Canonical secrets keys

Use the same names in `config/secrets/*.env`:

```dotenv
SUPABASE_URL=
SUPABASE_PROJECT_REF=       # optional; derived from URL if omitted
SUPABASE_DB_PASSWORD=       # optional; for supabase link
SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=
WORKER_TICK_SECRET=
LOG_LEVEL=INFO
MESSAGING_CLIENT_POLL_ENABLED=false
```

`env:sync` maps to app-specific files:

- ERP: `SUPABASE_CONNECTION_URL`, `SUPABASE_ANON_KEY`, `APP_ENV`, …
- Worker: `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, …

## Tooling layout

```
config/environments.json
tools/vet45_env/           # Dart CLI (list, use, sync, doctor, resolve-shell)
scripts/env/vet45_env.sh   # Melos entrypoint + `run erp|worker`
```

Low-level CLI (from repo root):

```bash
dart run tools/vet45_env/bin/vet45_env.dart list
dart run tools/vet45_env/bin/vet45_env.dart sync --env development
dart run tools/vet45_env/bin/vet45_env.dart doctor --offline
```

## Docker worker

```bash
melos run env:development   # or env:local for Supabase CLI only
melos run worker:docker
```

Compose reads `WORKER_ENV_FILE` (set by `vet45_env.sh run worker docker`) and overrides `SUPABASE_URL` to `host.docker.internal:54321` for local Supabase.

## Railway deploy

Deploy scripts resolve worker env from manifest:

```bash
./apps/messaging_worker/scripts/deploy.sh --env staging --secrets
```

## Troubleshooting

| Symptom | Fix |
| ------- | --- |
| `Missing SUPABASE_SERVICE_ROLE_KEY` on local | `supabase start` then `melos run env:sync` |
| Switch remote dev/staging project | `melos run env:use:<env>` or `melos run env:link` |
| `supabase cli link` mismatch | `melos run env:sync` then `melos run env:doctor` |
| Edited generated `.env` lost | Edit `config/secrets/<env>.env` then re-sync |
| `supabase status failed` | Start CLI stack or add `config/secrets/local.env` override |

See also: [environments.md](environments.md)
