-- Catalog operational data (US-02): initial stock, base price, unit price bands, and readiness update.
-- Context: TH-02/EPIC-02/US-02 BE; docs/themes/TH-02-product-pricing/harness/*
-- Safety: idempotent ; low lock impact on empty/new schema

create table if not exists catalog.product_stock_profiles (
  product_id uuid primary key references catalog.products (id) on delete cascade,
  tenant_id uuid not null,
  mode text not null default 'basic'
    check (mode in ('basic', 'advanced')),
  initial_stock numeric not null default 0
    check (initial_stock >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_product_stock_profiles_tenant_id
  on catalog.product_stock_profiles (tenant_id);

create table if not exists catalog.product_base_price_profiles (
  product_id uuid primary key references catalog.products (id) on delete cascade,
  tenant_id uuid not null,
  mode text not null default 'manual'
    check (mode in ('manual', 'costingModule')),
  base_price_amount numeric null
    check (base_price_amount is null or base_price_amount >= 0),
  currency text not null default 'VND',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_product_base_price_profiles_tenant_id
  on catalog.product_base_price_profiles (tenant_id);

create table if not exists catalog.product_unit_price_bands (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  product_id uuid not null references catalog.products (id) on delete cascade,
  product_unit_id uuid not null references catalog.product_units (id) on delete cascade,
  list_price_amount numeric null
    check (list_price_amount is null or list_price_amount >= 0),
  floor_price_amount numeric null
    check (floor_price_amount is null or floor_price_amount >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_product_unit_price_bands_unit unique (product_id, product_unit_id),
  constraint chk_price_bands_floor_le_list check (
    floor_price_amount is null or list_price_amount is null or floor_price_amount <= list_price_amount
  )
);

create index if not exists idx_product_unit_price_bands_product_id
  on catalog.product_unit_price_bands (product_id);

-- RPC: set_initial_stock
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
begin
  v_actor_id := auth.uid();
  if v_actor_id is null then
    raise exception 'not authenticated';
  end if;

  if not iam.has_permission(p_tenant_id, 'catalog.product.manage_stock') then
    raise exception 'permission denied: catalog.product.manage_stock';
  end if;

  if not exists (select 1 from catalog.products where id = p_product_id and tenant_id = p_tenant_id) then
    raise exception 'product not found';
  end if;

  if p_mode <> 'basic' then
    raise exception 'not_basic_stock_mode';
  end if;

  if p_initial_stock < 0 then
    raise exception 'validation_exception: initial stock cannot be negative';
  end if;

  insert into catalog.product_stock_profiles (product_id, tenant_id, mode, initial_stock, updated_at)
  values (p_product_id, p_tenant_id, p_mode, p_initial_stock, now())
  on conflict (product_id) do update set
    mode = excluded.mode,
    initial_stock = excluded.initial_stock,
    updated_at = now();

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

-- RPC: set_manual_base_price
create or replace function catalog.set_manual_base_price(
  p_tenant_id uuid,
  p_product_id uuid,
  p_mode text,
  p_base_price numeric,
  p_currency text default 'VND'
)
returns void
language plpgsql
security definer
set search_path = catalog, iam, pg_temp
as $$
declare
  v_actor_id uuid;
begin
  v_actor_id := auth.uid();
  if v_actor_id is null then
    raise exception 'not authenticated';
  end if;

  if not iam.has_permission(p_tenant_id, 'catalog.product.manage_pricing') then
    raise exception 'permission denied: catalog.product.manage_pricing';
  end if;

  if not exists (select 1 from catalog.products where id = p_product_id and tenant_id = p_tenant_id) then
    raise exception 'product not found';
  end if;

  if p_mode <> 'manual' then
    raise exception 'not_manual_base_price_mode';
  end if;

  if p_base_price is not null and p_base_price < 0 then
    raise exception 'validation_exception: base price cannot be negative';
  end if;

  insert into catalog.product_base_price_profiles (product_id, tenant_id, mode, base_price_amount, currency, updated_at)
  values (p_product_id, p_tenant_id, p_mode, p_base_price, coalesce(p_currency, 'VND'), now())
  on conflict (product_id) do update set
    mode = excluded.mode,
    base_price_amount = excluded.base_price_amount,
    currency = excluded.currency,
    updated_at = now();

  insert into catalog.product_change_history (tenant_id, product_id, action, payload, actor_id)
  values (
    p_tenant_id,
    p_product_id,
    'set_manual_base_price',
    jsonb_build_object('mode', p_mode, 'base_price', p_base_price, 'currency', p_currency),
    v_actor_id
  );
end;
$$;

-- RPC: set_initial_price_band
create or replace function catalog.set_initial_price_band(
  p_tenant_id uuid,
  p_product_id uuid,
  p_product_unit_id uuid,
  p_list_price numeric,
  p_floor_price numeric
)
returns void
language plpgsql
security definer
set search_path = catalog, iam, pg_temp
as $$
declare
  v_actor_id uuid;
  v_has_image boolean;
  v_has_unit boolean;
  v_blockers jsonb;
  v_new_status catalog.product_readiness_status;
begin
  v_actor_id := auth.uid();
  if v_actor_id is null then
    raise exception 'not authenticated';
  end if;

  if not iam.has_permission(p_tenant_id, 'catalog.product.manage_pricing') then
    raise exception 'permission denied: catalog.product.manage_pricing';
  end if;

  if not exists (select 1 from catalog.products where id = p_product_id and tenant_id = p_tenant_id) then
    raise exception 'product not found';
  end if;

  if p_floor_price is not null and p_list_price is not null and p_floor_price > p_list_price then
    raise exception 'floor_price_greater_than_list_price';
  end if;

  insert into catalog.product_unit_price_bands (tenant_id, product_id, product_unit_id, list_price_amount, floor_price_amount, updated_at)
  values (p_tenant_id, p_product_id, p_product_unit_id, p_list_price, p_floor_price, now())
  on conflict (product_id, product_unit_id) do update set
    list_price_amount = excluded.list_price_amount,
    floor_price_amount = excluded.floor_price_amount,
    updated_at = now();

  -- Evaluate readiness
  select exists(select 1 from catalog.product_images where product_id = p_product_id and tenant_id = p_tenant_id) into v_has_image;
  select exists(select 1 from catalog.product_units where product_id = p_product_id and tenant_id = p_tenant_id) into v_has_unit;

  v_blockers := '[]'::jsonb;
  if not v_has_image then
    v_blockers := v_blockers || '[{"code": "missing_image", "group": "optional", "message": "Product has no images yet"}]'::jsonb;
  end if;
  if not v_has_unit then
    v_blockers := v_blockers || '[{"code": "missing_base_unit", "group": "required", "message": "Product missing base unit"}]'::jsonb;
  end if;
  -- Note: price band is now set, so no missing_price blocker!

  if not v_has_unit then
    v_new_status := 'incomplete'::catalog.product_readiness_status;
  else
    v_new_status := 'ready_to_sell'::catalog.product_readiness_status;
  end if;

  insert into catalog.product_readiness (product_id, tenant_id, status, blockers, updated_at)
  values (p_product_id, p_tenant_id, v_new_status, v_blockers, now())
  on conflict (product_id) do update set
    status = excluded.status,
    blockers = excluded.blockers,
    updated_at = now();

  insert into catalog.product_change_history (tenant_id, product_id, action, payload, actor_id)
  values (
    p_tenant_id,
    p_product_id,
    'set_initial_price_band',
    jsonb_build_object('product_unit_id', p_product_unit_id, 'list_price', p_list_price, 'floor_price', p_floor_price, 'readiness_status', v_new_status),
    v_actor_id
  );
end;
$$;
