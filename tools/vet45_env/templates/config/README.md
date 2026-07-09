# Local Vet45 configuration

This directory is **gitignored** and created by:

```bash
melos bootstrap
melos run env:init
```

Templates live in `tools/vet45_env/templates/config/`. Re-scaffold scaffold files with:

```bash
melos run env:init -- --force
```

(`--force` never overwrites filled `*.env` secret files.)

See [docs/operations/environment-manager.md](../docs/operations/environment-manager.md).
