# Configuration profiles

Profiles isolate **secrets roots** and optional **Supabase account tokens** when you work with multiple hosted projects or client workspaces.

Profile registry lives in committed [`vet45.workspace.json`](../../vet45.workspace.json) (`profiles.entries`). `profile init` appends a new entry there.

| Profile | Secrets root | Use when |
| ------- | ------------ | -------- |
| `default` | `config/secrets/` | Vet45 main (Agapi) — existing layout |

Shared deploy credentials stay in `config/secrets/deploy.env` for all profiles.

## Active state

`.vet45/state.json` stores `{ "profile", "environment" }`. Legacy `.vet45/active` (environment id only) is still updated for compatibility.

## Commands

```bash
melos run profile:list
melos run profile:use -- <profile-id>
melos run profile:init -- <profile-id> [--description "Client X"]
```

When switching profiles, set `SUPABASE_ACCESS_TOKEN` manually in that profile's `auth.env` before `env:sync` / `env:use` / `melos run supabase`.

Any env command accepts `--profile <id>`:

```bash
melos run env:sync -- --profile acme --env staging
```

## New profile setup

```bash
melos run profile:init -- acme --description "Acme client"
cp config/profiles/acme/secrets/staging.env.example config/profiles/acme/secrets/staging.env
cp config/profiles/acme/secrets/auth.env.example config/profiles/acme/secrets/auth.env
# Fill keys + SUPABASE_ACCESS_TOKEN in auth.env
melos run profile:use -- acme
melos run env:use:staging
melos run env:sync
```

## Auth token

Per-profile `auth.env` holds `SUPABASE_ACCESS_TOKEN`. `deploy.env` remains shared at `config/secrets/deploy.env`.
