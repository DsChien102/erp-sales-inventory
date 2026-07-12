-- Title: catalog rename basic_stock_quantity_base + integer stock constraint
-- Kind: patch
-- Intent: catalog_rename_basic_stock_quantity_base
-- Context: TH-02 / EPIC-05 — rename initial_stock → basic_stock_quantity_base; Foundation stock qty = non-negative integer
-- Touches: set_basic_stock_quantity_base, adjust_basic_stock, create_guided_product, _product_change_history_category, get_product_control_center, search_products, find_product_by_barcode, _product_business_status_warnings, _product_deletion_issues
-- Safety: idempotent ; medium — DROP create_guided_product before recreate (param rename); DROP set_initial_stock
-- Depends on: 20260709006_catalog_basic_stock.sql, 20260712001_catalog_fix_create_guided_product_readiness.sql, 20260712002_catalog_product_fts_search.sql

-- ============================================================
-- 1. Rename column + enforce integer constraint (keep numeric)
-- ============================================================

alter table catalog.product_stock_profiles
  rename column initial_stock to basic_stock_quantity_base;

alter table catalog.product_stock_profiles
  drop constraint if exists product_stock_profiles_initial_stock_check;

alter table catalog.product_stock_profiles
  drop constraint if exists chk_basic_stock_quantity_base_non_negative;

alter table catalog.product_stock_profiles
  add constraint chk_basic_stock_quantity_base_non_negative
  check (
    basic_stock_quantity_base is null
    or (
      basic_stock_quantity_base >= 0
      and basic_stock_quantity_base = trunc(basic_stock_quantity_base)
    )
  );

-- Optional: movements integer defense (same rule)
alter table catalog.product_stock_movements
  drop constraint if exists chk_product_stock_movements_quantities_integer;

alter table catalog.product_stock_movements
  add constraint chk_product_stock_movements_quantities_integer
  check (
    quantity_before = trunc(quantity_before)
    and quantity_after = trunc(quantity_after)
    and delta = trunc(delta)
    and quantity_before >= 0
    and quantity_after >= 0
  );

-- ============================================================
-- 2. New RPC: catalog.set_basic_stock_quantity_base
-- ============================================================

create or replace function catalog.set_basic_stock_quantity_base(
  p_tenant_id uuid,
  p_product_id uuid,
  p_mode text,
  p_basic_stock_quantity_base numeric
)
returns void
language plpgsql
security definer
as $$
declare
  v_previous_stock numeric;
  v_stock_version  int;
begin
  if p_mode <> 'basic' then
    raise exception 'not_basic_stock_mode';
  end if;

  if p_basic_stock_quantity_base is null
     or p_basic_stock_quantity_base < 0
     or p_basic_stock_quantity_base <> trunc(p_basic_stock_quantity_base) then
    raise exception 'invalid_stock_quantity';
  end if;

  select sp.basic_stock_quantity_base, sp.stock_version
    into v_previous_stock, v_stock_version
    from catalog.product_stock_profiles sp
   where sp.product_id = p_product_id
   limit 1;

  insert into catalog.product_stock_profiles (
    tenant_id,
    product_id,
    mode,
    basic_stock_quantity_base,
    stock_version
  ) values (
    p_tenant_id,
    p_product_id,
    p_mode,
    p_basic_stock_quantity_base,
    1
  )
  on conflict (product_id) do update
    set basic_stock_quantity_base = excluded.basic_stock_quantity_base,
        stock_version = catalog.product_stock_profiles.stock_version + 1,
        mode = excluded.mode;

  insert into catalog.product_stock_movements (
    tenant_id,
    product_id,
    movement_type,
    quantity_before,
    quantity_after,
    delta,
    actor_id
  ) values (
    p_tenant_id,
    p_product_id,
    'initial',
    coalesce(v_previous_stock, 0),
    p_basic_stock_quantity_base,
    p_basic_stock_quantity_base - coalesce(v_previous_stock, 0),
    p_tenant_id
  );

  insert into catalog.product_change_history (tenant_id, product_id, action, payload, actor_id)
  values (
    p_tenant_id,
    p_product_id,
    'set_basic_stock_quantity_base',
    jsonb_build_object('mode', p_mode, 'basic_stock_quantity_base', p_basic_stock_quantity_base),
    p_tenant_id
  );
