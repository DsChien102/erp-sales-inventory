# VET45 ERP

Flutter shell cho modular monolith ERP.

## Môi trường

Secrets nằm trong `config/secrets/`; `melos run env:sync` sinh `apps/erp/.env*` (generated — không chỉnh tay).

| Lệnh | Mô tả |
|---|---|
| `melos run env:sync` | Sync `.env` theo active environment |
| `melos run debug` | ERP — active env (mặc định `development`) |
| `melos run debug:staging` | Staging + sync + run |
| `melos run build:ios:staging` | IPA staging (qua manifest + sync) |
| `melos run deploy:ios:staging` | Upload TestFlight staging |

Chi tiết: [docs/operations/environment-manager.md](../../docs/operations/environment-manager.md) · [environments.md](../../docs/operations/environments.md)

## Setup

```bash
melos bootstrap
cp config/secrets/development.env.example config/secrets/development.env
# Điền Supabase URL + keys (remote dev)

melos run env:sync
melos run env:doctor
melos run debug
```

Supabase CLI local (`supabase start`):

```bash
melos run env:local
melos run debug
```

Staging/production secrets: `config/secrets/staging.env`, `config/secrets/production.env` → `melos run env:use:staging` + `env:sync`.

## iOS release

```bash
./scripts/build_ios.sh --env staging
./deploy-ios.sh --env staging
```

TestFlight setup: [docs/operations/testflight-asc-setup.md](../../docs/operations/testflight-asc-setup.md)
