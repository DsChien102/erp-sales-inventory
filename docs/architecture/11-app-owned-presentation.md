# ADR: App-owned presentation

Status: Accepted  
Date: 2026-09-03  
Supersedes: [10-hybrid-presentation-ownership.md](10-hybrid-presentation-ownership.md)

## Context

Hybrid ownership (pages/cubits in ERP, widgets in `modules/*/presentation`) still forced:

- Fake ACL ports / typedefs so module packages could not import other BC application layers
- Double homes for state and display models
- Separate Melos packages + example apps per BC

The app is already the composition root. Keeping a presentation package per module no longer pays for itself.

## Decision

**All presentation lives in ship-unit apps:**

| Concern | Location |
| -------- | -------- |
| Route pages, cubits, widgets, display VMs, feature support | `apps/erp/lib/features/<feature>/presentation/` |
| Widget preview catalog | `apps/erp/example/` |
| Admin-only UI | `apps/admin/lib/features/<feature>/presentation/` |

Module packages retain only: `domain` / `application` / `infrastructure` / `integration_events`.

Rules:

1. **Do not** create or expand `modules/*/presentation`.
2. New UI code goes in the consuming app (`erp` or `admin`).
3. Cross-BC orchestration imports other modules’ `vet45_*_application` only from apps.
4. Shared UI across ERP and Admin may be **duplicated** in both apps — do not reintroduce a shared presentation package.
5. IAM: ERP shells stay under ERP features; platform-admin surfaces live under Admin.

## Migration

Phased collapse by BC (Sales → Partner → Pricing/Catalog/Dashboard → IAM split → stub cleanup). Delete each `vet45_*_presentation` package when that BC has zero imports.

## Consequences

- One home for feature UI; fewer ports and mirror DTOs
- Example catalog unified under ERP
- Slight duplication between ERP and Admin for IAM widgets is accepted
- Module scaffolds no longer include a presentation layer by default
