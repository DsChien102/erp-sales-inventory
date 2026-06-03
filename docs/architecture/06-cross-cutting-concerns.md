# Cross-cutting concerns

## Identity & Access (TH-01 foundation)

Module `iam` — bounded context **IdentityAccess**:

- User account, tenant, membership, role, permission catalogue
- Public contracts: `IIamModule`, `IAccessChecker`, `IExecutionContext`
- ERP: `IamAuthSyncService` sync user on login

Chi tiết: [IDENTITY_ACCESS_MODULES.md](../Modules/IDENTITY_ACCESS_MODULES.md)

## Tenant context

- Mọi dữ liệu nghiệp vụ scoped `tenant_id`
- `app_current_tenant_id()` — bridge legacy trong giai đoạn migration
- ADR: [iam-multi-tenant-migration.md](../adr/iam-multi-tenant-migration.md)

**IAM không sở hữu** tenant settings nghiệp vụ (giá, thuế sales, catalog…) — mỗi module có `{Module}TenantSettings`.

## Permission enforcement rollout

```text
off → observe → enforce
```

- Phase hiện tại: auth + tenant; RBAC wired, chưa enforce đầy đủ Catalog/Sales
- Matrix: [IAM_PERMISSION_MATRIX.md](../Modules/IAM_PERMISSION_MATRIX.md)

## Dependency injection

| Thành phần | Đăng ký tại |
| ---------- | ----------- |
| `IIamModule`, `IAccessChecker` | `apps/erp/lib/core/di/injection.dart` |
| Per-module buses | `{Module}Startup` → GetIt container |
| Supabase client | ERP bootstrap, truyền vào module startups |

## Messaging orchestrator (ERP)

`apps/erp/lib/core/messaging/` — lifecycle observer, poll policy, module registry (catalog, sales, partner, iam).

Worker chạy flush durable; client có thể tắt poll qua env.

## Module public contracts (liên theme)

| Contract | Consumer |
| -------- | -------- |
| `IAccessChecker` | Mọi module mutation admin |
| `ProductForSalesSnapshot` | Sales ← Catalog |
| `CustomerSnapshot` | Sales ← Partner |
| Integration event types | Inventory, Costing, … |

## Liên kết

- [08-data-and-security.md](08-data-and-security.md)
- [07-integration-and-messaging.md](07-integration-and-messaging.md)
- [themes/TH-01-store-setup/](../themes/TH-01-store-setup/)
