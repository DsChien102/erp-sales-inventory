# Catalog — TH-02 bounded context

Owner module for product master, readiness, UOM, stock/base price profiles, price band, and custom fields. Theme harness: [docs/themes/TH-02-product-pricing/](../../docs/themes/TH-02-product-pricing/).

## Folder map

```text
modules/catalog/
  application/          # commands, queries, handlers, DTOs, ports, FakeCatalogModule
  domain/               # Product aggregate, CatalogPermissions, readiness, value objects
  infrastructure/
    lib/src/configuration/
      data_access/      # gateways only
      mediation/        # registerGeneratedCatalogHandlers + queries
      processing/       # CatalogCommandPipeline, ModuleDefinition, generated/
        generated/      # *.g.dart — commit after melos run codegen
    lib/src/domain/     # Supabase RPC adapters
```

## Codegen ritual

```bash
melos bootstrap
cd modules/catalog/infrastructure && dart run build_runner build
# or: melos run codegen
```

Builders (IAM-style — no messaging registries yet):

- `cqrs_registrar` → `registerGeneratedCatalogHandlers` / `registerGeneratedCatalogQueries`
- `cqrs_infrastructure` → `CatalogCommandRegistration` bus extensions
- `access_metadata` → `catalogAccessMetadataRegistry`
- `module_manifest` → `CatalogModuleDefinition`

## Current slice

- **EPIC-02/US-01 CONTRACT + BE + FE + E2E:** guided create (`CreateProductCommand`) + dup check (`CheckDuplicateProductCodeQuery`)
- Draft SQL: `supabase/migrations/_drafts/01_catalog_guided_create.sql` (chưa promote — runtime RPC cần migration apply)
- ERP DI: `CatalogStartup` trong `apps/erp/lib/core/di/injection.dart`
- E2E: `apps/erp/test/features/catalog/presentation/pages/product_guided_create_e2e_test.dart`
