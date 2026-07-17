# Vet45 configuration

Committed:

- [`vet45.workspace.json`](../vet45.workspace.json) — environments, profiles, scan
- [`default/`](default/) — default profile (`*.env.example` committed; `*.env` gitignored)
- [`deploy/`](deploy/) — deploy target + shared `deploy.env`
- `apps/*/vet45.target.json` — app targets

Profile layout (no nested `secrets/` folder):

```text
config/<profileId>/
  development.env(.example)
  staging.env(.example)
  auth.env(.example)
```

```bash
cp config/default/development.env.example config/default/development.env
# fill secrets
vet45 sync
```

New profile:

```bash
vet45 profile init acme --description "Client Acme"
# creates config/acme/ + registry entry in vet45.workspace.json
```

See [docs/operations/environment-manager.md](../docs/operations/environment-manager.md).
