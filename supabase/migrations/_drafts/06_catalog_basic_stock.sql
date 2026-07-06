-- Catalog basic stock (EPIC-05/US-01 + US-02): movements, adjust, history, stock_version.
-- Context: TH-02/EPIC-05 slice #8 BE; docs/themes/TH-02-product-pricing/harness/*
-- Depends on: 02_catalog_operational_data.sql, 05_catalog_units.sql
-- Safety: idempotent draft only; do not promote without a unique timestamp migration review.

alter table catalog.product_stock_profiles
  add column if not exists stock_version int not null default 1;

create table if not exists catalog.product_stock_movements (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  product_id uuid not null references catalog.products (id) on delete cascade,
  movement_type text not null
    check (movement_type in ('initial', 'adjust')),
  quantity_before numeric not null,
  quantity_after numeric not null,
  delta numeric not null,
  reason text,
  actor_id uuid not null,
  occurred_at timestamptz not null default now()
);

create index if not exists idx_product_stock_movements_product_occurred
  on catalog.product_stock_movements (product_id, occurred_at desc);

create index if not exists idx_product_stock_movements_tenant_id
  on catalog.product_stock_movements (tenant_id);

create or replace function catalog._product_base_unit_name(
  p_tenant_id uuid,
  p_product_id uuid
)
returns text
language sql
stable
security definer
set search_path = catalog, pg_temp
as $$
  select pu.unit_name
  from catalog.product_units pu
  where pu.product_id = p_product_id
    and pu.tenant_id = p_tenant_id
    and pu.is_base_unit = true
    and pu.is_active = true
  limit 1;
$$;

create or replace function catalog.set_initial_stock(
  p_tenant_id uuid,
  p_product_id uuid,
  p_mode text,
  p_initial_stock numeric
)
returns void
language plpgsql
security definer
set search_path = catalog, iam, pg_temp
as $$
declare
  v_actor_id uuid;
  v_previous_stock numeric := 0;
  v_stock_version int := 1;
begin
  v_actor_id := auth.uid();
  if v_actor_id is null then
    raise exception 'not authenticated';
  end if;

  if not iam.has_permission(p_tenant_id, 'catalog.product.manage_stock') then
    raise exception 'permission denied: catalog.product.manage_stock';
  end if;

  if not exists (
    select 1
    from catalog.products
    where id = p_product_id
      and tenant_id = p_tenant_id
  ) then
    raise exception 'product not found';
  end if;

  perform catalog._ensure_product_has_base_unit(p_tenant_id, p_product_id);

  if p_mode <> 'basic' then
    raise exception 'not_basic_stock_mode';
  end if;

  if p_initial_stock < 0 then
    raise exception 'validation_exception: initial stock cannot be negative';
  end if;

  select sp.initial_stock, sp.stock_version
  into v_previous_stock, v_stock_version
  from catalog.product_stock_profiles sp
  where sp.product_id = p_product_id
    and sp.tenant_id = p_tenant_id;

  if not found then
    v_previous_stock := 0;
    v_stock_version := 0;
  end if;

  insert into catalog.product_stock_profiles (
    product_id,
    tenant_id,
    mode,
    initial_stock,
    stock_version,
    updated_at
  )
  values (
    p_product_id,
    p_tenant_id,
    p_mode,
    p_initial_stock,
    v_stock_version + 1,
    now()
  )
  on conflict (product_id) do update set
    mode = excluded.mode,
    initial_stock = excluded.initial_stock,
    stock_version = catalog.product_stock_profiles.stock_version + 1,
    updated_at = now();

  insert into catalog.product_stock_movements (
    tenant_id,
    product_id,
    movement_type,
    quantity_before,
    quantity_after,
    delta,
    reason,
    actor_id
  )
  values (
    p_tenant_id,
    p_product_id,
    'initial',
    coalesce(v_previous_stock, 0),
    p_initial_stock,
    p_initial_stock - coalesce(v_previous_stock, 0),
    null,
    v_actor_id
  );

  insert into catalog.product_change_history (tenant_id, product_id, action, payload, actor_id)
  values (
    p_tenant_id,
    p_product_id,
    'set_initial_stock',
    jsonb_build_object('mode', p_mode, 'initial_stock', p_initial_stock),
    v_actor_id
  );
end;
$$;

create or replace function catalog.adjust_basic_stock(
  p_tenant_id uuid,
  p_product_id uuid,
  p_new_quantity numeric,
  p_reason text default null,
  p_expected_quantity numeric default null
)
returns jsonb
language plpgsql
security definer
set search_path = catalog, iam, pg_temp
as $$
declare
  v_actor_id uuid;
  v_profile catalog.product_stock_profiles%rowtype;
  v_unit_name text;
