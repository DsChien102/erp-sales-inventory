# Vet45 secrets layout

All runtime configuration is edited in `config/secrets/` (gitignored `*.env`), then applied with `melos run env:sync`.

This directory is the **default profile** secrets root (`config/profiles.json`). For additional Supabase accounts/clients, see [config/profiles/README.md](../profiles/README.md).

| File | Purpose |
| ---- | ------- |
| `auth.env` | Optional `SUPABASE_ACCESS_TOKEN` for Supabase CLI |
| `development.env` | Remote dev — shared canonical secrets for erp + worker |
| `local.env` | Optional overrides when using `supabase start` |
| `staging.env` | Staging Supabase + worker tuning |
| `production.env` | Production Supabase + worker tuning |
| `deploy.env` | Shared iOS TestFlight (`APP_STORE_CONNECT_*`) — deploy target only |

## First-time setup

```bash
cp config/secrets/development.env.example config/secrets/development.env
# Fill Supabase URL + keys, then:
melos run env:sync
```

See [docs/operations/environment-manager.md](../../docs/operations/environment-manager.md).
