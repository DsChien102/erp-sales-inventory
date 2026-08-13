# Cấu trúc repository

## Cây thư mục tổng quan

```text
vet45/
├── apps/
│   ├── erp/                    # Flutter shell — UI, DI, adapters
│   └── messaging_worker/       # Server-side messaging loop (shell)
├── modules/
│   ├── {bounded_context}/
│   │   ├── domain/
│   │   ├── application/
│   │   ├── infrastructure/
│   │   ├── integration_events/
│   │   └── presentation/       # optional (catalog, sales, partner)
│   │       ├── lib/            # reusable BC widgets / cubits
│   │       └── example/        # Flutter catalog — preview/audit widgets (not in Melos workspace)
│   ├── iam/
│   ├── catalog/
│   ├── sales/
│   ├── partner/
│   ├── inventory/
│   ├── costing/
│   ├── dashboard/
│   └── accounting/
├── packages/
│   ├── vet45_shared/           # domain, application, infrastructure kernel
│   ├── vet45_adapters/         # Supabase RPC, messaging, outbox/inbox
│   ├── vet45_annotations/      # codegen metadata
│   ├── vet45_design_system/
│   └── vet45_generator/
├── scripts/
│   └── scaffold_module.sh      # Regenerate module layer skeletons
├── supabase/
│   └── migrations/             # SQL schema + RPC (greenfield bootstrap)
└── docs/
    ├── architecture/
    └── themes/
```

## Module trong workspace (greenfield skeleton)

Định nghĩa trong root `pubspec.yaml` workspace — **40 package** module skeleton, chưa có business logic:

| Module | Layers |
| ------ | ------ |
| catalog, sales, partner, iam, inventory, costing, dashboard, accounting | domain, application, infrastructure, integration_events, presentation |

Tenant (multi-tenant identity, membership) nằm trong module **iam**, không có bounded context `tenant` riêng.

Mỗi layer có `pubspec.yaml`, barrel `lib/{layer}.dart`, và placeholder tối thiểu (`I{Name}Module`, `{Name}Startup`).

## Quy ước đặt tên package

```text
vet45_{module}_{layer}
```

Ví dụ: `vet45_sales_application`, `vet45_iam_domain`.

## Barrel export

Mỗi layer:

```text
lib/application.dart    # public API
lib/src/...             # private — không import từ package khác
```

## ERP feature adapters

`apps/erp/lib/features/{feature}/` — shell app adapters (auth, dashboard). Module adapters được thêm lại khi rebuild từng theme.

## Liên kết

- [shared-toolkit.md](shared-toolkit.md)
- [05-layered-module-structure.md](05-layered-module-structure.md)
- [themes/README.md](../themes/README.md)
- [MODULES_IMPLEMENTATION_TEMPLATE.md](../MODULES_IMPLEMENTATION_TEMPLATE.md)
