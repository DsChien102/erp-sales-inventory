-- Title: inventory core schema and ledger
-- Kind: schema
-- Intent: inventory_core
-- Context: TH-07 / KB-KGV-001..005, spec giá vốn; PLAN T7-G5-0b
-- Touches: ledger_counters, lots, stock_movements, stock_balances, cost_policies, cost_periods, cost_versions, value_movements, product_costs, _raise, _forbid_ledger_mutation, _lock_tracking_after_movement, _assert_actor, _begin_idempotency, _complete_idempotency, _cost_method, _ensure_open_period, _available_quantity, _next_ledger_sequence, _value_line, _post_movements, get_warehouse_hub_summary
-- Safety: one-shot ; low lock impact on new tables
-- Depends on: 20261104001_inventory_default_pair, 20260709001_catalog_guided_create

create schema if not exists inventory;

create or replace function inventory._raise(p_code text, p_message text)
returns void
language plpgsql
as $$
begin
  -- Core Error Codes:
  -- 'PERMISSION_DENIED', 'CONTEXT_INVALID', 'DATA_SCOPE_DENIED', 'IDEMPOTENCY_CONFLICT',
  -- 'COMMAND_IN_PROGRESS', 'VERSION_CONFLICT', 'INSUFFICIENT_STOCK', 'LOT_REQUIRED',
  -- 'LOT_NOT_ALLOWED', 'EXPIRY_REQUIRED', 'LOT_ATTRIBUTE_CONFLICT', 'TRACKING_LOCKED',
  -- 'UNIT_COST_REQUIRED', 'PERIOD_CLOSED'
  raise exception using message = jsonb_build_object(
    'code', p_code,
    'message', p_message
  )::text;
end;
$$;

revoke all on function inventory._raise(text, text) from public, anon, authenticated;

-- 1. Ledger counters (tenant-monotonic counter)
create table inventory.ledger_counters (
  tenant_id uuid primary key references iam.tenants (id) on delete cascade,
  last_sequence bigint not null default 0
);

-- 2. Lots
create table inventory.lots (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references iam.tenants (id) on delete cascade,
  product_id uuid not null references catalog.products (id) on delete cascade,
  lot_code text not null,
  lot_code_normalized text not null,
  expiry_date date,
  expiry_precision text check (expiry_precision is null or expiry_precision in ('DAY', 'MONTH', 'YEAR')),
  manufacture_date date,
  origin_intent_type text,
  origin_intent_id uuid,
  created_at timestamptz not null default now(),
  created_by uuid not null,
  constraint chk_lots_code_not_blank check (length(btrim(lot_code)) > 0),
  constraint lots_tenant_product_code_key unique (tenant_id, product_id, lot_code_normalized)
);

-- 3. Stock movements (append-only ledger)
create table inventory.stock_movements (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references iam.tenants (id) on delete cascade,
  ledger_sequence bigint not null,
  warehouse_id uuid not null references inventory.warehouses (id) on delete cascade,
  product_id uuid not null references catalog.products (id) on delete cascade,
  lot_id uuid references inventory.lots (id) on delete set null,
  intent_type text not null,
  intent_id uuid not null,
  intent_line_id uuid,
  movement_kind text not null check (movement_kind in (
    'OPENING', 'RECEIPT', 'SALE', 'SALE_REVERSAL',
    'RETURN_IN', 'COUNT_GAIN', 'COUNT_LOSS', 'WRITE_OFF'
  )),
  reason text check (reason is null or reason in ('DAMAGED', 'EXPIRED', 'LOSS', 'COUNT')),
  quantity_delta numeric not null check (quantity_delta <> 0),
  business_date date not null,
  created_at timestamptz not null default now(),
  created_by uuid not null,
  constraint stock_movements_tenant_sequence_key unique (tenant_id, ledger_sequence)
);

-- 4. Stock balances
create table inventory.stock_balances (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references iam.tenants (id) on delete cascade,
  warehouse_id uuid not null references inventory.warehouses (id) on delete cascade,
  product_id uuid not null references catalog.products (id) on delete cascade,
  lot_key uuid not null,
  physical_quantity numeric not null default 0 check (physical_quantity >= 0),
  last_ledger_sequence bigint not null default 0,
  updated_at timestamptz not null default now(),
  constraint stock_balances_unique_key unique (tenant_id, warehouse_id, product_id, lot_key)
);

-- 5. Cost policies
create table inventory.cost_policies (
  tenant_id uuid primary key references iam.tenants (id) on delete cascade,
  method text not null default 'MOVING' check (method in ('MOVING', 'PERIODIC')),
  changed_at timestamptz not null default now(),
  changed_by uuid not null
);

