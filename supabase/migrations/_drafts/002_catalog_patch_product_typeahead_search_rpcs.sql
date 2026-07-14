-- Title: catalog patch product typeahead search_products
-- Kind: patch
-- Intent: catalog_product_typeahead_search
-- Context: TH-02 / EPIC-01 — contains typeahead via search_text; two-phase id→enrich; FTS rank only
-- Touches: search_products
-- Safety: idempotent ; medium
-- Depends on: 001_catalog_patch_product_typeahead_search_schema.sql

create or replace function catalog.search_products(
  p_tenant_id uuid,
  p_keyword text default null,
  p_business_statuses text[] default array['active']::text[],
  p_readiness_filter text default null,
  p_include_soft_deleted boolean default false,
  p_limit int default 50,
  p_offset int default 0,
  p_custom_field_filters jsonb default '[]'::jsonb,
  p_sort_order text default 'updated_at_desc'
)
returns table (
  product_id uuid,
  name text,
  trade_name text,
  sku text,
  barcode text,
  primary_image_url text,
  business_status text,
  is_soft_deleted boolean,
  base_unit_name text,
  stock_qty numeric,
  list_price numeric,
  floor_price numeric,
  updated_at timestamptz,
  has_base_unit boolean,
  has_images boolean,
  has_stock boolean,
  has_base_price boolean,
  has_price_band boolean,
  has_required_custom_fields boolean,
  stock_mode text,
  base_price_mode text,
  custom_field_values jsonb,
  total_count bigint
)
language plpgsql
security definer
set search_path = catalog, iam, extensions, pg_temp
as $$
declare
  v_keyword text;
  v_sku_keyword text;
  v_keyword_unaccented text;
  v_keyword_pattern text;
  v_tsquery tsquery;
  v_sort_order text;
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  if not iam.has_permission(p_tenant_id, 'catalog.product.view') then
    raise exception 'permission denied: catalog.product.view';
  end if;

  v_keyword := nullif(btrim(coalesce(p_keyword, '')), '');
  v_sku_keyword := catalog._normalize_product_sku(v_keyword);
  v_keyword_unaccented := nullif(
    lower(btrim(catalog.unaccent_immutable(coalesce(v_keyword, '')))),
    ''
  );
  -- Escape LIKE metacharacters for contains pattern.
  v_keyword_pattern := case
    when v_keyword_unaccented is null then null
    else '%'
      || replace(
        replace(replace(v_keyword_unaccented, '\', '\\'), '%', '\%'),
        '_',
        '\_'
      )
      || '%'
  end;

  if v_keyword_unaccented is null then
    v_tsquery := null;
  else
    v_tsquery := websearch_to_tsquery('simple', v_keyword_unaccented);
    if numnode(v_tsquery) = 0 then
      v_tsquery := null;
    end if;
  end if;

  v_sort_order := case
    when p_sort_order = 'relevance_desc' then 'relevance_desc'
    else 'updated_at_desc'
  end;

  return query
  with matched as (
    -- Phase A: cheap columns only (no operational facts / image / price).
    select
      p.id,
      p.name,
      p.trade_name,
      p.sku,
      p.barcode,
      p.search_document,
      p.business_status::text as business_status,
      (p.business_status = 'soft_deleted'::catalog.product_business_status) as is_soft_deleted,
      p.updated_at
    from catalog.products p
    where p.tenant_id = p_tenant_id
      and (
        p_include_soft_deleted
        or p.business_status <> 'soft_deleted'::catalog.product_business_status
        or 'soft_deleted' = any (p_business_statuses)
      )
      and p.business_status::text = any (p_business_statuses)
      and (
        v_keyword is null
        or (
          v_keyword_pattern is not null
          and p.search_text like v_keyword_pattern escape '\'
        )
        or (v_sku_keyword is not null and p.sku = v_sku_keyword)
        or (v_keyword is not null and p.barcode = btrim(v_keyword))
        or (
          v_sku_keyword is not null
          and length(v_sku_keyword) >= 1
          and p.sku like v_sku_keyword || '%'
        )
      )
      and catalog._product_matches_custom_field_filters(
        p_tenant_id,
        p.id,
        coalesce(p_custom_field_filters, '[]'::jsonb)
      )
  ),
  readiness_candidates as (
    -- When readiness filter set: apply facts here (still no image/price enrich).
    select
      m.*,
      f.has_base_unit,
      f.has_images,
      f.has_stock,
      f.has_base_price,
      f.has_price_band,
      f.has_required_custom_fields,
      f.stock_mode,
      f.base_price_mode
    from matched m
    cross join lateral catalog._product_operational_facts(p_tenant_id, m.id) f
    where p_readiness_filter is not null
      and (
        (
          p_readiness_filter = 'ready_to_sell'
          and catalog._product_readiness_is_ready(
            f.has_base_unit, f.has_images, f.has_stock, f.has_base_price,
            f.has_price_band, f.has_required_custom_fields, f.stock_mode, f.base_price_mode
          )
        )
        or (
          p_readiness_filter = 'incomplete'
          and not catalog._product_readiness_is_ready(
            f.has_base_unit, f.has_images, f.has_stock, f.has_base_price,
            f.has_price_band, f.has_required_custom_fields, f.stock_mode, f.base_price_mode
          )
        )
      )
  ),
  ranked as (
    select
      c.id,
      c.name,
      c.trade_name,
      c.sku,
      c.barcode,
      c.search_document,
      c.business_status,
      c.is_soft_deleted,
      c.updated_at,
      c.has_base_unit,
      c.has_images,
      c.has_stock,
      c.has_base_price,
      c.has_price_band,
      c.has_required_custom_fields,
      c.stock_mode,
      c.base_price_mode,
      case
        when v_keyword is not null
          and v_sort_order = 'relevance_desc'
          and v_tsquery is not null
        then ts_rank_cd(c.search_document, v_tsquery, 32)
        else null
      end as relevance_rank
    from readiness_candidates c
    where p_readiness_filter is not null

    union all

    select
      m.id,
      m.name,
      m.trade_name,
      m.sku,
      m.barcode,
      m.search_document,
      m.business_status,
      m.is_soft_deleted,
      m.updated_at,
      null::boolean as has_base_unit,
      null::boolean as has_images,
      null::boolean as has_stock,
      null::boolean as has_base_price,
      null::boolean as has_price_band,
      null::boolean as has_required_custom_fields,
      null::text as stock_mode,
      null::text as base_price_mode,
      case
        when v_keyword is not null
          and v_sort_order = 'relevance_desc'
          and v_tsquery is not null
        then ts_rank_cd(m.search_document, v_tsquery, 32)
        else null
      end as relevance_rank
    from matched m
    where p_readiness_filter is null
  ),
  counted as (
    select count(*)::bigint as total_count from ranked
  ),
  page as (
    select r.*
    from ranked r
    order by
      case when r.business_status = 'active' then 0 else 1 end,
      r.relevance_rank desc nulls last,
      r.updated_at desc,
      r.name asc
    limit greatest(p_limit, 0)
    offset greatest(p_offset, 0)
  )
  -- Phase B: enrich page rows only.
  select
    pg.id as product_id,
    pg.name,
    pg.trade_name,
    pg.sku,
    pg.barcode,
    (
      select coalesce(i.file_url, i.storage_key)
      from catalog.product_images i
      where i.product_id = pg.id
        and i.tenant_id = p_tenant_id
      order by i.is_primary desc, i.sort_order asc, i.created_at asc
      limit 1
    ) as primary_image_url,
    pg.business_status,
    pg.is_soft_deleted,
    (
      select u.unit_name
      from catalog.product_units u
      where u.product_id = pg.id
        and u.tenant_id = p_tenant_id
        and u.is_base_unit = true
      limit 1
    ) as base_unit_name,
    (
      select sp.basic_stock_quantity_base
      from catalog.product_stock_profiles sp
      where sp.product_id = pg.id
        and sp.tenant_id = p_tenant_id
      limit 1
    ) as stock_qty,
    (
      select pb.list_price_before_vat
      from catalog.product_unit_price_bands pb
      join catalog.product_units bu
        on bu.id = pb.product_unit_id
       and bu.product_id = pg.id
       and bu.is_base_unit = true
      where pb.product_id = pg.id
        and pb.tenant_id = p_tenant_id
        and pb.status = 'active'
        and pb.effective_from <= now()
        and (pb.effective_to is null or pb.effective_to > now())
      limit 1
    ) as list_price,
    (
      select pb.floor_price_before_vat
      from catalog.product_unit_price_bands pb
      join catalog.product_units bu
        on bu.id = pb.product_unit_id
       and bu.product_id = pg.id
       and bu.is_base_unit = true
      where pb.product_id = pg.id
        and pb.tenant_id = p_tenant_id
        and pb.status = 'active'
        and pb.effective_from <= now()
        and (pb.effective_to is null or pb.effective_to > now())
      limit 1
    ) as floor_price,
    pg.updated_at,
    coalesce(pg.has_base_unit, f.has_base_unit) as has_base_unit,
    coalesce(pg.has_images, f.has_images) as has_images,
    coalesce(pg.has_stock, f.has_stock) as has_stock,
    coalesce(pg.has_base_price, f.has_base_price) as has_base_price,
    coalesce(pg.has_price_band, f.has_price_band) as has_price_band,
    coalesce(pg.has_required_custom_fields, f.has_required_custom_fields)
      as has_required_custom_fields,
    coalesce(pg.stock_mode, f.stock_mode) as stock_mode,
    coalesce(pg.base_price_mode, f.base_price_mode) as base_price_mode,
    catalog._product_custom_field_list_values_json(p_tenant_id, pg.id) as custom_field_values,
    c.total_count
  from page pg
  cross join counted c
  cross join lateral catalog._product_operational_facts(p_tenant_id, pg.id) f
  order by
    case when pg.business_status = 'active' then 0 else 1 end,
    pg.relevance_rank desc nulls last,
    pg.updated_at desc,
    pg.name asc;
end;
$$;

revoke all on function catalog.search_products(
  uuid, text, text[], text, boolean, int, int, jsonb, text
) from public;
grant execute on function catalog.search_products(
  uuid, text, text[], text, boolean, int, int, jsonb, text
) to authenticated;
