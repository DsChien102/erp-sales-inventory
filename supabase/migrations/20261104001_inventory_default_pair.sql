-- Title: inventory default store/warehouse pair
-- Kind: patch
-- Intent: inventory_default_pair
-- Context: TH-07 / KB-KGV-003; PLAN 5-A4
-- Touches: ensure_default_store_warehouse_pair, get_default_store_warehouse_pair
-- Safety: one-shot ; low
-- Depends on: 20261113001_inventory_supplier_programs (runtime _ensure_walk_in_supplier), 20260830001_iam_active_store_context_group_a, 20260916001_iam_ensure_default_store_scope_helpers, 20260811024_iam_patch_owner_role_canonicalization
-- Promoted from _drafts/inventory_default_pair.sql

create schema if not exists inventory;

grant usage on schema inventory to authenticated;

create table inventory.warehouses (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references iam.tenants (id) on delete cascade,
  display_name text not null,
  status text not null,
  created_at timestamptz not null default now(),
  constraint warehouses_status_check check (status in ('active', 'inactive')),
  constraint warehouses_tenant_id_id_key unique (tenant_id, id)
);

create unique index warehouses_one_active_per_tenant
  on inventory.warehouses (tenant_id)
  where status = 'active';

create table inventory.store_warehouse_assignments (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references iam.tenants (id) on delete cascade,
  store_id uuid not null,
  warehouse_id uuid not null,
  status text not null,
  created_at timestamptz not null default now(),
  constraint store_warehouse_assignments_status_check
    check (status in ('active', 'inactive')),
  constraint store_warehouse_assignments_store_fkey
    foreign key (tenant_id, store_id)
    references iam.stores (tenant_id, id)
    on delete cascade,
  constraint store_warehouse_assignments_warehouse_fkey
    foreign key (tenant_id, warehouse_id)
    references inventory.warehouses (tenant_id, id)
    on delete cascade
);

create unique index store_warehouse_assignments_one_active_per_tenant
  on inventory.store_warehouse_assignments (tenant_id)
  where status = 'active';

create table inventory.idempotency_records (
  id uuid primary key,
  tenant_id uuid not null,
  command_scope varchar(100) not null,
  idempotency_key varchar(150) not null,
  payload_hash varchar(128) not null,
  status text not null,
  result_type varchar(100),
  result_id uuid,
  result_snapshot jsonb,
  correlation_id uuid not null,
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint idempotency_records_status_check
    check (status in ('in_progress', 'succeeded', 'failed', 'uncertain')),
  constraint idempotency_records_tenant_scope_key
    unique (tenant_id, command_scope, idempotency_key)
);

alter table inventory.warehouses enable row level security;
alter table inventory.store_warehouse_assignments enable row level security;
alter table inventory.idempotency_records enable row level security;

revoke all on inventory.warehouses from public, anon, authenticated;
revoke all on inventory.store_warehouse_assignments from public, anon, authenticated;
revoke all on inventory.idempotency_records from public, anon, authenticated;