-- 6. Cost periods
create table inventory.cost_periods (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references iam.tenants (id) on delete cascade,
  period_month date not null,
  status text not null default 'OPEN' check (status in ('OPEN', 'CLOSED')),
  closed_at timestamptz,
  closed_by uuid,
  closing_run_id uuid,
  constraint cost_periods_tenant_month_key unique (tenant_id, period_month)
);

-- 7. Cost versions
create table inventory.cost_versions (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references iam.tenants (id) on delete cascade,
  product_id uuid not null references catalog.products (id) on delete cascade,
  unit_cost numeric(18,4) not null check (unit_cost >= 0),
  method text not null check (method in ('MOVING', 'PERIODIC')),
  effective_from_sequence bigint not null,
  cost_run_id uuid,
  created_at timestamptz not null default now()
);

-- 8. Value movements (append-only ledger)
create table inventory.value_movements (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references iam.tenants (id) on delete cascade,
  ledger_sequence bigint not null,
  product_id uuid not null references catalog.products (id) on delete cascade,
  movement_id uuid references inventory.stock_movements (id) on delete cascade,
  kind text not null check (kind in (
    'OPENING', 'RECEIPT', 'SALE', 'SALE_REVERSAL', 'RETURN_IN',
    'COUNT_GAIN', 'COUNT_LOSS', 'WRITE_OFF',
    'COGS_TRUE_UP', 'LOSS_TRUE_UP', 'REVALUE_ROUNDING', 'SUPPLIER_REBATE'
  )),
  quantity_basis numeric not null default 0,
  unit_cost numeric(18,4) check (unit_cost is null or unit_cost >= 0),
  amount_vnd bigint not null,
  cost_version_id uuid references inventory.cost_versions (id) on delete set null,
  is_provisional boolean not null default false,
  cost_run_id uuid,
  supplier_rebate_id uuid,
  source_movement_id uuid references inventory.stock_movements (id) on delete set null,
  business_date date not null,
  created_at timestamptz not null default now(),
  created_by uuid not null,
  constraint chk_value_movements_adjust_requires_run check (
    (kind in ('COGS_TRUE_UP', 'LOSS_TRUE_UP', 'REVALUE_ROUNDING') and movement_id is null and cost_run_id is not null)
    or (kind = 'SUPPLIER_REBATE' and movement_id is null and supplier_rebate_id is not null)
    or (kind not in ('COGS_TRUE_UP', 'LOSS_TRUE_UP', 'REVALUE_ROUNDING', 'SUPPLIER_REBATE') and movement_id is not null)
  ),
  constraint value_movements_tenant_sequence_key unique (tenant_id, ledger_sequence)
);

-- 9. Product costs (moving average cost & ledger valuation per tenant + product)
create table inventory.product_costs (
  tenant_id uuid not null references iam.tenants (id) on delete cascade,
  product_id uuid not null references catalog.products (id) on delete cascade,
  quantity_on_hand numeric not null default 0 check (quantity_on_hand >= 0),
  ledger_value_vnd bigint not null default 0,
  moving_avg_cost numeric(18,4) not null default 0 check (moving_avg_cost >= 0),
  official_version_id uuid references inventory.cost_versions (id) on delete set null,
  official_unit_cost numeric(18,4) check (official_unit_cost is null or official_unit_cost >= 0),
  last_ledger_sequence bigint not null default 0,
  updated_at timestamptz not null default now(),
  primary key (tenant_id, product_id)
);

-- RLS & Revoke
alter table inventory.ledger_counters enable row level security;
alter table inventory.lots enable row level security;
alter table inventory.stock_movements enable row level security;
alter table inventory.stock_balances enable row level security;
alter table inventory.cost_policies enable row level security;
alter table inventory.cost_periods enable row level security;
alter table inventory.cost_versions enable row level security;
alter table inventory.value_movements enable row level security;
alter table inventory.product_costs enable row level security;

revoke all on inventory.ledger_counters from public, anon, authenticated;
revoke all on inventory.lots from public, anon, authenticated;
revoke all on inventory.stock_movements from public, anon, authenticated;
revoke all on inventory.stock_balances from public, anon, authenticated;
revoke all on inventory.cost_policies from public, anon, authenticated;
revoke all on inventory.cost_periods from public, anon, authenticated;
revoke all on inventory.cost_versions from public, anon, authenticated;
revoke all on inventory.value_movements from public, anon, authenticated;
revoke all on inventory.product_costs from public, anon, authenticated;

-- Triggers for append-only ledger
create or replace function inventory._forbid_ledger_mutation()
returns trigger
language plpgsql
as $$
begin
  perform inventory._raise('CONTEXT_INVALID', 'Ledger is append-only.');
  return null;
end;
$$;

revoke all on function inventory._forbid_ledger_mutation() from public, anon, authenticated;

create trigger trg_stock_movements_forbid_mutation
  before update or delete on inventory.stock_movements
  for each row execute function inventory._forbid_ledger_mutation();

