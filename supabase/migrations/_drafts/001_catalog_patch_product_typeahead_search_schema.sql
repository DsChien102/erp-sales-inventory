-- Title: catalog patch product typeahead search schema
-- Kind: patch
-- Intent: catalog_product_typeahead_search
-- Context: TH-02 / EPIC-01 — search_text + pg_trgm for contains typeahead; dual-refresh with search_document
-- Touches: _build_product_search_text, _refresh_product_search_document, _trg_products_refresh_search_document, _trg_product_custom_field_values_refresh_search_document, _trg_custom_fields_refresh_search_document, _trg_custom_field_options_refresh_search_document
-- Safety: idempotent ; medium — backfill search_text + GIN trgm index
-- Depends on: 20260712011_catalog_patch_sku_uppercase_search_products

create schema if not exists extensions;

create extension if not exists unaccent with schema extensions;
create extension if not exists pg_trgm with schema extensions;

-- ---------------------------------------------------------------------------
-- 1) search_text column + indexes
-- ---------------------------------------------------------------------------

alter table catalog.products
  add column if not exists search_text text not null default '';

create index if not exists idx_products_search_text_trgm
  on catalog.products using gin (search_text gin_trgm_ops);

create index if not exists idx_products_tenant_status_updated
  on catalog.products (tenant_id, business_status, updated_at desc);

-- ---------------------------------------------------------------------------
-- 2) Build search_text (unaccent + lower; name/trade/sku/barcode + searchable CF)
-- ---------------------------------------------------------------------------

create or replace function catalog._build_product_search_text(
  p_tenant_id uuid,
  p_product_id uuid
)
returns text
language sql
stable
security definer
set search_path = catalog, extensions, pg_temp
as $$
  select lower(
    catalog.unaccent_immutable(
      trim(
        both from concat_ws(
          ' ',
          nullif(btrim(coalesce(p.name, '')), ''),
          nullif(btrim(coalesce(p.trade_name, '')), ''),
          nullif(btrim(coalesce(p.sku, '')), ''),
          nullif(btrim(coalesce(p.barcode, '')), ''),
          nullif(
            btrim(
              coalesce(
                (
                  select string_agg(
                    catalog._product_custom_field_display_value(
                      f.field_type,
                      v.value_text,
                      v.value_number,
                      v.value_date,
                      v.value_boolean,
                      o.label
                    ),
                    ' '
                  )
                  from catalog.custom_field_groups g
                  join catalog.custom_fields f
                    on f.group_id = g.id
                   and f.tenant_id = p_tenant_id
                  join catalog.product_custom_field_values v
                    on v.custom_field_id = f.id
                   and v.product_id = p_product_id
                   and v.tenant_id = p_tenant_id
                  left join catalog.custom_field_options o
                    on o.id = v.value_option_id
                  where g.tenant_id = p_tenant_id
                    and g.status = 'active'
                    and f.status = 'active'
                    and f.is_searchable = true
                    and f.field_type in ('text', 'singleSelect')
                ),
                ''
              )
            ),
            ''
          )
        )
      )
    )
  )
  from catalog.products p
  where p.id = p_product_id
    and p.tenant_id = p_tenant_id;
$$;

-- ---------------------------------------------------------------------------
-- 3) Refresh both search_document + search_text
-- ---------------------------------------------------------------------------

create or replace function catalog._refresh_product_search_document(
  p_tenant_id uuid,
  p_product_id uuid
)
returns void
language plpgsql
security definer
set search_path = catalog, extensions, pg_temp
as $$
begin
  update catalog.products p
  set
    search_document = coalesce(
      catalog._build_product_search_document(p_tenant_id, p_product_id),
      ''::tsvector
    ),
    search_text = coalesce(
      catalog._build_product_search_text(p_tenant_id, p_product_id),
      ''
    )
  where p.id = p_product_id
    and p.tenant_id = p_tenant_id;
end;
$$;

create or replace function catalog._trg_products_refresh_search_document()
returns trigger
language plpgsql
security definer
set search_path = catalog, extensions, pg_temp
as $$
begin
  perform catalog._refresh_product_search_document(new.tenant_id, new.id);
  return new;
end;
$$;

create or replace function catalog._trg_product_custom_field_values_refresh_search_document()
returns trigger
language plpgsql
security definer
set search_path = catalog, extensions, pg_temp
as $$
declare
  v_tenant_id uuid;
  v_product_id uuid;
begin
  if tg_op = 'DELETE' then
    v_tenant_id := old.tenant_id;
    v_product_id := old.product_id;
  else
    v_tenant_id := new.tenant_id;
    v_product_id := new.product_id;
  end if;

  perform catalog._refresh_product_search_document(v_tenant_id, v_product_id);
  return coalesce(new, old);
end;
$$;

create or replace function catalog._trg_custom_fields_refresh_search_document()
returns trigger
language plpgsql
security definer
set search_path = catalog, extensions, pg_temp
as $$
begin
  perform catalog._refresh_product_search_document(v.tenant_id, v.product_id)
  from catalog.product_custom_field_values v
  where v.custom_field_id = new.id
    and v.tenant_id = new.tenant_id;
  return new;
end;
$$;

create or replace function catalog._trg_custom_field_options_refresh_search_document()
returns trigger
language plpgsql
security definer
set search_path = catalog, extensions, pg_temp
as $$
begin
  perform catalog._refresh_product_search_document(v.tenant_id, v.product_id)
  from catalog.product_custom_field_values v
  where v.value_option_id = new.id
    and v.tenant_id = new.tenant_id;
  return new;
end;
$$;

drop trigger if exists trg_products_refresh_search_document on catalog.products;
create trigger trg_products_refresh_search_document
  after insert or update of name, trade_name, sku, barcode
  on catalog.products
  for each row
  execute function catalog._trg_products_refresh_search_document();

drop trigger if exists trg_product_custom_field_values_refresh_search_document
  on catalog.product_custom_field_values;
create trigger trg_product_custom_field_values_refresh_search_document
  after insert or update or delete
  on catalog.product_custom_field_values
  for each row
  execute function catalog._trg_product_custom_field_values_refresh_search_document();

drop trigger if exists trg_custom_fields_refresh_search_document on catalog.custom_fields;
create trigger trg_custom_fields_refresh_search_document
  after update of is_searchable, status
  on catalog.custom_fields
  for each row
  execute function catalog._trg_custom_fields_refresh_search_document();

drop trigger if exists trg_custom_field_options_refresh_search_document
  on catalog.custom_field_options;
create trigger trg_custom_field_options_refresh_search_document
  after update of label
  on catalog.custom_field_options
  for each row
  execute function catalog._trg_custom_field_options_refresh_search_document();

-- ---------------------------------------------------------------------------
-- 4) Backfill search_text (and refresh document for consistency)
-- ---------------------------------------------------------------------------

update catalog.products p
set
  search_document = coalesce(
    catalog._build_product_search_document(p.tenant_id, p.id),
    ''::tsvector
  ),
  search_text = coalesce(
    catalog._build_product_search_text(p.tenant_id, p.id),
    ''
  );

revoke all on function catalog._build_product_search_text(uuid, uuid)
  from public, anon;
grant execute on function catalog._build_product_search_text(uuid, uuid)
  to authenticated, service_role;

revoke all on function catalog._refresh_product_search_document(uuid, uuid)
  from public, anon;
grant execute on function catalog._refresh_product_search_document(uuid, uuid)
  to authenticated, service_role;
