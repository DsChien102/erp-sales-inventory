# Default profile (`config/default`)

Secrets root for the **default** configuration profile.

| File | Purpose |
| ---- | ------- |
| `auth.env` | Optional `SUPABASE_ACCESS_TOKEN` for Supabase CLI |
| `development.env` | Remote dev — shared canonical secrets for apps |
| `local.env` | Optional overrides when using `supabase start` |
| `staging.env` | Staging Supabase + worker tuning |
| `production.env` | Production Supabase + worker tuning |

iOS TestFlight keys live in [`../deploy/deploy.env`](../deploy/deploy.env) (shared, not per-profile).

```bash
cp config/default/development.env.example config/default/development.env
# fill keys, then:
vet45 sync
```