create trigger trg_value_movements_forbid_mutation
  before update or delete on inventory.value_movements
  for each row execute function inventory._forbid_ledger_mutation();

create trigger trg_cost_versions_forbid_mutation
  before update or delete on inventory.cost_versions
  for each row execute function inventory._forbid_ledger_mutation();

-- Trigger on catalog.products to lock tracking mode changes after movement
create or replace function catalog._lock_tracking_after_movement()
returns trigger
language plpgsql
as $$
begin
  if (new.tracking_mode is distinct from old.tracking_mode
      or new.expiry_required is distinct from old.expiry_required) then
    if exists (
      select 1 from inventory.stock_movements m
      where m.tenant_id = old.tenant_id and m.product_id = old.id
    ) then
      perform inventory._raise(
        'TRACKING_LOCKED',
        'Đã có biến động kho, không đổi được.'
      );
    end if;
  end if;
  return new;
end;
$$;

revoke all on function catalog._lock_tracking_after_movement() from public, anon, authenticated;

create trigger trg_catalog_products_lock_tracking
  before update of tracking_mode, expiry_required on catalog.products
  for each row execute function catalog._lock_tracking_after_movement();

-- ---------------------------------------------------------------------------
-- Helpers (Internal, revoke execute from authenticated)
-- ---------------------------------------------------------------------------

-- 1. _assert_actor: check auth, permission, is_owner, store_warehouse_assignments
create or replace function inventory._assert_actor(
  p_tenant_id uuid,
  p_permission text,
  p_require_owner boolean default false
) returns jsonb
language plpgsql
security definer
set search_path = inventory, iam, public, pg_temp
as $$
declare
  v_actor_id uuid := auth.uid();
  v_owner boolean := false;
  v_assignment record;
begin
  if v_actor_id is null then
    perform inventory._raise('PERMISSION_DENIED', 'Not authenticated.');
  end if;

  if not iam.has_permission(p_tenant_id, p_permission) then
    perform inventory._raise('PERMISSION_DENIED', 'Permission denied: ' || coalesce(p_permission, ''));
  end if;

  -- check is_owner
  select coalesce(m.is_owner, false)
  into v_owner
  from iam.memberships m
  where m.tenant_id = p_tenant_id
    and m.user_id = v_actor_id;

  v_owner := coalesce(v_owner, false);

  if p_require_owner and not v_owner then
    perform inventory._raise('PERMISSION_DENIED', 'Owner permission required.');
  end if;

  select store_id, warehouse_id into v_assignment
  from inventory.store_warehouse_assignments
  where tenant_id = p_tenant_id
    and status = 'active';

  if not found then
    perform inventory._raise('CONTEXT_INVALID', 'Active store warehouse assignment not found.');
  end if;

  return jsonb_build_object(
    'actor_id', v_actor_id,
    'is_owner', v_owner,
    'store_id', v_assignment.store_id,
    'warehouse_id', v_assignment.warehouse_id
  );
end;
$$;

revoke all on function inventory._assert_actor(uuid, text, boolean) from public, anon, authenticated;

-- 2. _begin_idempotency: advisory lock -> new | replay | in_progress, conflict on hash mismatch
create or replace function inventory._begin_idempotency(
  p_tenant_id uuid,
  p_command_scope text,
  p_idempotency_key text,
  p_payload_hash text
) returns jsonb
language plpgsql
security definer
set search_path = inventory, iam, public, pg_temp
as $$
declare
  v_key text := trim(p_idempotency_key);
  v_hash text := coalesce(nullif(trim(coalesce(p_payload_hash, '')), ''), '');
  v_record inventory.idempotency_records%rowtype;
begin
  if nullif(v_key, '') is null or nullif(trim(coalesce(p_command_scope, '')), '') is null then
    perform inventory._raise('CONTEXT_INVALID', 'Idempotency scope and key are required.');
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended(p_tenant_id::text || ':' || trim(p_command_scope) || ':' || v_key, 0)
  );

  select * into v_record
  from inventory.idempotency_records
  where tenant_id = p_tenant_id
    and command_scope = trim(p_command_scope)
    and idempotency_key = v_key
  for update;

  if found then
    if v_record.payload_hash is distinct from v_hash then
      perform inventory._raise('IDEMPOTENCY_CONFLICT', 'Idempotency key was already used with another payload.');
    end if;

    if v_record.status = 'in_progress' then
      return jsonb_build_object(
        'decision', 'in_progress',
        'status', v_record.status,
        'result_snapshot', v_record.result_snapshot
      );
    end if;

    return jsonb_build_object(
      'decision', 'replay',
      'status', v_record.status,
      'result_snapshot', v_record.result_snapshot
    );
  end if;

  insert into inventory.idempotency_records (
    id,
    tenant_id,
    command_scope,
    idempotency_key,
    payload_hash,
    status,
    correlation_id
  ) values (
    gen_random_uuid(),
    p_tenant_id,
    trim(p_command_scope),
    v_key,
    v_hash,
    'in_progress',
    gen_random_uuid()
  );

  return jsonb_build_object(
    'decision', 'new',
    'status', 'in_progress'
  );
