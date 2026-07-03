# VET45

Hệ thống ERP cho phòng khám thú y và cửa hàng bán lẻ thú y — **multi-tenant**, nhiều cửa hàng/chi nhánh. Sản phẩm được deliver theo **theme** (TH-01..TH-11); kiến trúc kỹ thuật là **modular monolith**: một app Flutter (`apps/erp`) gồm nhiều bounded context trong `modules/`.

## Tech stack

| Thành phần | Công nghệ |
| ---------- | --------- |
| Client | Flutter 3.x, Dart SDK ≥ 3.11 |
| State / routing | flutter_bloc, go_router |
| DI | get_it |
| Backend | Supabase (Auth, Postgres, Storage) |
| Async messaging | Dart worker (`apps/messaging_worker`) trên Railway |
| Monorepo | Dart workspace + [Melos](https://melos.invertase.dev/) |

## Cấu trúc repository

```text
vet45/
├── apps/
│   ├── erp/                 # Flutter shell — UI, DI, feature adapters
│   └── messaging_worker/    # Server-side integration event worker
├── modules/                 # Bounded contexts (domain / application / infrastructure / …)
│   ├── iam/, catalog/, sales/, partner/, inventory/, …
├── packages/                # Shared kernel, adapters, design system, codegen
├── supabase/                # Local Supabase config + migrations
├── docs/                    # Kiến trúc, theme, module blueprints
└── pubspec.yaml             # Workspace root + Melos scripts
```

Mỗi module theo layer: `vet45_{module}_{domain|application|infrastructure|…}`.

## Yêu cầu

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable, khớp `sdk: ^3.11.1` trong `apps/erp/pubspec.yaml`)
- [Dart SDK](https://dart.dev/get-dart) ≥ 3.11
- [Melos](https://melos.invertase.dev/): `dart pub global activate melos`
- (Tuỳ chọn) [Supabase CLI](https://supabase.com/docs/guides/cli) — dev DB local
- (Tuỳ chọn) Xcode — build iOS

## Cài đặt nhanh

```bash
# 1. Clone và vào thư mục gốc
cd vet45

# 2. Cài dependency workspace
melos bootstrap

# 3. Cấu hình môi trường ERP
cp apps/erp/.env.example apps/erp/.env
# Điền SUPABASE_CONNECTION_URL và SUPABASE_ANON_KEY

# 4. Chạy app
melos run debug
```

Lệnh `melos run debug` chạy `flutter run --flavor development --dart-define-from-file=.env` trong `apps/erp`.

### Môi trường staging / production

```bash
cp apps/erp/.env.staging.example apps/erp/.env.staging
cp apps/erp/.env.production.example apps/erp/.env.production
# Điền Supabase URL + anon key cho từng file
```

| Lệnh | Mô tả |
| ---- | ----- |
| `melos run debug` | Dev local — flavor `development` + `--dart-define-from-file=.env` |
| `melos run debug:dev` | Flavor `development` + `.env` (explicit) |
| `melos run debug:staging` | Flavor staging + `.env.staging` |
| `melos run debug:prod` | Flavor production + `.env.production` |
| `melos run debug:web` | Chạy trên Chrome + `.env` |
| `melos run debug:ios` | iOS — flavor `development` + `.env` |

Chi tiết flavor, bundle ID, CircleCI: [docs/operations/environments.md](docs/operations/environments.md).

**Config:** `--dart-define` / `--dart-define-from-file` (compile-time).

## Supabase

Schema và RPC nằm trong `supabase/`. Dev local (cần Supabase CLI):

```bash
supabase start
# API: http://127.0.0.1:54321 — lấy anon key: supabase status
```

Áp migration lên remote:

```bash
supabase db push
```

App Flutter chỉ dùng **anon key**; mutation nghiệp vụ quan trọng đi qua **Postgres RPC** (defense in depth + RLS).

## Lệnh phát triển

```bash
melos bootstrap          # Link lại packages sau khi đổi pubspec
melos run codegen        # build_runner ở các module/package có cấu hình
melos run analyze        # dart analyze toàn workspace
melos run test           # dart test các package có thư mục test/ (trừ erp)
./scripts/ci/verify_harness.sh   # Layer guards + doc link checks
cd apps/erp && flutter test      # Unit/widget test shell app
cd apps/messaging_worker && dart test
```

**AI agents:** đọc [AGENTS.md](AGENTS.md) trước khi implement.

Scaffold module mới: `./scripts/scaffold_module.sh`.

## Messaging worker (tuỳ chọn)

Worker xử lý outbox/inbox và integration events server-side — không bắt buộc cho dev UI thuần.

```bash
supabase start
melos run worker:setup          # lần đầu — tạo apps/messaging_worker/.env
melos run worker:serve          # dart trên host → http://localhost:8080/health
melos run worker:once           # một tick rồi thoát
melos run worker:docker         # container AOT (giống Railway)
melos run worker:verify         # compile + optional docker build
```

Thủ công (tương đương `worker:serve`):

```bash
cp apps/messaging_worker/.env.example apps/messaging_worker/.env
# Điền SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, WORKER_TICK_SECRET

cd apps/messaging_worker
dart run bin/worker.dart --once
dart run bin/worker.dart --serve
```

Docker Compose: `docker-compose.yml` (service `messaging-worker`). Trong container, Supabase local dùng `host.docker.internal:54321`.

Deploy Railway: `railway.toml` + `apps/messaging_worker/Dockerfile`. Trên staging/production, tắt poll phía client (`MESSAGING_CLIENT_POLL_ENABLED=false`) sau khi worker đã chạy.

## Build iOS & TestFlight

```bash
./apps/erp/scripts/build_ios.sh --env staging
./apps/erp/deploy-ios.sh --env staging
```

Hoặc: `melos run build:ios:staging`, `melos run deploy:ios:staging`.

Thiết lập App Store Connect: [docs/operations/testflight-asc-setup.md](docs/operations/testflight-asc-setup.md).

## CI

CircleCI (`.circleci/config.yml`):

- **verify** — mọi push/PR: `verify_workspace`. Trên `dev`/`main`: approval → worker verify/deploy staging. Trên `main`: approval → worker verify/deploy production.

## Tài liệu

| Tài liệu | Nội dung |
| -------- | -------- |
| [AGENTS.md](AGENTS.md) | Onboarding cho AI coding agents |
| [docs/architecture/](docs/architecture/) | Kiến trúc nền — modular monolith, layers, messaging |
| [docs/themes/](docs/themes/) | Theme sản phẩm TH-01..TH-11 |
| [docs/operations/](docs/operations/) | Môi trường, TestFlight, deploy |
| [docs/MODULES_IMPLEMENTATION_TEMPLATE.md](docs/MODULES_IMPLEMENTATION_TEMPLATE.md) | Template implement module |
| [apps/erp/README.md](apps/erp/README.md) | Ghi chú riêng cho Flutter shell |

## Kiến trúc tóm tắt

- **Theme ≠ module** — một theme có thể span nhiều bounded context.
- Module **không import** implementation nội bộ module khác; giao tiếp qua integration events và snapshot ports.
- **Domain** thuần Dart; **Application** điều phối command/query; **Infrastructure** gọi Supabase RPC.
- UI có thể nằm trong `modules/*/presentation` hoặc `apps/erp/lib/features/`.

Đọc thêm: [docs/architecture/01-vision-and-principles.md](docs/architecture/01-vision-and-principles.md).

## License

Proprietary — Agapi / internal use.
