# Môi trường ERP (development / staging / production)

## Tổng quan

| Flavor | `APP_ENV` | Bundle ID | Supabase | TestFlight |
|---|---|---|---|---|
| `development` | `development` | `com.agapi.vet45.dev` | Dev project | Không |
| `staging` | `staging` | `com.agapi.vet45.staging` | Staging project | App ASC riêng |
| `production` | `production` | `com.agapi.vet45` | Production project | App ASC chính |

Messaging worker Railway: `staging` / `production` — map 1:1 với ERP staging/production.

## Config files

```
apps/erp/
  .env                    # local dev (gitignored) — envied fallback
  .env.example
  .env.staging            # gitignored
  .env.staging.example
  .env.production         # gitignored
  .env.production.example
```

**Priority:** `--dart-define` / `--dart-define-from-file` > envied (`.env`).

Keys bake vào app: `APP_ENV`, `SUPABASE_*`, `LOG_LEVEL`, `MESSAGING_CLIENT_POLL_ENABLED`.

Keys **không** bake vào app (chỉ deploy script): `APP_STORE_CONNECT_*` — giữ trong `.env` local hoặc CircleCI context `vet45-deploy`.

### Setup lần đầu

```bash
cp apps/erp/.env.staging.example apps/erp/.env.staging
cp apps/erp/.env.production.example apps/erp/.env.production
# Điền Supabase URL + anon key cho từng file
melos run codegen
```

## Chạy local

```bash
melos run debug              # development flavor + .env (envied)
melos run debug:dev          # development flavor + .env (explicit)
melos run debug:staging      # flavor staging + .env.staging
melos run debug:prod         # flavor production + .env.production
```

## Build & TestFlight

```bash
./apps/erp/scripts/build_ios.sh --env staging
./apps/erp/deploy-ios.sh --env staging

./apps/erp/scripts/build_ios.sh --env production
./apps/erp/deploy-ios.sh --env production
```

Hoặc qua Melos: `melos run build:ios:staging`, `melos run deploy:ios:staging`.

Xem [testflight-asc-setup.md](testflight-asc-setup.md) để tạo app ASC staging/production.

## CircleCI

File: [.circleci/config.yml](../../.circleci/config.yml)

| Workflow | Mô tả |
|---|---|
| `verify` | Mọi push/PR — `melos analyze` + `flutter test` (Linux) |
| `deploy_staging` | Manual approval — worker + iOS staging (macOS) |
| `deploy_production` | Manual approval — worker + iOS production (macOS) |

**Contexts cần tạo trên CircleCI:**

| Context | Variables |
|---|---|
| `vet45-staging` | `ERP_STAGING_SUPABASE_URL`, `ERP_STAGING_SUPABASE_ANON_KEY`, `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `WORKER_TICK_SECRET` |
| `vet45-production` | `ERP_PRODUCTION_SUPABASE_URL`, `ERP_PRODUCTION_SUPABASE_ANON_KEY`, worker secrets tương ứng |
| `vet45-deploy` | `APP_STORE_CONNECT_ISSUER_ID`, `APP_STORE_CONNECT_KEY_IDENTIFIER`, API key |

Phase 1: chỉ bật `verify` nếu chưa có macOS executor / signing.

## Đồng bộ messaging worker

Trước khi tắt `MESSAGING_CLIENT_POLL_ENABLED` trên staging ERP, deploy worker:

```bash
./apps/messaging_worker/scripts/deploy.sh --env staging --secrets
```

## iOS flavors

Schemes: `development`, `staging`, `production` trong `apps/erp/ios/Runner.xcodeproj/xcshareddata/xcschemes/`.

Chạy lại setup nếu cần: `python3 apps/erp/ios/scripts/setup_flavors.py`