end;
$$;

-- ============================================================
-- 3. Drop legacy RPC
-- ============================================================

drop function if exists catalog.set_initial_stock(uuid, uuid, text, numeric);

-- ============================================================
-- 4. Patch catalog.adjust_basic_stock — use new column name
-- ============================================================

create or replace function catalog.adjust_basic_stock(
  p_tenant_id        uuid,
  p_product_id       uuid,
  p_new_quantity     numeric,
  p_reason           text    default null,
  p_expected_quantity numeric  default null
)
returns jsonb
language plpgsql
security definer
as $$
declare
  v_profile catalog.product_stock_profiles%rowtype;
begin
  select * into v_profile
    from catalog.product_stock_profiles sp
   where sp.product_id = p_product_id
     and sp.tenant_id  = p_tenant_id
   limit 1;

  if not found then
    raise exception 'product_not_found';
  end if;

  if v_profile.mode = 'advanced' then
    raise exception 'not_basic_stock_mode';
  end if;

  if p_new_quantity is null
     or p_new_quantity < 0
     or p_new_quantity <> trunc(p_new_quantity) then
    raise exception 'invalid_stock_quantity';
  end if;

  if p_expected_quantity is not null
     and (
       p_expected_quantity <> trunc(p_expected_quantity)
       or p_expected_quantity <> v_profile.basic_stock_quantity_base
     ) then
    raise exception 'stale_stock_quantity';
  end if;

  update catalog.product_stock_profiles
     set basic_stock_quantity_base = p_new_quantity,
         stock_version = stock_version + 1
   where product_id = p_product_id
     and tenant_id  = p_tenant_id;

  insert into catalog.product_stock_movements (
    tenant_id,
    product_id,
    movement_type,
    quantity_before,
    quantity_after,
    delta,
    reason,
    actor_id
  ) values (
    p_tenant_id,
    p_product_id,
    'adjust',
    v_profile.basic_stock_quantity_base,
    p_new_quantity,
    p_new_quantity - v_profile.basic_stock_quantity_base,
    p_reason,
    p_tenant_id
  );

  insert into catalog.product_change_history (tenant_id, product_id, action, payload, actor_id)
  values (
    p_tenant_id,
    p_product_id,
    'adjust_basic_stock',
    jsonb_build_object(
      'quantity_before', v_profile.basic_stock_quantity_base,
      'quantity_after',  p_new_quantity,
      'reason',          p_reason
    ),
    p_tenant_id
  );

  return jsonb_build_object(
    'previous_quantity', v_profile.basic_stock_quantity_base,
    'new_quantity',      p_new_quantity
  );
end;
$$;

-- ============================================================
-- 5. Patch catalog.create_guided_product
-- ============================================================

-- Parameter rename p_initial_stock → p_basic_stock_quantity_base requires DROP first
-- (CREATE OR REPLACE cannot rename input parameters).
drop function if exists catalog.create_guided_product(
  uuid, uuid, text, text, text, text, text, jsonb, uuid, text,
  numeric, numeric, numeric, numeric, boolean, jsonb, uuid
);

