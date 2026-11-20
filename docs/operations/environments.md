# Môi trường ERP (development / staging / production)

## Tổng quan

| Flavor | `APP_ENV` | Bundle ID | Supabase | TestFlight |
|---|---|---|---|---|
| `development` | `development` | `com.dschien.erp.dev` | Dev project (remote) hoặc `supabase start` trên máy | Không |
| `staging` | `staging` | `com.dschien.erp.staging` | Staging project | App ASC riêng |
| `production` | `production` | `com.dschien.erp` | Production project | App ASC chính |

Không còn worker chạy riêng (`apps/messaging_worker` đã xoá ở 8-D): email qua Edge Function `send-email` (2-B2); e-invoice chạy bằng Edge Function `einvoice-processor`. Secrets của Edge Function (MISA, Resend, service role…) đặt trên Supabase (`supabase secrets set`), không nằm trong file `.env` của app.

## File cấu hình

```
apps/erp/.env              # development (gitignored)
apps/erp/.env.staging      # staging (gitignored, tuỳ chọn)
apps/erp/.env.production   # prlafmoduction (gitignored, tuỳ chọn)
deploy/deploy.env          # APP_STORE_CONNECT_* — dùng chung mọi flavor iOS (gitignored)
deploy/deploy.env.example  # mẫu, committed
```

File `.env` của app viết tay, gồm các key:

| Key | Bắt buộc | Ghi chú |
|---|---|---|
| `APP_ENV` | Có | `development` / `staging` / `production` |
| `SUPABASE_CONNECTION_URL` | Có | URL project Supabase |
| `SUPABASE_ANON_KEY` | Có | anon/public key |
| `LOG_LEVEL` | Không | mặc định `INFO` |
| `MESSAGING_CLIENT_POLL_ENABLED` | Không | mặc định `false` |

**Runtime:** `--dart-define-from-file` khi `flutter run` / `flutter build` — key bake vào binary lúc compile.

## Chạy local

```bash
cd apps/erp
flutter run --flavor development --dart-define-from-file=.env
flutter run -d chrome --flavor development --dart-define-from-file=.env
```

Dùng Supabase local: `supabase start`, rồi lấy URL + anon key từ `supabase status` điền vào `apps/erp/.env`.

## Build & TestFlight

```bash
./apps/erp/scripts/build_ios.sh --env staging     # build IPA
./apps/erp/deploy-ios.sh --env staging            # upload IPA lên App Store Connect
```

`build_ios.sh` đọc `apps/erp/.env.<env>`, không có thì dùng `apps/erp/.env`; ghi đè bằng `ERP_ENV_FILE=/đường/dẫn/file.env`.

`APP_STORE_CONNECT_*` trong `deploy/deploy.env` (`cp deploy/deploy.env.example deploy/deploy.env` rồi điền).

Xem [testflight-asc-setup.md](testflight-asc-setup.md) để tạo app ASC staging/production.

## iOS flavors

Schemes: `development`, `staging`, `production` trong `apps/erp/ios/Runner.xcodeproj/xcshareddata/xcschemes/`.
