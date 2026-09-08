# Railway messaging worker (handover)

Playbook chuyển giao: dựng **project Railway sạch** rồi deploy `messaging-worker`. Tài liệu này dành cho ops / người nhận repo — không phải kiến trúc messaging (xem [07-integration-and-messaging.md](../architecture/07-integration-and-messaging.md)).

## Phạm vi

Railway **chỉ** chạy worker Dart. ERP và Admin (Flutter) **không** deploy lên Railway.

| Environment Railway | ERP flavor | Supabase |
| ------------------- | ---------- | -------- |
| `staging` | `staging` (`com.agapi.vet45.staging`) | Project staging |
| `production` | `production` (`com.agapi.vet45`) | Project production |

Tên project IaC: `VET45`. Tên service: `messaging-worker`.

## Ba lớp — đừng trộn

| Lớp | SSOT | Lệnh | Ghi chú |
| --- | ---- | ---- | ------- |
| Infra | [`.railway/railway.ts`](../../.railway/railway.ts) | `vet45 run railway plan` rồi `apply` | Service, healthcheck, knobs `WORKER_*`, replicas. Shared keys: `ctx.shared` |
| Secrets | `.vet45/profiles/<profileId>/<env>.env` | `vet45 run railway sync-env` | Shared: `SUPABASE_URL`, `APP_LINK_BASE_URL`. Service: role key, tick, Resend. Không set knobs |
| Image | monorepo root (Docker context) | `vet45 run worker publish` | Build `linux/amd64`, push version + pointer env. Không redeploy |
| Rollout | [`.railway/services.txt`](../../.railway/services.txt) | `vet45 run railway rollout` | `redeploy --from-source` từng service trong file |

Chi tiết knobs IaC: [`.railway/README.md`](../../.railway/README.md). Scaling: [messaging_worker_scaling.md](messaging_worker_scaling.md).

**Accepted:** GitLab build/push, Railway pull — [ADR 12](../architecture/12-railway-image-source.md). `messaging-worker` là instance đầu (`source: image`). Không `railway up` service đã chuyển image. `apply` vẫn không đẩy image — phải push registry trước.

## Điều kiện trước

