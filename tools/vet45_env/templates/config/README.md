# Local Vet45 secrets templates

Committed workspace/target manifests live at the repo root:

- `vet45.workspace.json`
- `apps/*/vet45.target.json`
- `config/deploy/vet45.target.json`

This directory only scaffolds **local secrets**:

```bash
melos bootstrap
melos run env:init
```

Then copy examples and fill values:

```bash
cp config/secrets/development.env.example config/secrets/development.env
# fill secrets, then:
vet45 sync
```

Re-scaffold secret templates with:

```bash
melos run env:init -- --force
```

(`--force` never overwrites filled `*.env` secret files.)

See [docs/operations/environment-manager.md](../../../../docs/operations/environment-manager.md).
