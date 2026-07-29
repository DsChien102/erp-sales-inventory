# `.vet45/` — local env kit

| Path | Tracked? | Purpose |
|------|----------|---------|
| `deploy/` | yes (except `deploy.env`) | Shared iOS TestFlight target + generated `deploy.env.example` |
| `profiles/<id>/` | no | Local secrets per profile (`vet45 init` / `vet45 example`) |
| `state.json` / `bin/` | no | Active profile/env + AOT binary |

Profile `.env.example` files are **generated** from `vet45.target.json` keys (comment format `# <targetId>: <description>`). There is no committed `templates/` folder.

Never commit filled `*.env` under `profiles/` or `deploy/deploy.env`.
