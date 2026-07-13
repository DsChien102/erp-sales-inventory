-- Title: catalog patch base price before/after VAT schema
-- Kind: patch
-- Intent: catalog_base_price_vat
-- Context: TH-02 EPIC-06 — split base_price_amount into after (required when set) + before (nullable)
-- Touches:
-- Safety: idempotent ; medium — rename column + add nullable before
-- Depends on: 20260709002_catalog_operational_data, 001_catalog_patch_price_band_vat_effective_schema

-- Current amount becomes after-VAT. Before-VAT stays null for now.
do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'catalog'
      and table_name = 'product_base_price_profiles'
      and column_name = 'base_price_amount'
  ) and not exists (
    select 1
    from information_schema.columns
    where table_schema = 'catalog'
      and table_name = 'product_base_price_profiles'
      and column_name = 'base_price_after_vat'
  ) then
    alter table catalog.product_base_price_profiles
      rename column base_price_amount to base_price_after_vat;
  end if;
end $$;

alter table catalog.product_base_price_profiles
  add column if not exists base_price_before_vat numeric null
    check (base_price_before_vat is null or base_price_before_vat >= 0);

-- If a prior draft created after_vat without renaming amount, backfill then drop amount.
do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'catalog'
      and table_name = 'product_base_price_profiles'
      and column_name = 'base_price_amount'
  ) and exists (
    select 1
    from information_schema.columns
    where table_schema = 'catalog'
      and table_name = 'product_base_price_profiles'
      and column_name = 'base_price_after_vat'
  ) then
    update catalog.product_base_price_profiles
    set base_price_after_vat = coalesce(base_price_after_vat, base_price_amount)
    where base_price_after_vat is null
      and base_price_amount is not null;

    alter table catalog.product_base_price_profiles
      drop column base_price_amount;
  end if;
end $$;

-- Ensure after-VAT stays non-negative (rename keeps existing check name may vary).
alter table catalog.product_base_price_profiles
  drop constraint if exists product_base_price_profiles_base_price_amount_check;

alter table catalog.product_base_price_profiles
  drop constraint if exists product_base_price_profiles_base_price_after_vat_check;

alter table catalog.product_base_price_profiles
  add constraint product_base_price_profiles_base_price_after_vat_check
  check (base_price_after_vat is null or base_price_after_vat >= 0);

-- after_vat remains nullable at rest (seed row = null ⇒ chưa có giá).
-- Write path requires after when setting a price; has_base_price checks after is not null.
-- before_vat stays null for legacy rows (no backfill).

comment on column catalog.product_base_price_profiles.base_price_after_vat is
  'Base price after VAT (numeric). Required when a base price is set; null = missing.';
comment on column catalog.product_base_price_profiles.base_price_before_vat is
  'Base price before VAT (numeric, optional/temporary).';
