# VET45 ERP

Flutter shell cho modular monolith ERP.

## Môi trường

| Lệnh | Mô tả |
|---|---|
| `melos run debug` | Dev local — flavor `development` + `.env` (envied) |
| `melos run debug:staging` | Flavor staging |
| `melos run build:ios:staging` | IPA staging |
| `melos run deploy:ios:staging` | Upload TestFlight staging |

Chi tiết: [docs/operations/environments.md](../../docs/operations/environments.md)

## Setup

```bash
cp .env.example .env
# Điền SUPABASE_CONNECTION_URL, SUPABASE_ANON_KEY

melos bootstrap
melos run codegen
melos run debug
```

Staging/production:

```bash
cp .env.staging.example .env.staging
cp .env.production.example .env.production
```

## iOS release

```bash
./scripts/build_ios.sh --env staging
./deploy-ios.sh --env staging
```

TestFlight setup: [docs/operations/testflight-asc-setup.md](../../docs/operations/testflight-asc-setup.md)
