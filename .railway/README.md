# Railway configuration (VET45)

SSOT for the Railway **project** (services, knobs, healthcheck) is:

```txt
.railway/railway.ts
```

Evaluate it with the Railway CLI. The TypeScript SDK lives in the repo-root
`package.json` (`railway` / `railway-iac-ts`). Dart/Flutter apps do not use it.

**Node 22 required.** `tsx` (used by `railway-iac-ts`) cannot resolve
`railway/iac` on Node 24. From the repo root:

```bash
npm install
./scripts/railway-config.sh plan
./scripts/railway-config.sh apply
```

Or: `nvm exec 22 -- railway config plan`.

## Infra vs code deploy

| Việc | Lệnh |
|------|------|
| Đổi infra (env knobs, healthcheck, watchPatterns, replicas) | `./scripts/railway-config.sh plan` rồi `apply` |
| Đẩy image/code worker | `./apps/messaging_worker/scripts/deploy.sh` (`railway up`) |
| Đẩy secrets (Supabase, tick, Resend) | `./apps/messaging_worker/scripts/set_secrets.sh` |

`apply` không thay `deploy.sh`. Secrets không commit vào `railway.ts` — dùng `preserve()` và inject qua `set_secrets.sh`.

## Commands

```bash
railway config pull          # import live project (overwrites railway.ts)
./scripts/railway-config.sh plan
./scripts/railway-config.sh apply
```

- `plan` is safe and does not change Railway.
- `apply` previews and asks before applying unless you pass `--yes`.
- Destructive changes in agent/CI sessions also need `--confirm-destructive`.
- Do not manage the same service with `railway.toml` / `railway.json` and this file.
- Use `replicas` for scaling. Imported secrets stay as `preserve()`.
- Do not set `restartPolicyType: "ON_FAILURE"` in `railway.ts` — it is the
  platform default and never converges in `plan`.