1. Account Railway + [CLI](https://docs.railway.com/develop/cli) (`brew install railway` hoặc script cài chính thức).
2. **Node 22.** `railway config` / `tsx` không resolve `railway/iac` trên Node 24. Dùng `nvm exec 22` nếu máy đang Node khác.
3. Clone monorepo, `melos bootstrap`, `npm install` trong `.railway/` (package `railway` — chỉ cho IaC, không phải runtime Flutter).
4. Migration messaging đã apply trên Supabase đích; schema `platform` expose trong API settings. Danh sách file: [messaging_schema.md](messaging_schema.md).
5. Profile env local: `vet45 init <profileId>` rồi điền `.vet45/profiles/<profileId>/staging.env` (và `production.env` khi lên prod). Xem [environment-manager.md](environment-manager.md).

## Bootstrap project Railway sạch

Thứ tự bắt buộc: **tạo project → apply IaC (tạo service) → secrets → `railway up`**.

**Không** chạy `railway up` ngay từ root repo khi chưa có service `messaging-worker`. `package.json` gốc chỉ chứa Railway TypeScript SDK — CLI dễ tạo service Node sai.

### 1. Đăng nhập và tạo project trống

```bash
railway login
railway init --name VET45
railway status --json
```

`init` tạo project và link thư mục hiện tại. Environment mặc định thường là `production`. Tạo thêm `staging` (tên phải khớp script):

```bash
railway environment new staging
```

Chọn env đang làm việc:

```bash
railway environment staging
```

Nếu project `VET45` đã tồn tại trên workspace: `railway link --project VET45` thay vì `init`.

### 2. Tạo service bằng IaC

Từ root repo, **trên từng environment** (`staging` rồi `production`):

```bash
cd .railway && npm install    # once
vet45 run railway plan
vet45 run railway apply
```

`plan` không đổi Railway. `apply` preview rồi hỏi xác nhận (trừ `--yes`). Thay đổi destructive trong session agent/CI cần thêm `--confirm-destructive`.

Kết quả kỳ vọng: service `messaging-worker` với:

- Builder `DOCKERFILE`, path `apps/messaging_worker/Dockerfile`
- Healthcheck `GET /health` (timeout 90s)
- Replica region `asia-southeast1-eqsg3a`
- Knobs (`WORKER_LOG_LEVEL`, batch, tick interval, `WORKER_ENV` = tên environment Railway)
- Secrets khai `preserve()` — lúc này còn trống

Không quản lý cùng service bằng `railway.toml` / `railway.json` **và** `railway.ts`.

### 3. Điền secrets local rồi đẩy lên Railway

```bash
cp .vet45/profiles/<profileId>/staging.env.example \
   .vet45/profiles/<profileId>/staging.env
# Điền key bên dưới

melos run env:use:staging
melos run env:sync
```

Bắt buộc trên Railway (worker):

| Key | Vai trò |
| --- | ------- |
| `SUPABASE_URL` | URL project Supabase cùng env |
| `SUPABASE_SERVICE_ROLE_KEY` | Worker only — **không** đưa vào ERP |
| `WORKER_TICK_SECRET` | Auth `POST /tick` (ops); client ERP không nhúng secret này |

Tuỳ chọn (bỏ qua nếu trống): `RESEND_API_KEY`, `RESEND_FROM_DOMAIN`, `APP_LINK_BASE_URL`.

Knobs (`WORKER_LOG_LEVEL`, `WORKER_TENANT_BATCH_SIZE`, …) thuộc IaC — **không** đưa vào profile, không set bằng `sync-env`.

### 4. Image và secret lần đầu

Build context là **cả monorepo** (`Dockerfile` `COPY . .`). Publish không redeploy.

```bash
vet45 use staging
./apps/messaging_worker/scripts/publish.sh --env staging --verify
vet45 run railway sync-env
vet45 run railway rollout
```

Nếu chưa có public domain:

```bash
railway domain --service messaging-worker --environment staging
```

### 5. Production

Lặp bước 2–4 với `--env production` và file `production.env` (Supabase production riêng). `apply` khi đang link environment `production`.

Trước khi tắt `MESSAGING_CLIENT_POLL_ENABLED` trên ERP staging/production, worker env tương ứng phải đang chạy.

## Việc hàng ngày (project đã có)

```bash
vet45 use staging
vet45 run worker publish          # registry only
vet45 run railway sync-env        # profile → Railway (khi secret đổi)
vet45 run railway rollout         # pull pointer, không build
```

`vet45 run railway apply` chỉ khi đổi knobs, healthcheck, hoặc image pointer trong `railway.ts`.

## Kiểm tra

```bash
curl -sf "https://<worker-host>/health"
railway logs --service messaging-worker --environment staging --lines 50
```

Log tick kỳ vọng:

```text
tick {"tenantsProcessed":0,"rounds":0,"durationMs":12,"errorsCount":0,"hadBacklog":false}
```

`POST /tick` chỉ dùng ops — không nhúng secret vào app:

```bash
curl -sf -X POST "https://<worker-host>/tick" \
  -H "Authorization: Bearer $WORKER_TICK_SECRET"
```

## CI

Token: `RAILWAY_TOKEN` (project-scoped). CircleCI contexts `vet45-staging` / `vet45-production` — xem [environments.md](environments.md).

`sync-env.sh --ci` đọc cùng tên biến: `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `WORKER_TICK_SECRET`, cộng `RESEND_*` / `APP_LINK_BASE_URL` nếu có. Wrapper cũ: `apps/messaging_worker/scripts/set_secrets.sh`.

Không commit `.env`, service role, hay `RAILWAY_TOKEN`.

## Rollback

| Tình huống | Việc làm |
| ---------- | -------- |
| Deploy xấu | Publish image version trước, rồi `vet45 run railway rollout` |
| Tắt worker | `railway down --service messaging-worker --environment <env> -y` |
| Sai secret | `vet45 run railway sync-env` |

## Anti-patterns

- `railway up` từ root khi chưa có service `messaging-worker` (dễ tạo service từ `package.json` IaC).
- `railway config apply` trên một environment rồi `railway up` environment kia — instance trống (vd. apply `production`, up `staging`) trả 404/502.
- `railway config apply` rồi coi như đã ship code — image vẫn cần `vet45 run worker publish` rồi `rollout`.
- Set knobs worker bằng `railway variable set` / `sync-env` — lần `apply` sau sẽ drift so với `railway.ts`.
- Ghi secret vào `railway.ts` (shared `ctx.shared` + service `preserve()`; đẩy bằng `sync-env`).
- `restartPolicyType: "ON_FAILURE"` trong `railway.ts` — platform default, `plan` không bao giờ converge.
- Deploy worker env A rồi trỏ ERP flavor B vào Supabase khác.

## Liên kết

- [12-railway-image-source.md](../architecture/12-railway-image-source.md) — ADR Accepted (mọi service Railway)
- [`.railway/README.md`](../../.railway/README.md) — IaC plan/apply
- [`apps/messaging_worker/README.md`](../../apps/messaging_worker/README.md) — local dev, redeploy, CI draft
- [environments.md](environments.md) — map flavor ERP ↔ Railway ↔ Supabase
- [messaging_schema.md](messaging_schema.md) — RPC / view worker phụ thuộc
- [messaging_worker_scaling.md](messaging_worker_scaling.md) — concurrency / replica
- [environment-manager.md](environment-manager.md) — profile `.vet45`
