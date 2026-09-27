# Supabase Migration Conventions (Vet45)

Tai lieu nay la quy chuan chung cho **migration chinh thuc** trong `supabase/migrations/`.

## 0) Draft vs migration chinh thuc

| Loai | Path | Supabase CLI apply? |
| ---- | ---- | ------------------- |
| **Draft (agents / slice BE)** | `supabase/migrations/_drafts/<scope>_<description>.sql` | Khong |
| **Declarative SQL (function/view/trigger/policy)** | `modules/<m>/infrastructure/supabase/sql/...` hoac `supabase/sql/<schema>/...` | Khong (tool sinh migration) |
| **Migration chinh thuc** | `supabase/migrations/YYYYMMDDxxx_<scope>_<description>.sql` | Co |

Agents: xem [AGENTS.md](../../AGENTS.md) — **Schema & migration**. Chi promote draft / `migrate:generate` thanh file timestamp khi maintainer/user yeu cau; timestamp phai unique trong ca repo.

**Object stateless (RPC / view / trigger / policy)** uu tien luong declarative — xem [14-declarative-sql-objects.md](../../docs/architecture/14-declarative-sql-objects.md):

- Sua file nguon, khong copy body vao patch migration
- Object cu: `melos run schema:adopt -- <schema.fn>` (khong sinh migration)
- Thu nhanh: `melos run schema:apply-dev`
- Promote: `melos run migrate:generate -- <intent>` (Kind: generated)
- Lock: `supabase/schema.lock.yaml` — REGISTRY chi con object chua adopt

## 1) Dat ten file

- Dung format: `YYYYMMDDxxx_<scope>_<short_description>.sql`
  - `YYYYMMDD` = ngay tao migration (local date)
  - `xxx` = thu tu migration trong ngay do (`001`..`999`, zero-pad 3 chu so)
- Vi du:
  - `20260630001_iam_foundation.sql`
  - `20260630002_partner_theme_foundation.sql`
  - `20260709001_catalog_guided_create.sql`
- `<scope>` uu tien theo bounded context: `iam`, `partner`, `sales`, `platform`, ...
- `<short_description>` ngan gon, dung `snake_case`, mo ta "why" hon la "how".

## 2) Header bat buoc

Moi migration bat dau bang comment header:

```sql
-- Title: catalog patch inline sku/barcode normalization
-- Kind: patch
-- Intent: catalog_sku_barcode_inline_normalize
-- Context: TH-02 / US-xx / FR-xx
-- Touches: _normalize_product_sku, create_product, search_products
-- Safety: idempotent ; medium
-- Depends on: 20260710001_catalog_product_reference_id
```

| Kind | Khi dung | Gom duoc | Gioi han goi y |
|------|----------|----------|----------------|
| `bootstrap` | Greenfield subsystem (29 file catalog hien tai — grandfather) | schema + indexes + helpers + RPC khoi tao | Khong ap lint strict |
| `patch` | US/FR thay doi hanh vi | DDL lien quan + RPC **thuc su doi** cung intent | ≤8 functions, cung `-- Intent:` |
| `surgical` | Hotfix 1 RPC / 1 cot | 1–3 statement | ≤3 functions |

**Quy tac vang (chong regression):**

- Patch **khong** `create or replace` RPC khong nam trong `-- Touches:`
- **Khong** copy body RPC tu migration cu "cho dong bo"
- DDL cross-cutting (cot moi) **tach** khoi RPC khong lien quan

Neu migration chua RLS/policy/function quyen, ghi ro trong header.

## 2b) Cohesive slice + surgical patch

- **Authoring:** draft atomic (1 object / file) trong `_drafts/` — xem [_drafts/README.md](_drafts/README.md)
- **Apply:** promote gom theo intent (`--bundle-intent`) → 1 timestamp = 1 intent
- **Ownership:** `REGISTRY.yaml` — migration cuoi cung dinh nghia moi RPC
- **CI:** `melos run migrate:verify-policy -- --strict` — `Touches` phai khop body

File trong `REGISTRY.yaml → bootstrap_grandfathered` (29 migration bundled hien tai) duoc mien kiem tra strict.

## 3) Nguyen tac viet SQL

- Uu tien idempotent:
  - `create schema if not exists`
  - `create table if not exists`
  - `create index if not exists`
  - `drop ... if exists` truoc khi `create ...` khi can thay doi object
- Khong dung destructive operation trong migration thuong:
  - tranh `drop table`, `drop column`, `alter type ... drop value`
  - neu bat buoc, tao migration rieng co ke hoach backfill/rollback ro rang
- Moi thay doi DDL lon can tach thanh cac khoi ro nghia:
  - enum/type
  - table
  - index
  - function/trigger
  - grants/policies

## 4) Security va tenancy

- Moi table trong schema expose phai:
  - `enable row level security`
  - co policy tenant isolation ro rang
- Khong dua logic auth vao `user_metadata` claims.
- Function `security definer`:
  - dat `set search_path = <schema>, pg_temp`
  - revoke/grant execute ro role (`authenticated` hoac `service_role`)

## 5) Quy uoc schema Vet45

- Bounded context nao thi ghi vao schema do (`iam.*`, `partner.*`, ...)
- Khong cross-module table ownership.
- Projection/read-model co the o module owner, nhung source id phai truy vet duoc:
  - `source_module`, `source_entity_type`, `source_entity_id`

## 6) Indexing quy chuan

- Luon index theo query pattern trong FR/US (tenant + filter + sort).
- Voi tim kiem text:
  - can nhac `pg_trgm` + GIN index.
- Voi unique mang tinh nghiep vu:
  - chi dat unique khi business rule yeu cau hard-block.
  - Neu chi warning duplicate, khong dat unique constraint.

## 7) Verify truoc merge

- Kiem tra naming + syntax migration.
- Chay sequence verify toi thieu:
  - `supabase db reset` (neu co local db)
  - `supabase migration list --local`
  - `melos run test`
  - `melos run migrate:verify-policy -- --strict`
  - `melos run schema:verify-lock` (nhanh slice: warn; promote/release: fail)
  - `./scripts/ci/verify_harness.sh`
  - (CI co DB) `./scripts/ci/verify_schema_drift.sh` sau `supabase db reset`

## 8) Checklist review migration

- [ ] File name dung convention timestamp + scope + description
- [ ] Header co Kind, Intent, Touches (patch/surgical), Context, Safety, Depends on
- [ ] Touches khop moi `create or replace function` trong body
- [ ] REGISTRY.yaml cap nhat owner cho RPC trong Touches (sau promote)
- [ ] Idempotent primitives duoc dung hop ly
- [ ] RLS + policy + grant/revoke day du
- [ ] Index phu hop filter/sort/search thuc te
- [ ] Khong co destructive change khong duoc phe duyet
- [ ] Co ghi chu cho cac assumption quan trong

## 9) Template

Copy tu file: `supabase/migrations/_migration.template.sql`.