end;
$$;

revoke all on function inventory._begin_idempotency(uuid, text, text, text) from public, anon, authenticated;

-- 3. _complete_idempotency: save succeeded/failed result snapshot
create or replace function inventory._complete_idempotency(
  p_tenant_id uuid,
  p_command_scope text,
  p_idempotency_key text,
  p_status text,
  p_result_snapshot jsonb
) returns void
language plpgsql
security definer
set search_path = inventory, iam, public, pg_temp
as $$
declare
  v_key text := trim(p_idempotency_key);
begin
  if p_status not in ('succeeded', 'failed') then
    perform inventory._raise('CONTEXT_INVALID', 'Idempotency completion status is invalid.');
  end if;

  update inventory.idempotency_records
  set status = p_status,
      result_snapshot = p_result_snapshot,
      updated_at = now()
  where tenant_id = p_tenant_id
    and command_scope = trim(p_command_scope)
    and idempotency_key = v_key;
end;
$$;

revoke all on function inventory._complete_idempotency(uuid, text, text, text, jsonb) from public, anon, authenticated;

-- 4. _cost_method: returns MOVING or PERIODIC
create or replace function inventory._cost_method(p_tenant_id uuid)
returns text
language plpgsql
security definer
set search_path = inventory, pg_temp
as $$
declare
  v_method text;
begin
  select method into v_method
  from inventory.cost_policies
  where tenant_id = p_tenant_id;

  return coalesce(v_method, 'MOVING');
end;
$$;

revoke all on function inventory._cost_method(uuid) from public, anon, authenticated;

-- 5. _ensure_open_period: checks if period is CLOSED -> PERIOD_CLOSED, creates OPEN if missing
create or replace function inventory._ensure_open_period(
  p_tenant_id uuid,
  p_business_date date
) returns uuid
language plpgsql
security definer
set search_path = inventory, pg_temp
as $$
declare
  v_month date := date_trunc('month', p_business_date)::date;
  v_period record;
  v_period_id uuid;
begin
  select id, status into v_period
  from inventory.cost_periods
  where tenant_id = p_tenant_id
    and period_month = v_month;

  if found then
    if v_period.status = 'CLOSED' then
      perform inventory._raise('PERIOD_CLOSED', 'Kỳ giá vốn ' || to_char(v_month, 'MM/YYYY') || ' đã khoá sổ.');
    end if;
    return v_period.id;
  end if;

  insert into inventory.cost_periods (
    tenant_id,
    period_month,
    status
  ) values (
    p_tenant_id,
    v_month,
    'OPEN'
  )
  on conflict (tenant_id, period_month) do update
    set period_month = excluded.period_month
  returning id into v_period_id;

  return v_period_id;
end;
$$;

revoke all on function inventory._ensure_open_period(uuid, date) from public, anon, authenticated;

-- 6. _available_quantity: sum of physical_quantity for product (+ optional lot)
create or replace function inventory._available_quantity(
  p_tenant_id uuid,
  p_product_id uuid,
  p_lot_id uuid default null
) returns numeric
language plpgsql
security definer
set search_path = inventory, pg_temp
as $$
declare
  v_qty numeric;
begin
  select coalesce(sum(physical_quantity), 0) into v_qty
  from inventory.stock_balances
  where tenant_id = p_tenant_id
    and product_id = p_product_id
    and (p_lot_id is null or lot_key = p_lot_id);

  return v_qty;
end;
$$;

revoke all on function inventory._available_quantity(uuid, uuid, uuid) from public, anon, authenticated;

-- 7. _next_ledger_sequence: increments and returns sequence from ledger_counters
create or replace function inventory._next_ledger_sequence(p_tenant_id uuid)
returns bigint
language plpgsql
security definer
set search_path = inventory, pg_temp
as $$
declare
  v_seq bigint;
begin
  insert into inventory.ledger_counters (tenant_id, last_sequence)
  values (p_tenant_id, 1)
  on conflict (tenant_id) do update
  set last_sequence = inventory.ledger_counters.last_sequence + 1
  returning last_sequence into v_seq;

  return v_seq;
end;
$$;

revoke all on function inventory._next_ledger_sequence(uuid) from public, anon, authenticated;