create or replace function catalog.create_guided_product(
  p_tenant_id uuid,
  p_actor_id uuid,
  p_name text,
  p_reference_id text,
  p_trade_name text default null,
  p_sku text default null,
  p_barcode text default null,
  p_images jsonb default '[]'::jsonb,
  p_tenant_unit_id uuid default null,
  p_new_unit_name text default null,
  p_basic_stock_quantity_base numeric default null,
  p_base_price numeric default null,
  p_list_price numeric default null,
  p_floor_price numeric default null,
  p_use_store_price_rule boolean default false,
  p_custom_field_values jsonb default '[]'::jsonb,
  p_idempotency_key uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = catalog, iam, pg_temp
as $$
declare
  v_product_id uuid;
  v_existing boolean := false;
  v_readiness_status text;
  v_readiness_blockers jsonb;
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;
  if p_actor_id is null or p_actor_id <> auth.uid() then
    raise exception 'actor mismatch';
  end if;
  if not iam.has_permission(p_tenant_id, 'catalog.product.create') then
    raise exception 'permission denied: catalog.product.create';
  end if;

  if p_idempotency_key is not null then
    select p.id into v_product_id
    from catalog.products p
    where p.tenant_id = p_tenant_id
      and p.idempotency_key = p_idempotency_key;
    v_existing := found;
  end if;
  if v_existing then
    select r.readiness_status, r.readiness_blockers
    into v_readiness_status, v_readiness_blockers
    from catalog._refresh_product_readiness(p_tenant_id, v_product_id) r;

    return jsonb_build_object(
      'product_id', v_product_id,
      'readiness_status', v_readiness_status,
      'readiness_blockers', coalesce(v_readiness_blockers, '[]'::jsonb)
    );
  end if;

  if (p_tenant_unit_id is not null or nullif(btrim(coalesce(p_new_unit_name, '')), '') is not null)
     and not iam.has_permission(p_tenant_id, 'catalog.product.manage_units') then
    raise exception 'permission denied: catalog.product.manage_units';
  end if;
  if p_basic_stock_quantity_base is not null
     and not iam.has_permission(p_tenant_id, 'catalog.product.manage_stock') then
    raise exception 'permission denied: catalog.product.manage_stock';
  end if;
  if (p_base_price is not null or p_list_price is not null or p_floor_price is not null or p_use_store_price_rule)
     and not iam.has_permission(p_tenant_id, 'catalog.product.manage_pricing') then
    raise exception 'permission denied: catalog.product.manage_pricing';
  end if;
  if jsonb_array_length(coalesce(p_custom_field_values, '[]'::jsonb)) > 0
     and not iam.has_permission(p_tenant_id, 'catalog.product.update') then
    raise exception 'permission denied: catalog.product.update';
  end if;

  if p_basic_stock_quantity_base is not null
     and (p_basic_stock_quantity_base < 0 or p_basic_stock_quantity_base <> trunc(p_basic_stock_quantity_base)) then
    raise exception 'validation_exception: initial stock must be a non-negative integer';
  end if;
  if (p_basic_stock_quantity_base is not null or p_base_price is not null or p_list_price is not null
      or p_floor_price is not null or p_use_store_price_rule)
     and p_tenant_unit_id is null
     and nullif(btrim(coalesce(p_new_unit_name, '')), '') is null then
    raise exception 'validation_exception: base unit is required for stock or pricing';
  end if;
  if p_base_price < 0 or p_list_price < 0 or p_floor_price < 0 then
    raise exception 'validation_exception: prices cannot be negative';
  end if;
  if p_floor_price is not null and p_list_price is not null and p_floor_price > p_list_price then
    raise exception 'floor_price_greater_than_list_price';
  end if;

  v_product_id := catalog.create_product(
    p_tenant_id => p_tenant_id,
    p_name => p_name,
    p_reference_id => p_reference_id,
    p_actor_id => p_actor_id,
    p_trade_name => p_trade_name,
    p_sku => p_sku,
    p_barcode => p_barcode,
    p_images => p_images,
    p_idempotency_key => p_idempotency_key
  );

  if p_tenant_unit_id is not null or nullif(btrim(coalesce(p_new_unit_name, '')), '') is not null then
    perform catalog.set_product_base_unit(
      p_tenant_id, v_product_id, p_tenant_unit_id, p_new_unit_name
    );
  end if;
  if p_basic_stock_quantity_base is not null then
    perform catalog.set_basic_stock_quantity_base(p_tenant_id, v_product_id, 'basic', p_basic_stock_quantity_base);
  end if;
  if p_base_price is not null then
    perform catalog.set_manual_base_price(p_tenant_id, v_product_id, 'manual', p_base_price, 'VND');
  end if;
  if p_use_store_price_rule then
    perform 1 from catalog.apply_store_price_rule(p_tenant_id, v_product_id);
  elsif p_list_price is not null or p_floor_price is not null then
    perform catalog.set_initial_price_band(
      p_tenant_id, v_product_id, p_list_price, p_floor_price, null
    );
  end if;
  if jsonb_array_length(coalesce(p_custom_field_values, '[]'::jsonb)) > 0 then
    perform catalog.upsert_product_custom_field_values(
      p_tenant_id, v_product_id, p_custom_field_values
    );
  end if;

  select r.readiness_status, r.readiness_blockers
  into v_readiness_status, v_readiness_blockers
  from catalog._refresh_product_readiness(p_tenant_id, v_product_id) r;

  return jsonb_build_object(
    'product_id', v_product_id,
    'readiness_status', v_readiness_status,
    'readiness_blockers', coalesce(v_readiness_blockers, '[]'::jsonb)
  );
end;
$$;

-- ============================================================
-- 6. Patch _product_change_history_category — add new action
-- ============================================================

create or replace function catalog._product_change_history_category(p_action text)
returns text
language sql
immutable
as $$
  select case p_action
    when 'product_created'           then 'profile'
    when 'update_product_profile'    then 'profile'
    when 'product_profile_updated'   then 'profile'
    when 'update_product_images'     then 'images'
    when 'product_images_updated'    then 'images'
    when 'add_product_unit'          then 'units'
    when 'deactivate_product_unit'   then 'units'
    when 'reactivate_product_unit'   then 'units'
    when 'set_product_base_unit'     then 'units'
    when 'set_basic_stock_quantity_base' then 'stock'
    when 'set_initial_stock'         then 'stock'
    when 'adjust_basic_stock'        then 'stock'
    when 'set_manual_base_price'     then 'pricing'
    when 'apply_store_price_rule'    then 'pricing'
    when 'set_product_unit_price_band'  then 'pricing'
    when 'set_initial_price_band'    then 'pricing'
    when 'upsert_custom_field_values'   then 'custom_fields'
    when 'custom_field_values_updated'  then 'custom_fields'
    when 'product_status_changed'    then 'status'
    when 'deactivate_product'        then 'status'
    when 'reactivate_product'        then 'status'
    when 'product_soft_deleted'      then 'lifecycle'
    when 'product_restored'          then 'lifecycle'
    else null
  end
$$;

-- ============================================================
-- 7. Patch read projections / helpers using renamed stock column
-- ============================================================

create or replace function catalog.get_product_control_center(
  p_tenant_id uuid,
  p_product_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = catalog, iam, pg_temp
as $$
declare
  v_result jsonb;
begin
  perform catalog._assert_product_permission(p_tenant_id, 'catalog.product.view_detail');

  select jsonb_build_object(
    'product_id', p.id,
    'name', p.name,
    'trade_name', p.trade_name,
    'sku', p.sku,
    'barcode', p.barcode,
    'description', p.description,
    'note', p.note,
    'business_status', p.business_status::text,
    'is_soft_deleted', (p.deleted_at is not null),
    'primary_image_url', (
      select coalesce(i.file_url, i.storage_key)
      from catalog.product_images i
      where i.product_id = p.id and i.tenant_id = p_tenant_id
      order by i.is_primary desc, i.sort_order asc
      limit 1
    ),
    'images', coalesce((
      select jsonb_agg(coalesce(i.file_url, i.storage_key) order by i.is_primary desc, i.sort_order asc)
      from catalog.product_images i
      where i.product_id = p.id and i.tenant_id = p_tenant_id
    ), '[]'::jsonb),
    'base_unit_name', (
      select u.unit_name
      from catalog.product_units u
      where u.product_id = p.id and u.is_base_unit = true
      limit 1
    ),
    'conversion_units', coalesce((
      select jsonb_agg(jsonb_build_object(
        'name', u.unit_name,
        'conversion_rate', u.conversion_rate_to_base,
        'is_active', true
      ) order by u.created_at)
      from catalog.product_units u
      where u.product_id = p.id
        and u.tenant_id = p_tenant_id
        and u.is_base_unit = false
    ), '[]'::jsonb),
    'stock_mode', f.stock_mode,
    'stock_qty', (
      select sp.basic_stock_quantity_base
      from catalog.product_stock_profiles sp
      where sp.product_id = p.id
      limit 1
    ),
    'stock_version', (
      select sp.stock_version
      from catalog.product_stock_profiles sp
      where sp.product_id = p.id
      limit 1
    ),
    'base_price_mode', f.base_price_mode,
    'base_price_amount', (
      select bp.base_price_amount
      from catalog.product_base_price_profiles bp
      where bp.product_id = p.id
      limit 1
    ),
    'base_price_currency', coalesce((
      select bp.currency
      from catalog.product_base_price_profiles bp
      where bp.product_id = p.id
      limit 1
    ), 'VND'),
    'list_price', (
      select pb.list_price_amount
      from catalog.product_unit_price_bands pb
      join catalog.product_units bu on bu.id = pb.product_unit_id and bu.is_base_unit = true
      where pb.product_id = p.id
      limit 1
    ),
    'floor_price', (
      select pb.floor_price_amount
      from catalog.product_unit_price_bands pb
      join catalog.product_units bu on bu.id = pb.product_unit_id and bu.is_base_unit = true
      where pb.product_id = p.id
      limit 1
    ),
    'price_band_source_type', (
      select pb.source_type
      from catalog.product_unit_price_bands pb
      join catalog.product_units bu on bu.id = pb.product_unit_id and bu.is_base_unit = true
      where pb.product_id = p.id
      limit 1
    ),
    'store_price_rule_name', (
      select sr.name
      from catalog.product_unit_price_bands pb
      join catalog.product_units bu on bu.id = pb.product_unit_id and bu.is_base_unit = true
      left join catalog.store_price_rules sr on sr.id = pb.store_price_rule_id
      where pb.product_id = p.id
      limit 1
    ),
    'is_custom_override', coalesce((
      select pb.is_custom_override
      from catalog.product_unit_price_bands pb
      join catalog.product_units bu on bu.id = pb.product_unit_id and bu.is_base_unit = true
      where pb.product_id = p.id
      limit 1
    ), false),
    'has_base_unit', f.has_base_unit,
    'has_images', f.has_images,
    'has_stock', f.has_stock,
    'has_base_price', f.has_base_price,
    'has_price_band', f.has_price_band,
    'has_required_custom_fields', f.has_required_custom_fields,
    'custom_field_group_cards',
      catalog._product_custom_field_group_cards_json(p_tenant_id, p.id),
    'change_history_preview', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', h.id,
        'occurred_at', h.created_at,
        'actor_display_name', left(h.actor_id::text, 8),
        'change_type', h.action,
        'summary', h.action,
        'value_before', h.payload ->> 'value_before',
        'value_after', h.payload ->> 'value_after'
      ) order by h.created_at desc)
      from (
        select *
        from catalog.product_change_history h
        where h.product_id = p.id and h.tenant_id = p_tenant_id
        order by h.created_at desc
        limit 3
      ) h
    ), '[]'::jsonb)
  )
  into v_result
  from catalog.products p
  cross join lateral catalog._product_operational_facts(p_tenant_id, p.id) f
  where p.tenant_id = p_tenant_id
    and p.id = p_product_id
    and p.deleted_at is null;

  if v_result is null then
    raise exception 'product not found';
  end if;

  return v_result;
