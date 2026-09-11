# ADR: Hybrid presentation ownership

Status: **Superseded** by [11-app-owned-presentation.md](11-app-owned-presentation.md)  
Date: 2026-09-03

## Context

Putting multi-bounded-context orchestration (e.g. Sales compose + Pricing + Partner + Catalog) inside `modules/<module>/presentation` forces fake ACL ports (`typedef` + ERP lookup mappers). That raises maintain cost without protecting a real package boundary — the app already is the composition root.

Collapsing all UI into `apps/erp` would remove module widget packages, example catalogs, and isolated widget tests.

## Decision (historical)

**Hybrid dual path** (pages/cubits in ERP; reusable widgets in module presentation) — retained briefly as an intermediate step, then replaced by full app-owned presentation.

## Supersession

Widgets, models, cubits, and example catalogs now live under `apps/erp` (and `apps/admin` for Admin IAM). See ADR 11.