-- 8. _value_line: records a value_movement row and updates product_costs
create or replace function inventory._value_line(
  p_tenant_id          uuid,
  p_movement_id        uuid,
  p_product_id         uuid,
  p_kind               text,
  p_quantity           numeric,
  p_unit_cost          numeric,
  p_amount_vnd         bigint,
  p_source_movement_id uuid,
  p_business_date      date,
  p_created_by         uuid default auth.uid()
) returns jsonb
language plpgsql
security definer
set search_path = inventory, iam, catalog, pg_temp
as $$
declare
  v_method text;
  v_cost record;
  v_q numeric;
  v_val bigint;
  v_m numeric(18,4);
  v_o numeric(18,4);
  v_official_version_id uuid;
  v_cost_version_id uuid := null;
  v_is_provisional boolean := false;
  v_c numeric(18,4) := null;
  v_amount bigint := null;
  v_delta numeric := p_quantity;
  v_new_q numeric;
  v_new_val bigint;
  v_new_m numeric(18,4);
  v_src_cost numeric(18,4);
  v_seq bigint;
  v_val_id uuid;
begin
  v_method := inventory._cost_method(p_tenant_id);

  insert into inventory.product_costs (
    tenant_id, product_id, quantity_on_hand, ledger_value_vnd,
    moving_avg_cost, official_unit_cost, official_version_id,
    last_ledger_sequence, updated_at
  ) values (
    p_tenant_id, p_product_id, 0, 0,
    0, null, null,
    0, now()
  ) on conflict (tenant_id, product_id) do nothing;

  select * into v_cost
  from inventory.product_costs
  where tenant_id = p_tenant_id and product_id = p_product_id
  for update;

  v_q := v_cost.quantity_on_hand;
  v_val := v_cost.ledger_value_vnd;
  v_m := v_cost.moving_avg_cost;
  v_o := v_cost.official_unit_cost;
  v_official_version_id := v_cost.official_version_id;

  if p_kind = 'RECEIPT' then
    if p_unit_cost is null or p_unit_cost < 0 then
      perform inventory._raise('UNIT_COST_REQUIRED', 'Nhập hàng yêu cầu đơn giá không âm.');
    end if;
    v_c := p_unit_cost;
    if p_amount_vnd is not null then
      v_amount := p_amount_vnd;
    else
      v_amount := round(abs(v_delta) * v_c)::bigint;
    end if;
    v_new_q := v_q + abs(v_delta);
    v_new_val := v_val + v_amount;
    if v_new_q > 0 then
      v_new_m := round((v_new_val::numeric / v_new_q::numeric), 4);
    else
      v_new_m := v_m;
    end if;
    update inventory.product_costs
    set quantity_on_hand = v_new_q,
        ledger_value_vnd = v_new_val,
        moving_avg_cost = v_new_m
    where tenant_id = p_tenant_id and product_id = p_product_id;

  elsif p_kind = 'COUNT_GAIN' then
    if v_method = 'PERIODIC' and v_o is not null then
      v_c := v_o;
      v_cost_version_id := v_official_version_id;
    else
      if p_unit_cost is not null and p_unit_cost > 0 then
        v_c := p_unit_cost;
      else
        v_c := v_m;
      end if;
      if v_q = 0 and (v_c is null or v_c = 0) then
        perform inventory._raise('UNIT_COST_REQUIRED', 'Kiểm kê tăng khi chưa có tồn yêu cầu đơn giá.');
      end if;
    end if;
    if p_amount_vnd is not null then
      v_amount := p_amount_vnd;
    else
      v_amount := round(abs(v_delta) * coalesce(v_c, 0))::bigint;
    end if;
    v_new_q := v_q + abs(v_delta);
    v_new_val := v_val + v_amount;
    if v_new_q > 0 then
      v_new_m := round((v_new_val::numeric / v_new_q::numeric), 4);
    else
      v_new_m := v_m;
    end if;
    update inventory.product_costs
    set quantity_on_hand = v_new_q,
        ledger_value_vnd = v_new_val,
        moving_avg_cost = v_new_m
    where tenant_id = p_tenant_id and product_id = p_product_id;

  elsif p_kind = 'RETURN_IN' then
    if p_source_movement_id is null then
      perform inventory._raise('CONTEXT_INVALID', 'Trả hàng nhập kho yêu cầu source_movement_id.');
    end if;
    select unit_cost into v_src_cost
    from inventory.value_movements
    where tenant_id = p_tenant_id and movement_id = p_source_movement_id;
    if v_src_cost is null then
      perform inventory._raise('CONTEXT_INVALID', 'Không tìm thấy dòng xuất gốc trong sổ giá trị.');
    end if;
    v_c := v_src_cost;
    v_amount := round(abs(v_delta) * v_c)::bigint;
    v_new_q := v_q + abs(v_delta);
    v_new_val := v_val + v_amount;
    if v_new_q > 0 then
      v_new_m := round((v_new_val::numeric / v_new_q::numeric), 4);
    else
      v_new_m := v_m;
    end if;
    update inventory.product_costs
    set quantity_on_hand = v_new_q,
        ledger_value_vnd = v_new_val,
        moving_avg_cost = v_new_m
    where tenant_id = p_tenant_id and product_id = p_product_id;

  elsif p_kind in ('SALE', 'COUNT_LOSS', 'WRITE_OFF') then
    if v_method = 'MOVING' then
      v_c := v_m;
    elsif v_method = 'PERIODIC' then
      if v_o is not null then
        v_c := v_o;
        v_cost_version_id := v_official_version_id;
      else
        v_c := v_m;
        v_is_provisional := true;
      end if;
    end if;
    v_amount := -round(abs(v_delta) * coalesce(v_c, 0))::bigint;
    v_new_q := v_q - abs(v_delta);
    v_new_val := v_val + v_amount;
    v_new_m := v_m;
    update inventory.product_costs
    set quantity_on_hand = v_new_q,
        ledger_value_vnd = v_new_val,
        moving_avg_cost = v_new_m
    where tenant_id = p_tenant_id and product_id = p_product_id;

  elsif p_kind = 'SALE_REVERSAL' then
    if p_source_movement_id is null then
      perform inventory._raise('CONTEXT_INVALID', 'Huỷ bán hàng yêu cầu source_movement_id.');
    end if;
    select unit_cost into v_src_cost
    from inventory.value_movements
    where tenant_id = p_tenant_id and movement_id = p_source_movement_id;
    if v_src_cost is null then
      perform inventory._raise('CONTEXT_INVALID', 'Không tìm thấy dòng xuất gốc cho huỷ bán hàng.');
    end if;
    v_c := v_src_cost;
    v_amount := round(abs(v_delta) * v_c)::bigint;
    v_new_q := v_q + abs(v_delta);
    v_new_val := v_val + v_amount;
    if v_new_q > 0 then
      v_new_m := round((v_new_val::numeric / v_new_q::numeric), 4);
    else
      v_new_m := v_m;
    end if;
    update inventory.product_costs
    set quantity_on_hand = v_new_q,
        ledger_value_vnd = v_new_val,
        moving_avg_cost = v_new_m
    where tenant_id = p_tenant_id and product_id = p_product_id;

  else
    perform inventory._raise('CONTEXT_INVALID', 'Loại biến động không được hỗ trợ trong sổ giá trị: ' || coalesce(p_kind, 'null'));
  end if;

  v_seq := inventory._next_ledger_sequence(p_tenant_id);

  insert into inventory.value_movements (
    tenant_id, ledger_sequence, product_id, movement_id, kind,
    quantity_basis, unit_cost, amount_vnd, cost_version_id, is_provisional,
    source_movement_id, business_date, created_by
  ) values (
    p_tenant_id, v_seq, p_product_id, p_movement_id, p_kind,
    abs(v_delta), v_c, v_amount, v_cost_version_id, v_is_provisional,
    p_source_movement_id, p_business_date, coalesce(p_created_by, auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid)
  ) returning id into v_val_id;

  update inventory.product_costs
  set last_ledger_sequence = v_seq, updated_at = now()
  where tenant_id = p_tenant_id and product_id = p_product_id;

  return jsonb_build_object(
    'value_movement_id', v_val_id,
    'unit_cost', v_c,
    'amount_vnd', v_amount,
    'cost_version_id', v_cost_version_id,
    'is_provisional', v_is_provisional
  );
