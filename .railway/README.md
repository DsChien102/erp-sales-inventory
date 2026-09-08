# Railway configuration (VET45)

Handover (project sạch, secrets, first deploy): [docs/operations/railway_messaging_worker.md](../docs/operations/railway_messaging_worker.md).

Nguồn image: [ADR 12](../docs/architecture/12-railway-image-source.md) (Accepted). Service đã `source: image` thì không `railway up`.

SSOT for the Railway **project** (services, knobs, healthcheck) is:

```txt
.railway/railway.ts
```

Evaluate it with the Railway CLI. The TypeScript SDK lives in
[`.railway/package.json`](package.json) (`railway` / `railway-iac-ts`). Dart/Flutter apps do not use it.

**Node 22 required.** `tsx` (used by `railway-iac-ts`) cannot resolve
`railway/iac` on Node 24.

```bash
cd .railway && npm install          # once
vet45 run railway plan              # active env must be staging or production
vet45 run railway apply
```

## Infra vs code deploy

| Việc | Lệnh |
|------|------|
| Đổi infra (env knobs, healthcheck, replicas) | `vet45 run railway plan` rồi `apply` |
| Publish image worker | `vet45 run worker publish` |
| Đẩy secrets | `vet45 run railway sync-env` |
| Pull image | `vet45 run railway rollout` |

`apply` không publish image. Secret không commit vào `railway.ts` — shared qua `ctx.shared`, secret service `preserve()` + `sync-env`.

## Commands

```bash
railway config pull          # import live project (overwrites railway.ts)
vet45 run railway plan
vet45 run railway apply
```

- `plan` is safe and does not change Railway.
- `apply` previews and asks before applying unless you pass `--yes`.
- Destructive changes in agent/CI sessions also need `--confirm-destructive`.
- Do not manage the same service with `railway.toml` / `railway.json` and this file.
- Use `replicas` for scaling. Imported secrets stay as `preserve()`.
- Do not set `restartPolicyType: "ON_FAILURE"` in `railway.ts` — it is the
  platform default and never converges in `plan`.
