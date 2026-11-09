-- Title: inventory core schema and ledger
-- Kind: schema
-- Intent: inventory_core
-- Context: TH-07 / KB-KGV-001..005, spec giá vốn; PLAN T7-G5-0b
-- Touches: ledger_counters, lots, stock_movements, stock_balances, cost_policies, cost_periods, cost_versions, value_movements, product_costs, _raise, _forbid_ledger_mutation, _lock_tracking_after_movement
-- Safety: one-shot ; low lock impact on new tables
-- Depends on: 20261104001_inventory_default_pair, 20260709001_catalog_guided_create

create schema if not exists inventory;

create or replace function inventory._raise(p_code text, p_message text)
returns void
language plpgsql
as $$
begin
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