end;
$$;

revoke all on function inventory._value_line(uuid, uuid, uuid, text, numeric, numeric, bigint, uuid, date, uuid) from public, anon, authenticated;

-- 9. _post_movements: core inventory posting for stock and value ledger
create or replace function inventory._post_movements(
  p_tenant_id        uuid,
  p_warehouse_id     uuid,
  p_intent_type      text,
  p_intent_id        uuid,
  p_business_date    date,
  p_lines            jsonb,
  p_created_by       uuid default auth.uid()
) returns jsonb
language plpgsql
security definer
set search_path = inventory, iam, catalog, pg_temp
as $$
declare
  v_prod_id uuid;
  v_elem jsonb;
  v_line_id uuid;
  v_product_id uuid;
  v_lot_id uuid;
  v_lot_code text;
  v_expiry_date date;
  v_expiry_precision text;
  v_manufacture_date date;
  v_qty_delta numeric;
  v_movement_kind text;
  v_reason text;
  v_unit_cost numeric;
  v_amount_vnd bigint;
  v_source_movement_id uuid;
  v_prod record;
  v_base_uom text;
  v_lot record;
  v_lot_key uuid;
  v_current_qty numeric;
  v_after_qty numeric;
  v_stock_seq bigint;
  v_movement_id uuid;
  v_val_res jsonb;
  v_res_movement_ids jsonb := '[]'::jsonb;
  v_res_lines jsonb := '[]'::jsonb;
  v_stock_changes jsonb := '[]'::jsonb;
