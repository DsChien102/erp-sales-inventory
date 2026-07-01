# Dữ liệu và bảo mật

## Multi-tenant

- Bảng nghiệp vụ có `tenant_id` (UUID)
- Giai đoạn migration: `iam.tenants.legacy_public_tenant_id` bridge `public.tenants`
- JWT Supabase Auth — `auth.uid()` = `iam.user_accounts.id`

## Schema isolation

| Schema | Owner module |
| ------ | ------------ |
| `iam` | IdentityAccess |
| `catalog` | Catalog |
| `sales` | Sales |
| `partner` | Partner |

Migration: `supabase/migrations/`

## RPC-first security

- Mutations qua `security definer` functions trong schema module
- `iam.require_auth()` — bắt buộc đăng nhập
- `iam.require_permission(code, tenant_id)` — RBAC admin
- `iam.has_permission` / `can_perform` — query side

## Row Level Security (RLS)

- Bật trên bảng nhạy cảm
- Policy member-scoped (user chỉ đọc tenant mình tham gia)
- Revoke direct table access — ưu tiên RPC cho write

## Read path

- Authenticated select qua policy (membership-scoped)
- Read gateways trong infrastructure query PostgREST với user JWT

## Enforcement phases

Xem [adr/iam-multi-tenant-migration.md](../adr/iam-multi-tenant-migration.md):

1. **off** — auth + tenant only
2. **observe** — log deny
3. **enforce** — block ở app + RPC

## Secrets

- Service role key chỉ trên worker / CI — không embed trong Flutter client
- ERP: `--dart-define-from-file=.env` (dev) hoặc `.env.staging` / `.env.production` (release builds)
- `APP_ENV` + Flutter flavors (`development` / `staging` / `production`) — xem [operations/environments.md](../operations/environments.md)

## Liên kết

- [06-cross-cutting-concerns.md](06-cross-cutting-concerns.md)
- [IAM_PERMISSION_CATALOG.md](../Modules/IAM_PERMISSION_CATALOG.md)