begin
  v_actor_id := auth.uid();
  if v_actor_id is null then
    raise exception 'not authenticated';
  end if;

  if not iam.has_permission(p_tenant_id, 'catalog.product.manage_stock') then
    raise exception 'permission denied: catalog.product.manage_stock';
  end if;

  if not exists (
    select 1
    from catalog.products
    where id = p_product_id
      and tenant_id = p_tenant_id
  ) then
    raise exception 'product not found';
  end if;

  perform catalog._ensure_product_has_base_unit(p_tenant_id, p_product_id);

  select *
  into v_profile
  from catalog.product_stock_profiles sp
  where sp.product_id = p_product_id
    and sp.tenant_id = p_tenant_id;

  if not found then
    raise exception 'not_basic_stock_mode';
  end if;

  if v_profile.mode <> 'basic' then
    raise exception 'not_basic_stock_mode';
  end if;

  if p_new_quantity < 0 then
    raise exception 'validation_exception: stock quantity cannot be negative';
  end if;

  if p_expected_quantity is not null and p_expected_quantity <> v_profile.initial_stock then
    raise exception 'stale_stock_quantity';
  end if;

  v_unit_name := catalog._product_base_unit_name(p_tenant_id, p_product_id);

  update catalog.product_stock_profiles
  set initial_stock = p_new_quantity,
      stock_version = stock_version + 1,
      updated_at = now()
  where product_id = p_product_id
    and tenant_id = p_tenant_id;

  insert into catalog.product_stock_movements (
    tenant_id,
    product_id,
    movement_type,
    quantity_before,
    quantity_after,
    delta,
    reason,
    actor_id
  )
  values (
    p_tenant_id,
    p_product_id,
    'adjust',
    v_profile.initial_stock,
    p_new_quantity,
    p_new_quantity - v_profile.initial_stock,
    nullif(btrim(coalesce(p_reason, '')), ''),
    v_actor_id
  );

  insert into catalog.product_change_history (tenant_id, product_id, action, payload, actor_id)
  values (
    p_tenant_id,
    p_product_id,
    'adjust_basic_stock',
    jsonb_build_object(
      'quantity_before', v_profile.initial_stock,
      'quantity_after', p_new_quantity,
      'reason', nullif(btrim(coalesce(p_reason, '')), '')
    ),
    v_actor_id
  );

  return jsonb_build_object(
    'previous_quantity', v_profile.initial_stock,
    'new_quantity', p_new_quantity,
    'unit_name', v_unit_name
  );
end;
$$;

create or replace function catalog.get_product_stock_history(
  p_tenant_id uuid,
  p_product_id uuid,
  p_limit int default 50
)
returns table (
  id uuid,
  occurred_at timestamptz,
  actor_display_name text,
  movement_type text,
  quantity_before numeric,
  quantity_after numeric,
  delta numeric,
  reason text
)
language plpgsql
security definer
set search_path = catalog, iam, pg_temp
as $$
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  if not iam.has_permission(p_tenant_id, 'catalog.product.view_history') then
    raise exception 'permission denied: catalog.product.view_history';
  end if;

  if not exists (
    select 1
    from catalog.products
    where id = p_product_id
      and tenant_id = p_tenant_id
  ) then
    raise exception 'product not found';
  end if;

  return query
  select
    m.id,
    m.occurred_at,
    left(m.actor_id::text, 8) as actor_display_name,
    m.movement_type,
    m.quantity_before,
    m.quantity_after,
    m.delta,
    m.reason
  from catalog.product_stock_movements m
  where m.tenant_id = p_tenant_id
    and m.product_id = p_product_id
  order by m.occurred_at desc
  limit greatest(coalesce(p_limit, 50), 1);
end;
$$;

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
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  if not iam.has_permission(p_tenant_id, 'catalog.product.view_detail') then
    raise exception 'permission denied: catalog.product.view_detail';
  end if;

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
      select i.file_url
      from catalog.product_images i
      where i.product_id = p.id and i.tenant_id = p_tenant_id
      order by i.is_primary desc, i.sort_order asc
      limit 1
    ),
    'images', coalesce((
      select jsonb_agg(i.file_url order by i.is_primary desc, i.sort_order asc)
      from catalog.product_images i
      where i.product_id = p.id and i.tenant_id = p_tenant_id and i.file_url is not null
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
      select sp.initial_stock
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
    'has_base_unit', f.has_base_unit,
    'has_images', f.has_images,
    'has_stock', f.has_stock,
    'has_base_price', f.has_base_price,
    'has_price_band', f.has_price_band,
    'has_required_custom_fields', f.has_required_custom_fields,
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

revoke all on function catalog.set_initial_stock(uuid, uuid, text, numeric)
  from public, anon;
grant execute on function catalog.set_initial_stock(uuid, uuid, text, numeric)
  to authenticated, service_role;

revoke all on function catalog.adjust_basic_stock(uuid, uuid, numeric, text, numeric)
  from public, anon;
grant execute on function catalog.adjust_basic_stock(uuid, uuid, numeric, text, numeric)
  to authenticated, service_role;

revoke all on function catalog.get_product_stock_history(uuid, uuid, int)
  from public, anon;
grant execute on function catalog.get_product_stock_history(uuid, uuid, int)
  to authenticated, service_role;

revoke all on function catalog.get_product_control_center(uuid, uuid)
  from public, anon;
grant execute on function catalog.get_product_control_center(uuid, uuid)
  to authenticated, service_role;