end;
$$;

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
  v_keyword_normalized text;
  v_keyword_unaccented text;
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
  v_keyword_normalized := nullif(lower(v_keyword), '');
  v_keyword_unaccented := nullif(
    btrim(catalog.unaccent_immutable(coalesce(v_keyword, ''))),
    ''
  );
  if v_keyword_unaccented is null then
    v_tsquery := null;
  else
    v_tsquery := websearch_to_tsquery('simple', v_keyword_unaccented);
    -- Empty / no-token query → no FTS clause (keep sku/barcode fast-path).
    if numnode(v_tsquery) = 0 then
      v_tsquery := null;
    end if;
  end if;

  v_sort_order := case
    when p_sort_order = 'relevance_desc' then 'relevance_desc'
    else 'updated_at_desc'
  end;

  return query
  with filtered as (
    select
      p.id,
      p.name,
      p.trade_name,
      p.sku,
      p.barcode,
      p.search_document,
      (
        select coalesce(i.file_url, i.storage_key)
        from catalog.product_images i
        where i.product_id = p.id
          and i.tenant_id = p_tenant_id
        order by i.is_primary desc, i.sort_order asc, i.created_at asc
        limit 1
      ) as primary_image_url,
      p.business_status::text as business_status,
      (p.deleted_at is not null) as is_soft_deleted,
      (
        select u.unit_name
        from catalog.product_units u
        where u.product_id = p.id
          and u.tenant_id = p_tenant_id
          and u.is_base_unit = true
        limit 1
      ) as base_unit_name,
      (
        select sp.basic_stock_quantity_base
        from catalog.product_stock_profiles sp
        where sp.product_id = p.id
          and sp.tenant_id = p_tenant_id
        limit 1
      ) as stock_qty,
      (
        select pb.list_price_amount
        from catalog.product_unit_price_bands pb
        join catalog.product_units bu
          on bu.id = pb.product_unit_id
         and bu.product_id = p.id
         and bu.is_base_unit = true
        where pb.product_id = p.id
          and pb.tenant_id = p_tenant_id
        limit 1
      ) as list_price,
      (
        select pb.floor_price_amount
        from catalog.product_unit_price_bands pb
        join catalog.product_units bu
          on bu.id = pb.product_unit_id
         and bu.product_id = p.id
         and bu.is_base_unit = true
        where pb.product_id = p.id
          and pb.tenant_id = p_tenant_id
        limit 1
      ) as floor_price,
      p.updated_at,
      f.has_base_unit,
      f.has_images,
      f.has_stock,
      f.has_base_price,
      f.has_price_band,
      f.has_required_custom_fields,
      f.stock_mode,
      f.base_price_mode
    from catalog.products p
    cross join lateral catalog._product_operational_facts(p_tenant_id, p.id) f
    where p.tenant_id = p_tenant_id
      and (p_include_soft_deleted or p.deleted_at is null)
      and p.business_status::text = any (p_business_statuses)
      and (
        v_keyword is null
        or (v_tsquery is not null and p.search_document @@ v_tsquery)
        or (v_keyword_normalized is not null and p.sku = v_keyword_normalized)
        or (v_keyword is not null and p.barcode = btrim(v_keyword))
        or (
          v_keyword_normalized is not null
          and length(v_keyword_normalized) >= 2
          and p.sku like v_keyword_normalized || '%'
        )
      )
      and catalog._product_matches_custom_field_filters(
        p_tenant_id,
        p.id,
        coalesce(p_custom_field_filters, '[]'::jsonb)
      )
  ),
  readiness_filtered as (
    select *
    from filtered f
    where p_readiness_filter is null
      or (
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
  ),
  counted as (
    select count(*)::bigint as total_count from readiness_filtered
  )
  select
    rf.id as product_id,
    rf.name,
    rf.trade_name,
    rf.sku,
    rf.barcode,
    rf.primary_image_url,
    rf.business_status,
    rf.is_soft_deleted,
    rf.base_unit_name,
    rf.stock_qty,
    rf.list_price,
    rf.floor_price,
    rf.updated_at,
    rf.has_base_unit,
    rf.has_images,
    rf.has_stock,
    rf.has_base_price,
    rf.has_price_band,
    rf.has_required_custom_fields,
    rf.stock_mode,
    rf.base_price_mode,
    catalog._product_custom_field_list_values_json(p_tenant_id, rf.id) as custom_field_values,
    c.total_count
  from readiness_filtered rf
  cross join counted c
  order by
    case when rf.business_status = 'active' then 0 else 1 end,
    case
      when v_keyword is not null
        and v_sort_order = 'relevance_desc'
        and v_tsquery is not null
      then ts_rank_cd(rf.search_document, v_tsquery, 32)
      else null
    end desc nulls last,
    rf.updated_at desc,
    rf.name asc
  limit greatest(p_limit, 0)
  offset greatest(p_offset, 0);
end;
$$;

create or replace function catalog.find_product_by_barcode(
  p_tenant_id uuid,
  p_barcode text
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
  base_price_mode text
)
language plpgsql
security definer
set search_path = catalog, iam, pg_temp
as $$
declare
  v_barcode text;
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  if not iam.has_permission(p_tenant_id, 'catalog.product.view') then
    raise exception 'permission denied: catalog.product.view';
  end if;

  v_barcode := catalog._normalize_product_barcode(p_barcode);
  if v_barcode is null then
    return;
  end if;

  return query
  select
    p.id as product_id,
    p.name,
    p.trade_name,
    p.sku,
    p.barcode,
    (
      select coalesce(i.file_url, i.storage_key)
      from catalog.product_images i
      where i.product_id = p.id
        and i.tenant_id = p_tenant_id
      order by i.is_primary desc, i.sort_order asc
      limit 1
    ) as primary_image_url,
    p.business_status::text as business_status,
    false as is_soft_deleted,
    (
      select u.unit_name
      from catalog.product_units u
      where u.product_id = p.id
        and u.tenant_id = p_tenant_id
        and u.is_base_unit = true
      limit 1
    ) as base_unit_name,
    (
      select sp.basic_stock_quantity_base
      from catalog.product_stock_profiles sp
      where sp.product_id = p.id
        and sp.tenant_id = p_tenant_id
      limit 1
    ) as stock_qty,
    (
      select pb.list_price_amount
      from catalog.product_unit_price_bands pb
      join catalog.product_units bu
        on bu.id = pb.product_unit_id
       and bu.product_id = p.id
       and bu.is_base_unit = true
      where pb.product_id = p.id
        and pb.tenant_id = p_tenant_id
      limit 1
    ) as list_price,
    (
      select pb.floor_price_amount
      from catalog.product_unit_price_bands pb
      join catalog.product_units bu
        on bu.id = pb.product_unit_id
       and bu.product_id = p.id
       and bu.is_base_unit = true
      where pb.product_id = p.id
        and pb.tenant_id = p_tenant_id
      limit 1
    ) as floor_price,
    p.updated_at,
    f.has_base_unit,
    f.has_images,
    f.has_stock,
    f.has_base_price,
    f.has_price_band,
    f.has_required_custom_fields,
    f.stock_mode,
    f.base_price_mode
  from catalog.products p
  cross join lateral catalog._product_operational_facts(p_tenant_id, p.id) f
  where p.tenant_id = p_tenant_id
    and p.deleted_at is null
    and p.barcode = v_barcode
  limit 1;
end;
$$;

create or replace function catalog._product_business_status_warnings(
  p_tenant_id uuid,
  p_product_id uuid
)
returns jsonb
language sql
stable
security definer
set search_path = catalog, pg_temp
as $$
  select coalesce(jsonb_agg(warning), '[]'::jsonb)
  from (
    select jsonb_build_object(
      'code', 'has_stock',
      'message', 'Sản phẩm vẫn còn tồn kho hiện hành.'
    ) as warning
    where exists (
      select 1
      from catalog.product_stock_profiles sp
      where sp.tenant_id = p_tenant_id
        and sp.product_id = p_product_id
        and coalesce(sp.basic_stock_quantity_base, 0) > 0
    )
  ) warnings;
$$;

create or replace function catalog._product_deletion_issues(
  p_tenant_id uuid,
  p_product_id uuid
)
returns jsonb
language sql
stable
security definer
set search_path = catalog, pg_temp
as $$
  select coalesce(jsonb_agg(issue), '[]'::jsonb)
  from (
    -- Foundation MVP: live Sales/Purchase/Promotions contracts are not available yet.
    -- Keep cross-module dependency checks false until their read contracts exist.
    select jsonb_build_object(
      'code', 'has_stock',
      'message', 'Sản phẩm vẫn còn tồn kho hiện hành.',
      'severity', 'warning'
    ) as issue
    where exists (
      select 1
      from catalog.product_stock_profiles sp
      where sp.tenant_id = p_tenant_id
        and sp.product_id = p_product_id
        and coalesce(sp.basic_stock_quantity_base, 0) > 0
    )
  ) issues;
$$;

-- ============================================================
-- 8. Permissions
-- ============================================================

revoke all on function catalog.set_basic_stock_quantity_base(uuid, uuid, text, numeric) from public;
grant execute on function catalog.set_basic_stock_quantity_base(uuid, uuid, text, numeric)
  to authenticated;

revoke all on function catalog.adjust_basic_stock(uuid, uuid, numeric, text, numeric) from public;
grant execute on function catalog.adjust_basic_stock(uuid, uuid, numeric, text, numeric)
  to authenticated;

revoke all on function catalog._product_change_history_category(text) from public;
grant execute on function catalog._product_change_history_category(text)
  to authenticated;

revoke all on function catalog.create_guided_product(
  uuid, uuid, text, text, text, text, text, jsonb, uuid, text,
  numeric, numeric, numeric, numeric, boolean, jsonb, uuid
) from public, anon;
grant execute on function catalog.create_guided_product(
  uuid, uuid, text, text, text, text, text, jsonb, uuid, text,
  numeric, numeric, numeric, numeric, boolean, jsonb, uuid
) to authenticated, service_role;

-- get_product_control_center / search_products / find_product_by_barcode
-- keep existing grants (CREATE OR REPLACE without signature change).