create or replace function inventory.ensure_default_store_warehouse_pair(
  p_tenant_id uuid,
  p_correlation_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = inventory, iam, pg_temp
as $$
declare
  v_active_warehouse_count int;
  v_active_assignment_count int;
  v_warehouse_id uuid;
  v_warehouse_name text;
  v_assignment_warehouse_id uuid;
  v_store_id uuid;
  v_store_name text;
  v_active_store_count int;
  v_default_store_count int;
  v_snapshot jsonb;
begin
  if p_tenant_id is null or p_correlation_id is null then
    raise exception 'CONTEXT_INVALID';
  end if;

  if not exists (
    select 1
    from iam.tenants t
    where t.id = p_tenant_id
  ) then
    raise exception 'RESOURCE_NOT_FOUND';
  end if;

  if not iam.has_permission(p_tenant_id, 'inventory.default_pair.ensure') then
    raise exception 'Permission denied: inventory.default_pair.ensure';
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended(
      p_tenant_id::text || ':inventory.default_pair:' || p_tenant_id::text,
      0
    )
  );

  perform inventory._ensure_walk_in_supplier(p_tenant_id);

  select count(*)::int
  into v_active_warehouse_count
  from inventory.warehouses w
  where w.tenant_id = p_tenant_id
    and w.status = 'active';

  select count(*)::int
  into v_active_assignment_count
  from inventory.store_warehouse_assignments a
  where a.tenant_id = p_tenant_id
    and a.status = 'active';

  if v_active_warehouse_count = 1 and v_active_assignment_count = 1 then
    select w.id, w.display_name, a.warehouse_id, a.store_id
    into v_warehouse_id, v_warehouse_name, v_assignment_warehouse_id, v_store_id
    from inventory.warehouses w
    join inventory.store_warehouse_assignments a
      on a.tenant_id = w.tenant_id
     and a.status = 'active'
    where w.tenant_id = p_tenant_id
      and w.status = 'active';

    if v_assignment_warehouse_id is distinct from v_warehouse_id then
      raise exception 'DEFAULT_PAIR_LIMIT';
    end if;

    select s.display_name
    into v_store_name
    from iam.stores s
    where s.tenant_id = p_tenant_id
      and s.id = v_store_id;

    return jsonb_build_object(
      'storeId', v_store_id,
      'storeName', v_store_name,
      'warehouseId', v_warehouse_id,
      'warehouseName', v_warehouse_name,
      'replayed', true
    );
  end if;

  if not (
    (v_active_warehouse_count = 0 and v_active_assignment_count = 0)
    or (v_active_warehouse_count = 1 and v_active_assignment_count = 0)
  ) then
    raise exception 'DEFAULT_PAIR_LIMIT';
  end if;

  select
    (count(*) filter (where s.status = 'active'))::int,
    (count(*) filter (where s.status = 'active' and s.code = 'default'))::int
  into v_active_store_count, v_default_store_count
  from iam.stores s
  where s.tenant_id = p_tenant_id;

  if v_active_store_count > 0 and v_default_store_count = 0 then
    raise exception 'DEFAULT_STORE_MISSING';
  end if;

  v_store_id := iam._ensure_tenant_default_store(p_tenant_id);

  select s.display_name
  into v_store_name
  from iam.stores s
  where s.tenant_id = p_tenant_id
    and s.id = v_store_id;

  if v_active_warehouse_count = 0 then
    insert into inventory.warehouses (tenant_id, display_name, status)
    values (p_tenant_id, 'Kho mặc định', 'active')
    returning id, display_name
    into v_warehouse_id, v_warehouse_name;
  else
    select w.id, w.display_name
    into v_warehouse_id, v_warehouse_name
    from inventory.warehouses w
    where w.tenant_id = p_tenant_id
      and w.status = 'active';
  end if;

  insert into inventory.store_warehouse_assignments (
    tenant_id,
    store_id,
    warehouse_id,
    status
  )
  values (p_tenant_id, v_store_id, v_warehouse_id, 'active');

  v_snapshot := jsonb_build_object(
    'storeId', v_store_id,
    'storeName', v_store_name,
    'warehouseId', v_warehouse_id,
    'warehouseName', v_warehouse_name
  );

  insert into inventory.idempotency_records (
    id,
    tenant_id,
    command_scope,
    idempotency_key,
    payload_hash,
    status,
    result_type,
    result_id,
    result_snapshot,
    correlation_id,
    expires_at
  )
  values (
    gen_random_uuid(),
    p_tenant_id,
    'inventory.default_pair',
    p_tenant_id::text,
    'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    'succeeded',
    'inventory.default_pair',
    v_warehouse_id,
    v_snapshot,
    p_correlation_id,
    null
  )
  on conflict (tenant_id, command_scope, idempotency_key) do update
    set payload_hash = excluded.payload_hash,
        status = 'succeeded',
        result_type = excluded.result_type,
        result_id = excluded.result_id,
        result_snapshot = excluded.result_snapshot,
        correlation_id = excluded.correlation_id,
        expires_at = null,
        updated_at = now();

  return jsonb_build_object(
    'storeId', v_store_id,
    'storeName', v_store_name,
    'warehouseId', v_warehouse_id,
    'warehouseName', v_warehouse_name,
    'replayed', false
  );
exception
  when unique_violation then
    raise exception 'DEFAULT_PAIR_LIMIT';
end;
$$;

create or replace function inventory.get_default_store_warehouse_pair(
  p_tenant_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = inventory, iam, pg_temp
as $$
declare
  v_active_warehouse_count int;
  v_active_assignment_count int;
  v_warehouse_id uuid;
  v_warehouse_name text;
  v_assignment_warehouse_id uuid;
  v_store_id uuid;
  v_store_name text;
begin
  if p_tenant_id is null then
    raise exception 'CONTEXT_INVALID';
  end if;

  if not iam.has_permission(p_tenant_id, 'inventory.default_pair.read') then
    raise exception 'Permission denied: inventory.default_pair.read';
  end if;

  select count(*)::int
  into v_active_warehouse_count
  from inventory.warehouses w
  where w.tenant_id = p_tenant_id
    and w.status = 'active';

  select count(*)::int
  into v_active_assignment_count
  from inventory.store_warehouse_assignments a
  where a.tenant_id = p_tenant_id
    and a.status = 'active';

  if v_active_warehouse_count <> 1 or v_active_assignment_count <> 1 then
    raise exception 'DEFAULT_PAIR_MISSING';
  end if;

  select w.id, w.display_name, a.warehouse_id, a.store_id
  into v_warehouse_id, v_warehouse_name, v_assignment_warehouse_id, v_store_id
  from inventory.warehouses w
  join inventory.store_warehouse_assignments a
    on a.tenant_id = w.tenant_id
   and a.status = 'active'
  where w.tenant_id = p_tenant_id
    and w.status = 'active';

  if v_assignment_warehouse_id is distinct from v_warehouse_id then
    raise exception 'DEFAULT_PAIR_MISSING';
  end if;

  select s.display_name
  into v_store_name
  from iam.stores s
  where s.tenant_id = p_tenant_id
    and s.id = v_store_id;

  return jsonb_build_object(
    'storeId', v_store_id,
    'storeName', v_store_name,
    'warehouseId', v_warehouse_id,
    'warehouseName', v_warehouse_name
  );
end;
$$;

revoke all on function inventory.ensure_default_store_warehouse_pair(uuid, uuid)
  from public, anon;
revoke all on function inventory.get_default_store_warehouse_pair(uuid)
  from public, anon;

grant execute on function inventory.ensure_default_store_warehouse_pair(uuid, uuid)
  to authenticated;
grant execute on function inventory.get_default_store_warehouse_pair(uuid)
  to authenticated;
