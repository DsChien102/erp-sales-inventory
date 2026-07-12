-- Title: catalog patch business_status soft_deleted schema
-- Kind: patch
-- Intent: catalog_business_status_soft_deleted
-- Context: TH-02 EPIC-07 — business_status is source of truth for soft delete
-- Touches:
-- Safety: idempotent ; low — ADD VALUE only (must commit before backfill)
-- Depends on: 20260712003_catalog_rename_basic_stock_quantity_base
--
-- Postgres 55P04: new enum values cannot be used in the same transaction as
-- ALTER TYPE ... ADD VALUE. Run/commit this file alone, then run
-- 001b_catalog_patch_business_status_soft_deleted_backfill.sql.

alter type catalog.product_business_status
  add value if not exists 'soft_deleted';
