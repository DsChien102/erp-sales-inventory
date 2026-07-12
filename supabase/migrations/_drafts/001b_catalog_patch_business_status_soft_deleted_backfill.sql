-- Title: catalog patch business_status soft_deleted backfill
-- Kind: patch
-- Intent: catalog_business_status_soft_deleted
-- Context: TH-02 EPIC-07 — backfill soft_deleted from deleted_at audit column
-- Touches:
-- Safety: idempotent ; medium — backfill from deleted_at
-- Depends on: 001_catalog_patch_business_status_soft_deleted_schema.sql
--
-- Must run in a separate transaction AFTER 001 is committed (Postgres 55P04).

-- Backfill: soft-deleted rows (audit deleted_at) become business_status soft_deleted.
update catalog.products
set business_status = 'soft_deleted'::catalog.product_business_status
where deleted_at is not null
  and business_status <> 'soft_deleted'::catalog.product_business_status;

comment on column catalog.products.deleted_at is
  'Audit timestamp for soft delete; source of truth is business_status = soft_deleted.';

comment on column catalog.products.business_status is
  'Lifecycle: active | inactive | soft_deleted (soft delete overwrites prior status).';
