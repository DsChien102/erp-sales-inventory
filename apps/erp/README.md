# Mosaic Retail ERP

Flutter shell cho modular monolith ERP.

## Môi trường

Biến môi trường nằm trong `apps/erp/.env` (không commit, đã nằm trong `.gitignore`), tạo tay với 3 khoá:

```env
APP_ENV=development
SUPABASE_CONNECTION_URL=<URL Supabase>
SUPABASE_ANON_KEY=<anon key>
```

- Supabase local (`supabase start`): URL là `http://127.0.0.1:54421`, lấy anon key bằng `supabase status`.
- Cần nhiều môi trường: tạo `.env.staging`, `.env.production`; script build iOS ưu tiên `.env.<env>` và quay về `.env` nếu không có.
- VS Code: dùng cấu hình **ERP · development / local / staging / production** trong `.vscode/launch.json`; chúng đọc `--dart-define-from-file=.env`.

## Setup

```bash
melos bootstrap
# tạo apps/erp/.env như trên
cd apps/erp && flutter run --flavor development --dart-define-from-file=.env
```

## iOS release

```bash
./scripts/build_ios.sh --env staging        # build IPA (flavor suy ra từ --env)
./deploy-ios.sh --env staging               # upload TestFlight, đọc deploy/deploy.env
```

Ghi đè đường dẫn: `ERP_ENV_FILE=/đường/dẫn/.env` cho build, `DEPLOY_SECRETS_FILE=/đường/dẫn/deploy.env` cho deploy.

TestFlight setup: [docs/operations/testflight-asc-setup.md](../../docs/operations/testflight-asc-setup.md)
