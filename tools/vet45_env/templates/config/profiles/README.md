# Configuration profiles

Profiles isolate **secrets roots** and optional **Supabase account tokens** when you work with multiple hosted projects or client workspaces.

Registry: committed `vet45.workspace.json` (`profiles.entries`). `profile init` appends there.

| Profile | Secrets root | Use when |
| ------- | ------------ | -------- |
| `default` | `config/secrets/` | Main workspace |

Shared deploy credentials stay in `config/secrets/deploy.env` for all profiles.

## Commands

```bash
melos run profile:list
melos run profile:use -- <profile-id>
melos run profile:init -- <profile-id> [--description "Client X"]
```

Set `SUPABASE_ACCESS_TOKEN` in each profile's `auth.env` when switching Supabase accounts.

See [docs/operations/environment-manager.md](../../docs/operations/environment-manager.md).
