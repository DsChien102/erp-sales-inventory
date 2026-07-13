-- Title: catalog patch price band VAT + effective + status schema
-- Kind: patch
-- Intent: catalog_price_band_vat_effective
-- Context: TH-02 EPIC-06 — list/floor before+after VAT; effective window; status
-- Touches:
-- Safety: idempotent ; medium — rename columns + backfill + partial unique
-- Depends on: 20260709020_catalog_list_price_bands_base_price, 20260712008_catalog_patch_business_status_soft_deleted_read_rpcs

-- Rename before-VAT amounts (legacy list/floor). Keep NUMERIC storage.
do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'catalog'
      and table_name = 'product_unit_price_bands'
      and column_name = 'list_price_amount'
  ) then
    alter table catalog.product_unit_price_bands
      rename column list_price_amount to list_price_before_vat;
  end if;

  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'catalog'
      and table_name = 'product_unit_price_bands'
      and column_name = 'floor_price_amount'
  ) then
    alter table catalog.product_unit_price_bands
      rename column floor_price_amount to floor_price_before_vat;
  end if;
end $$;

-- Ensure before-VAT columns remain numeric if a prior draft cast them to bigint.
do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'catalog'
      and table_name = 'product_unit_price_bands'
      and column_name = 'list_price_before_vat'
      and data_type = 'bigint'
  ) then
    alter table catalog.product_unit_price_bands
      alter column list_price_before_vat type numeric using list_price_before_vat::numeric;
  end if;

  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'catalog'
      and table_name = 'product_unit_price_bands'
      and column_name = 'floor_price_before_vat'
      and data_type = 'bigint'
  ) then
    alter table catalog.product_unit_price_bands
      alter column floor_price_before_vat type numeric using floor_price_before_vat::numeric;
  end if;
end $$;

alter table catalog.product_unit_price_bands
  add column if not exists list_price_after_vat numeric null
    check (list_price_after_vat is null or list_price_after_vat >= 0),
  add column if not exists floor_price_after_vat numeric null
    check (floor_price_after_vat is null or floor_price_after_vat >= 0),
  add column if not exists effective_from timestamptz null,
  add column if not exists effective_to timestamptz null,
  add column if not exists status text not null default 'active';

-- If after-VAT was previously bigint, cast back to numeric.
do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'catalog'
      and table_name = 'product_unit_price_bands'
      and column_name = 'list_price_after_vat'
      and data_type = 'bigint'
  ) then
    alter table catalog.product_unit_price_bands
      alter column list_price_after_vat type numeric using list_price_after_vat::numeric;
  end if;

  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'catalog'
      and table_name = 'product_unit_price_bands'
      and column_name = 'floor_price_after_vat'
      and data_type = 'bigint'
  ) then
    alter table catalog.product_unit_price_bands
      alter column floor_price_after_vat type numeric using floor_price_after_vat::numeric;
  end if;
end $$;

alter table catalog.product_unit_price_bands
  drop constraint if exists chk_product_unit_price_bands_status;

alter table catalog.product_unit_price_bands
  add constraint chk_product_unit_price_bands_status
  check (status in ('active', 'inactive', 'deleted'));

alter table catalog.product_unit_price_bands
  drop constraint if exists chk_price_bands_floor_le_list;

alter table catalog.product_unit_price_bands
  drop constraint if exists chk_price_bands_floor_before_le_list_before;

alter table catalog.product_unit_price_bands
  add constraint chk_price_bands_floor_before_le_list_before
  check (
    floor_price_before_vat is null
    or list_price_before_vat is null
    or floor_price_before_vat <= list_price_before_vat
  );

alter table catalog.product_unit_price_bands
  drop constraint if exists chk_price_bands_floor_after_le_list_after;

alter table catalog.product_unit_price_bands
  add constraint chk_price_bands_floor_after_le_list_after
  check (
    floor_price_after_vat is null
    or list_price_after_vat is null
    or floor_price_after_vat <= list_price_after_vat
  );

alter table catalog.product_unit_price_bands
  drop constraint if exists chk_price_bands_effective_window;

alter table catalog.product_unit_price_bands
  add constraint chk_price_bands_effective_window
  check (
    effective_to is null
    or effective_from is null
    or effective_to > effective_from
  );

-- Backfill effective window, status, and required list after-VAT from before-VAT.
update catalog.product_unit_price_bands
set
  effective_from = coalesce(effective_from, created_at, now()),
  status = coalesce(nullif(status, ''), 'active'),
  list_price_after_vat = coalesce(list_price_after_vat, list_price_before_vat)
where effective_from is null
   or status is null
   or status = ''
   or list_price_after_vat is null;

alter table catalog.product_unit_price_bands
  alter column effective_from set default now();

alter table catalog.product_unit_price_bands
  alter column effective_from set not null;

-- list after-VAT is required going forward (legacy rows backfilled above).
alter table catalog.product_unit_price_bands
  alter column list_price_after_vat set not null;

-- One active band per product unit.
alter table catalog.product_unit_price_bands
  drop constraint if exists uq_product_unit_price_bands_unit;

drop index if exists catalog.uq_product_unit_price_bands_unit;
drop index if exists catalog.uq_product_unit_price_bands_active_unit;

create unique index uq_product_unit_price_bands_active_unit
  on catalog.product_unit_price_bands (product_id, product_unit_id)
  where status = 'active';

comment on column catalog.product_unit_price_bands.list_price_before_vat is
  'List (niêm yết) price before VAT (numeric).';
comment on column catalog.product_unit_price_bands.floor_price_before_vat is
  'Floor (sàn) price before VAT (numeric, optional).';
comment on column catalog.product_unit_price_bands.list_price_after_vat is
  'List price after VAT (numeric, required).';
comment on column catalog.product_unit_price_bands.floor_price_after_vat is
  'Floor price after VAT (numeric, optional).';
comment on column catalog.product_unit_price_bands.status is
  'active | inactive | deleted';
