# Mosaic Retail ERP

Flutter shell cho modular monolith ERP.

## Môi trường

Secrets nằm trong `.c45/profiles/<profileId>/`; `melos run env:sync` sinh `apps/erp/.env*` (generated — không chỉnh tay).

| Lệnh | Mô tả |
|---|---|
| `melos run env:sync` | Sync `.env` theo active environment |
| `melos run debug` | ERP — active env (mặc định `development`) |
| `melos run debug:staging` | Staging + sync + run |
| `melos run build:ios` | Build IPA — active env (staging\|production) |
| `melos run deploy:ios` | Build + upload TestFlight — active env |
| `melos run build:ios:staging` | Shortcut staging build |
| `melos run deploy:ios:staging` | Shortcut staging build + upload |

Chi tiết: [docs/operations/environment-manager.md](../../docs/operations/environment-manager.md) · [environments.md](../../docs/operations/environments.md)

## Setup

```bash
melos bootstrap
cp .c45/profiles/<profileId>/development.env.example .c45/profiles/<profileId>/development.env
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

Staging/production secrets: `.c45/profiles/<profileId>/staging.env`, `.c45/profiles/<profileId>/production.env` → `melos run env:use:staging` + `env:sync`.

## iOS release

```bash
./scripts/build_ios.sh --env staging
./deploy-ios.sh --env staging
```

TestFlight setup: [docs/operations/testflight-asc-setup.md](../../docs/operations/testflight-asc-setup.md)
