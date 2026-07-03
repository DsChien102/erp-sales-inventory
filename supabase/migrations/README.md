# Supabase Migration Conventions (Vet45)

Tai lieu nay la quy chuan chung cho **migration chinh thuc** trong `supabase/migrations/`.

## 0) Draft vs migration chinh thuc

| Loai | Path | Supabase CLI apply? |
| ---- | ---- | ------------------- |
| **Draft (agents / slice BE)** | `supabase/migrations/_drafts/<scope>_<description>.sql` | Khong |
| **Migration chinh thuc** | `supabase/migrations/YYYYMMDDHHMMSS_<scope>_<description>.sql` | Co |

Agents: xem [AGENTS.md](../../AGENTS.md) — **Schema & migration**. Chi promote draft thanh file timestamp khi maintainer/user yeu cau; timestamp phai unique trong ca repo.

## 1) Dat ten file

- Dung format: `YYYYMMDDHHMMSS_<scope>_<short_description>.sql`
- Vi du:
  - `20260630000001_iam_foundation.sql`
  - `20260630000002_partner_theme_foundation.sql`
- `<scope>` uu tien theo bounded context: `iam`, `partner`, `sales`, `platform`, ...
- `<short_description>` ngan gon, dung `snake_case`, mo ta "why" hon la "how".

## 2) Header bat buoc

Moi migration bat dau bang comment header:

```sql
-- <Title>: <1-line intent>
-- Context: <ticket/theme/us/fr hoac ly do thay doi>
-- Safety: <idempotent|one-way> ; <expected lock/data impact>
```

Neu migration chua RLS/policy/function quyen, ghi ro trong header.

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
  - `./scripts/ci/verify_harness.sh`

## 8) Checklist review migration

- [ ] File name dung convention timestamp + scope + description
- [ ] Header co context + safety
- [ ] Idempotent primitives duoc dung hop ly
- [ ] RLS + policy + grant/revoke day du
- [ ] Index phu hop filter/sort/search thuc te
- [ ] Khong co destructive change khong duoc phe duyet
- [ ] Co ghi chu cho cac assumption quan trong

## 9) Template

Copy tu file: `supabase/migrations/_migration.template.sql`.