begin
  -- 1. Ensure period is open before any lock or write
  perform inventory._ensure_open_period(p_tenant_id, p_business_date);

  if p_lines is null or jsonb_array_length(p_lines) = 0 then
    return jsonb_build_object(
      'movement_ids', v_res_movement_ids,
      'lines', v_res_lines,
      'stock_changes', v_stock_changes
    );
  end if;

  -- 2. Advisory lock ordered by product_id
  for v_prod_id in
    select distinct (elem->>'product_id')::uuid as pid
    from jsonb_array_elements(p_lines) as elem
    order by pid
  loop
    perform pg_advisory_xact_lock(
      hashtext(p_tenant_id::text),
      hashtext(v_prod_id::text)
    );
  end loop;

  -- 3. Iterate through lines
  for v_elem in select * from jsonb_array_elements(p_lines)
  loop
    v_line_id := coalesce((v_elem->>'line_id')::uuid, gen_random_uuid());
    v_product_id := (v_elem->>'product_id')::uuid;
    v_lot_code := trim(coalesce(v_elem->>'lot_code', ''));
    v_expiry_date := (v_elem->>'expiry_date')::date;
    v_expiry_precision := coalesce(v_elem->>'expiry_precision', 'DAY');
    v_manufacture_date := (v_elem->>'manufacture_date')::date;
    v_qty_delta := (v_elem->>'quantity_delta')::numeric;
    v_movement_kind := v_elem->>'movement_kind';
    v_reason := v_elem->>'reason';
    v_unit_cost := (v_elem->>'unit_cost')::numeric;
    v_amount_vnd := (v_elem->>'amount_vnd')::bigint;
    v_source_movement_id := (v_elem->>'source_movement_id')::uuid;

    if v_qty_delta is null or v_qty_delta = 0 then
      perform inventory._raise('CONTEXT_INVALID', 'Số lượng biến động không được rỗng hoặc bằng 0.');
    end if;

    if v_movement_kind in ('RECEIPT', 'RETURN_IN', 'COUNT_GAIN', 'SALE_REVERSAL') then
      if v_qty_delta <= 0 then
        perform inventory._raise('CONTEXT_INVALID', 'Chiều vào yêu cầu số lượng dương.');
      end if;
    elsif v_movement_kind in ('SALE', 'COUNT_LOSS', 'WRITE_OFF') then
      if v_qty_delta >= 0 then
        perform inventory._raise('CONTEXT_INVALID', 'Chiều ra yêu cầu số lượng âm.');
      end if;
    else
      perform inventory._raise('CONTEXT_INVALID', 'Loại biến động không hợp lệ: ' || coalesce(v_movement_kind, 'null'));
    end if;

    select id, name, tracking_mode, expiry_required
    into v_prod
    from catalog.products
    where id = v_product_id and tenant_id = p_tenant_id and deleted_at is null;

    if not found then
      perform inventory._raise('CONTEXT_INVALID', 'Sản phẩm không tồn tại: ' || v_product_id::text);
    end if;

    v_base_uom := catalog._product_base_unit_name(p_tenant_id, v_product_id);

    -- Lot rules
    if v_prod.tracking_mode = 'none' then
      if v_lot_code <> '' or (v_elem->>'lot_id') is not null then
        perform inventory._raise('LOT_NOT_ALLOWED', 'Sản phẩm ' || v_prod.name || ' không quản lý theo lô.');
      end if;
      v_lot_id := null;
      v_lot_key := '00000000-0000-0000-0000-000000000000'::uuid;
    elsif v_prod.tracking_mode = 'lot' then
      if (v_elem->>'lot_id') is not null then
        v_lot_id := (v_elem->>'lot_id')::uuid;
        select * into v_lot
        from inventory.lots
        where id = v_lot_id and tenant_id = p_tenant_id and product_id = v_product_id;
        if not found then
          perform inventory._raise('LOT_REQUIRED', 'Lô không tồn tại: ' || v_lot_id::text);
        end if;
        v_lot_key := v_lot_id;
      elsif v_lot_code <> '' then
        select * into v_lot
        from inventory.lots
        where tenant_id = p_tenant_id
          and product_id = v_product_id
          and lot_code_normalized = lower(trim(v_lot_code));
        if not found then
          if v_qty_delta < 0 then
            perform inventory._raise('LOT_REQUIRED', 'Lô chưa tồn tại khi xuất kho: ' || v_lot_code);
          end if;
          if v_prod.expiry_required and v_expiry_date is null then
            perform inventory._raise('EXPIRY_REQUIRED', 'Sản phẩm ' || v_prod.name || ' bắt buộc hạn dùng.');
          end if;
          insert into inventory.lots (
            tenant_id, product_id, lot_code, lot_code_normalized,
            expiry_date, expiry_precision, manufacture_date, created_by
          ) values (
            p_tenant_id, v_product_id, v_lot_code, lower(trim(v_lot_code)),
            v_expiry_date, v_expiry_precision, v_manufacture_date,
            coalesce(p_created_by, auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid)
          ) returning id into v_lot_id;
          v_lot_key := v_lot_id;
        else
          if v_expiry_date is not null and v_lot.expiry_date is not null and v_lot.expiry_date <> v_expiry_date then
            perform inventory._raise('LOT_ATTRIBUTE_CONFLICT', 'Xung đột hạn dùng cho lô ' || v_lot_code);
          end if;
          v_lot_id := v_lot.id;
          v_lot_key := v_lot.id;
        end if;
      else
        perform inventory._raise('LOT_REQUIRED', 'Sản phẩm ' || v_prod.name || ' yêu cầu thông tin lô.');
      end if;
    end if;

    -- Stock balance check & lock
    insert into inventory.stock_balances (
      tenant_id, warehouse_id, product_id, lot_key,
      physical_quantity, last_ledger_sequence, updated_at
    ) values (
      p_tenant_id, p_warehouse_id, v_product_id, v_lot_key,
      0, 0, now()
    ) on conflict (tenant_id, warehouse_id, product_id, lot_key) do nothing;

    select physical_quantity into v_current_qty
    from inventory.stock_balances
    where tenant_id = p_tenant_id
      and warehouse_id = p_warehouse_id
      and product_id = v_product_id
      and lot_key = v_lot_key
    for update;

    v_after_qty := v_current_qty + v_qty_delta;
    if v_after_qty < 0 then
      perform inventory._raise('INSUFFICIENT_STOCK', 'Tồn kho không đủ cho sản phẩm ' || v_prod.name);
    end if;

    -- Record stock movement
    v_stock_seq := inventory._next_ledger_sequence(p_tenant_id);

    insert into inventory.stock_movements (
      tenant_id, ledger_sequence, warehouse_id, product_id, lot_id,
      intent_type, intent_id, intent_line_id, movement_kind, reason,
      quantity_delta, business_date, created_by
    ) values (
      p_tenant_id, v_stock_seq, p_warehouse_id, v_product_id, v_lot_id,
      p_intent_type, p_intent_id, v_line_id, v_movement_kind, v_reason,
      v_qty_delta, p_business_date,
      coalesce(p_created_by, auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid)
    ) returning id into v_movement_id;

    update inventory.stock_balances
    set physical_quantity = v_after_qty,
        last_ledger_sequence = v_stock_seq,
        updated_at = now()
    where tenant_id = p_tenant_id
      and warehouse_id = p_warehouse_id
      and product_id = v_product_id
      and lot_key = v_lot_key;

    -- Call _value_line for value ledger
    v_val_res := inventory._value_line(
      p_tenant_id,
      v_movement_id,
      v_product_id,
      v_movement_kind,
      v_qty_delta,
      v_unit_cost,
      v_amount_vnd,
      v_source_movement_id,
      p_business_date,
      p_created_by
    );

    v_res_lines := v_res_lines || jsonb_build_object(
      'line_id', v_line_id,
      'movement_id', v_movement_id,
      'value_movement_id', v_val_res->'value_movement_id',
      'unit_cost', v_val_res->'unit_cost',
      'amount_vnd', v_val_res->'amount_vnd',
      'cost_version_id', v_val_res->'cost_version_id',
      'is_provisional', v_val_res->'is_provisional'
    );
    v_res_movement_ids := v_res_movement_ids || to_jsonb(v_movement_id);

    v_stock_changes := v_stock_changes || jsonb_build_object(
      'product_id', v_product_id,
      'product_name', v_prod.name,
      'base_uom', v_base_uom,
      'lot_id', v_lot_id,
      'before', v_current_qty,
      'after', v_after_qty
    );
  end loop;

  return jsonb_build_object(
    'movement_ids', v_res_movement_ids,
    'lines', v_res_lines,
    'stock_changes', v_stock_changes
  );
end;
$$;

revoke all on function inventory._post_movements(uuid, uuid, text, uuid, date, jsonb, uuid) from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- Public RPCs (grant execute to authenticated)
-- ---------------------------------------------------------------------------

create or replace function inventory.get_warehouse_hub_summary(p_tenant_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = inventory, iam, catalog, pg_temp
as $$
declare
  v_actor jsonb;
  v_activated boolean;
begin
  -- 1. Assert actor with inventory.read permission
  v_actor := inventory._assert_actor(p_tenant_id, 'inventory.read');

  -- 2. Activated = exists at least one stock_movement for tenant
  select exists (
    select 1
    from inventory.stock_movements
    where tenant_id = p_tenant_id
  ) into v_activated;

  -- 3. Return summary with activated and problems (problems is null until G5-2)
  return jsonb_build_object(
    'activated', v_activated,
    'problems', null
  );
end;
$$;

grant execute on function inventory.get_warehouse_hub_summary(uuid) to authenticated;


