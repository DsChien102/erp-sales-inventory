# Mosaic Retail

Hệ thống ERP cho phòng khám thú y và cửa hàng bán lẻ thú y — **multi-tenant**, nhiều cửa hàng/chi nhánh. Sản phẩm được deliver theo **theme** (TH-01..TH-11); kiến trúc kỹ thuật là **modular monolith**: một app Flutter (`apps/erp`) gồm nhiều bounded context trong `modules/`.

## Tech stack

| Thành phần | Công nghệ |
| ---------- | --------- |
| Client | Flutter 3.x, Dart SDK ≥ 3.11 |
| State / routing | flutter_bloc, go_router |
| DI | get_it |
| Backend | Supabase (Auth, Postgres, Storage, Edge Functions) |
| Monorepo | Dart pub workspace |

## Cấu trúc repository

```text
c45/
├── apps/
│   └── erp/                 # Flutter app duy nhất — UI, DI, feature, quản trị nền tảng
├── packages/                # Shared kernel, design system, lint
├── supabase/                # Local Supabase config + migrations
├── docs/                    # Kiến trúc, theme, module blueprints
└── pubspec.yaml             # Workspace root + Melos scripts
```

## Yêu cầu

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable, khớp `sdk: ^3.11.1` trong `apps/erp/pubspec.yaml`)
- [Dart SDK](https://dart.dev/get-dart) ≥ 3.11
- (Tuỳ chọn) [Supabase CLI](https://supabase.com/docs/guides/cli) — dev DB local
- (Tuỳ chọn) Xcode — build iOS

## Cài đặt nhanh

```bash
# 1. Clone và vào thư mục gốc
cd c45

# 2. Cài dependency workspace
dart pub get

# 3. Cấu hình môi trường: tạo apps/erp/.env với APP_ENV, SUPABASE_CONNECTION_URL, SUPABASE_ANON_KEY
#    (Supabase local: http://127.0.0.1:54421, lấy key bằng `supabase status`)

# 4. Chạy app
cd apps/erp && flutter run --flavor development --dart-define-from-file=.env
```

Chi tiết: [apps/erp/README.md](apps/erp/README.md). Trong VS Code có sẵn các cấu hình chạy **ERP · development / local / staging / production**.

Chi tiết flavor, bundle ID: [docs/operations/environments.md](docs/operations/environments.md).

**Config:** `--dart-define` / `--dart-define-from-file` (compile-time).

## Supabase

Schema và RPC nằm trong `supabase/`. Dev local (cần Supabase CLI):

```bash
supabase start
# API: http://127.0.0.1:54421 — lấy anon key: supabase status
```

Áp migration lên remote:

```bash
supabase db push
```

App Flutter chỉ dùng **anon key**; mutation nghiệp vụ quan trọng đi qua **Postgres RPC** (defense in depth + RLS).

Tổ chức tạo bằng **Đăng ký cửa hàng mới** trên màn đăng nhập. Không có vai trò Platform Admin và không có lệnh `c45 admin`.

## Lệnh phát triển

```bash
dart pub get                                                       # Link lại packages sau khi đổi pubspec
(cd apps/erp && dart run build_runner build --delete-conflicting-outputs)   # codegen
dart analyze apps/erp packages/c45_design_system packages/c45_lints   # analyze
./scripts/ci/verify_harness.sh   # Layer guards + doc link checks
cd apps/erp && flutter test      # Unit/widget test shell app
```

**AI agents:** đọc [AGENTS.md](AGENTS.md) trước khi implement.

## Versioning & changelog (ship units)

Ship units có version/changelog riêng: `erp`, `c45_design_system`.
Các module/package khác vẫn workspace-pinned — ghi note dưới **Internal** của unit ship liên quan.

```bash
# Ghi note vào <unit>/CHANGELOG.md → ## [Unreleased] khi làm feature
./apps/erp/scripts/bump_version.sh --patch --dry-run
./packages/c45_design_system/scripts/bump_version.sh --patch --dry-run
```

Chi tiết (framework flat `flutter_exec` / `dart_lib` / …): [docs/operations/app_versioning.md](docs/operations/app_versioning.md).

PR template (GitHub): [`.github/pull_request_template.md`](.github/pull_request_template.md).

## Build iOS & TestFlight

```bash
./apps/erp/scripts/build_ios.sh --env staging   # chỉ build
./apps/erp/deploy-ios.sh --env staging          # upload TestFlight
```

Thiết lập App Store Connect: [docs/operations/testflight-asc-setup.md](docs/operations/testflight-asc-setup.md).

## CI

Chưa cấu hình CI/CD. Kiểm tra local trước khi push: `dart analyze apps/erp packages/c45_design_system packages/c45_lints` và `cd apps/erp && flutter test`.

## Tài liệu

| Tài liệu | Nội dung |
| -------- | -------- |
| [AGENTS.md](AGENTS.md) | Onboarding cho AI coding agents |
| [docs/refactor/](docs/refactor/) | Refactor sang kiến trúc đơn giản — SCOPE, PLAN, CHECKLIST |
| [docs/requirements/](docs/requirements/) | Đặc tả nghiệp vụ chuẩn TH-01…08 |
| [docs/operations/](docs/operations/) | Môi trường, TestFlight, deploy |
| [apps/erp/README.md](apps/erp/README.md) | Ghi chú riêng cho Flutter shell |

## Kiến trúc tóm tắt

- **Theme ≠ module** — một theme có thể span nhiều bounded context.
- Module **không import** implementation nội bộ module khác; giao tiếp qua integration events và snapshot ports.
- **Domain** thuần Dart; **Application** điều phối command/query; **Infrastructure** gọi Supabase RPC.
- UI thuộc ship unit: `apps/erp/lib/features/`. Xem [AGENTS.md](AGENTS.md).

Đọc thêm: [AGENTS.md](AGENTS.md), [docs/refactor/SCOPE.md](docs/refactor/SCOPE.md).

## License

Proprietary — Agapi / internal use.
