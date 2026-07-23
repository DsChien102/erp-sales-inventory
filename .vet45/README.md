# `.vet45/` — local env kit

| Path | Tracked? | Purpose |
|------|----------|---------|
| `templates/` | yes | Scaffold for `vet45 init <profileId>` |
| `deploy/` | yes (except `deploy.env`) | Shared iOS TestFlight target + secrets |
| `profiles/<id>/` | no | Local secrets per profile |
| `state.json` / `bin/` | no | Active profile/env + AOT binary |

Never commit filled `*.env` under `profiles/` or `deploy/deploy.env`.
