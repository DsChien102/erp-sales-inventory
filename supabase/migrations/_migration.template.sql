-- Title: catalog patch inline sku/barcode normalization
-- Kind: patch
-- Intent: catalog_sku_barcode_inline_normalize
-- Context: TH-02 / US-xx / FR-xx
-- Touches: _normalize_product_sku, create_product
-- Safety: idempotent ; medium
-- Depends on: 20260710001_catalog_product_reference_id

-- 1) DDL / helpers / triggers for this intent only
-- create or replace function catalog._normalize_product_sku(p_sku text)
-- returns text
-- language sql
-- immutable
-- as $$
--   select nullif(trim(both from p_sku), '');
-- $$;

-- 2) RPC that actually change for this intent (must match Touches)
-- create or replace function catalog.create_product(...)
-- returns ...
-- language plpgsql
-- security definer
-- set search_path = catalog, pg_temp
-- as $$
-- begin
--   ...
-- end;
-- $$;

-- 3) Grants
-- revoke all on function catalog.create_product(...) from public, anon;
-- grant execute on function catalog.create_product(...) to authenticated;

-- Notes:
-- - Patch/surgical: only CREATE OR REPLACE functions listed in Touches
-- - Do not copy unchanged RPC bodies from older migrations
-- - After promote: update supabase/migrations/REGISTRY.yaml owners
