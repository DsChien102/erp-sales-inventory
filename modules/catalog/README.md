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

### Application layout (`custom_fields` — golden for new areas)

```text
application/lib/src/custom_fields/
  shared/                                    # cross-use-case DTOs
  initialize_custom_field_template/
  upsert_custom_field_group/
  reorder_custom_field_groups/
  upsert_custom_field/
  configure_custom_field_attributes/
  reorder_custom_fields/
  list_custom_field_config/
```

Mỗi `<use_case>/` chứa command/query (+ handler/validator khi có BE). Legacy areas (`guided_create/`, `units/`) vẫn flat — refactor dần; **area mới** phải theo layout trên. Guard: `scripts/ci/guard_application_use_case_layout.sh`.

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

- **EPIC-02/US-01 CONTRACT + BE + FE + E2E:** atomic guided create (`CreateGuidedProductCommand` → `catalog.create_guided_product`) + dup check (`CheckDuplicateProductCodeQuery`); `CreateProductCommand` remains for minimal create compatibility.
- Draft SQL: `supabase/migrations/_drafts/01_catalog_guided_create.sql` (chưa promote — runtime RPC cần migration apply)
- ERP DI: `CatalogStartup` trong `apps/erp/lib/core/di/injection.dart`
- E2E: `apps/erp/test/features/catalog/presentation/pages/product_guided_create_e2e_test.dart`
