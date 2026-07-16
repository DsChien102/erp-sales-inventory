# Vet45 local configuration

Committed:

- [`vet45.workspace.json`](../vet45.workspace.json) (repo root) — environments + profiles + scan
- [`deploy/vet45.target.json`](deploy/vet45.target.json) — iOS TestFlight secrets-only target
- `apps/*/vet45.target.json` — app targets (auto-discovered)

Local / gitignored:

- `secrets/*.env` — fill from `*.env.example` (scaffold via `melos run env:init`)
- `profiles/<id>/secrets/*.env` — per-profile secrets

```bash
melos bootstrap
melos run env:init
cp config/secrets/development.env.example config/secrets/development.env
# fill secrets, then:
vet45 sync
```

See [docs/operations/environment-manager.md](../docs/operations/environment-manager.md).
