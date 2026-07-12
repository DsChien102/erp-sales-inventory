-- Title: catalog patch SKU uppercase normalize
-- Kind: patch
-- Intent: catalog_sku_uppercase_normalize
-- Context: TH-02 — store SKU as uppercase (trim + upper) instead of lowercase
-- Touches: _normalize_product_sku
-- Safety: idempotent ; medium — backfill products.sku to uppercase
-- Depends on: 20260712008_catalog_patch_business_status_soft_deleted_read_rpcs
--
-- Note: no pre-backfill collision raise. Blank/whitespace SKUs normalize to NULL and
-- may repeat per tenant (allowed). Real duplicate non-null SKUs are unchanged by
-- lower→upper for ASCII and were already possible without a unique index.

create or replace function catalog._normalize_product_sku(p_sku text)
returns text
language sql
immutable
as $$
  select nullif(upper(btrim(coalesce(p_sku, ''))), '');
$$;

-- Backfill stored SKUs; BEFORE normalize trigger + AFTER search_document refresh on sku.
-- Empty/whitespace → NULL; other values → uppercase.
update catalog.products
set sku = catalog._normalize_product_sku(sku)
where sku is distinct from catalog._normalize_product_sku(sku);

comment on function catalog._normalize_product_sku(text) is
  'Inline SKU normalize: trim + uppercase; empty → null.';
