-- Title: inventory core schema and ledger
-- Kind: schema
-- Intent: inventory_core
-- Context: TH-07 / KB-KGV-001..005; PLAN T7-G5-0b
-- Touches: tenant_inventory_settings, ledger_counters, lots, stock_movements, stock_balances, value_movements, approval_cases, _raise, _forbid_ledger_mutation, _lock_tracking_after_movement
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

-- 1. Tenant settings
create table inventory.tenant_inventory_settings (
  tenant_id uuid primary key references iam.tenants (id) on delete cascade,
  activation_status text not null default 'PREPARING' check (activation_status in ('PREPARING', 'ACTIVE')),
  activated_at timestamptz,
  activated_by uuid
);

-- 2. Ledger counters (tenant-monotonic counter)
create table inventory.ledger_counters (
  tenant_id uuid primary key references iam.tenants (id) on delete cascade,
  last_sequence bigint not null default 0
);

-- 3. Lots
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

-- 4. Stock movements (append-only ledger)
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
  movement_kind text not null,
  from_state text check (from_state is null or from_state in ('SELLABLE', 'QUARANTINE', 'DAMAGED', 'EXPIRED', 'DEMO', 'RETURN_PENDING', 'RTV_PENDING')),
  to_state text check (to_state is null or to_state in ('SELLABLE', 'QUARANTINE', 'DAMAGED', 'EXPIRED', 'DEMO', 'RETURN_PENDING', 'RTV_PENDING')),
  valuation_state text not null check (valuation_state in ('PENDING', 'CONFIRMED')),
  quantity_delta numeric not null check (quantity_delta <> 0),
  business_date date not null,
  created_at timestamptz not null default now(),
  created_by uuid not null,
  constraint chk_stock_movements_state_change check (from_state is not null or to_state is not null),
  constraint stock_movements_tenant_sequence_key unique (tenant_id, ledger_sequence)
);

-- 5. Stock balances
create table inventory.stock_balances (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references iam.tenants (id) on delete cascade,
  warehouse_id uuid not null references inventory.warehouses (id) on delete cascade,
  product_id uuid not null references catalog.products (id) on delete cascade,
  stock_state text not null check (stock_state in ('SELLABLE', 'QUARANTINE', 'DAMAGED', 'EXPIRED', 'DEMO', 'RETURN_PENDING', 'RTV_PENDING')),
  valuation_state text not null check (valuation_state in ('PENDING', 'CONFIRMED')),
  lot_key uuid not null,
  physical_quantity numeric not null default 0 check (physical_quantity >= 0),
  last_ledger_sequence bigint not null default 0,
  updated_at timestamptz not null default now(),
  constraint stock_balances_unique_key unique (tenant_id, warehouse_id, product_id, stock_state, valuation_state, lot_key)
);

-- 6. Value movements (append-only ledger)
create table inventory.value_movements (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references iam.tenants (id) on delete cascade,
  ledger_sequence bigint not null,
  warehouse_id uuid not null references inventory.warehouses (id) on delete cascade,
  product_id uuid not null references catalog.products (id) on delete cascade,
  lot_id uuid references inventory.lots (id) on delete set null,
  intent_type text not null,
  intent_id uuid not null,
  intent_line_id uuid,
  movement_kind text not null,
  quantity_basis numeric not null,
  amount_vnd bigint not null,
  business_date date not null,
  created_at timestamptz not null default now(),
  created_by uuid not null
);

-- 7. Approval cases
create table inventory.approval_cases (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references iam.tenants (id) on delete cascade,
  subject_type text not null,
  subject_id uuid not null,
  snapshot jsonb not null,
  requester_id uuid not null,
  submitted_at timestamptz not null default now(),
  status text not null check (status in ('PENDING', 'APPROVED', 'REJECTED', 'SUPERSEDED')),
  decided_by uuid,
  decided_at timestamptz,
  decision_reason text,
  version int not null default 1
);

create unique index approval_cases_tenant_subject_pending_key
  on inventory.approval_cases (tenant_id, subject_type, subject_id)
  where status = 'PENDING';

-- RLS & Revoke
alter table inventory.tenant_inventory_settings enable row level security;
alter table inventory.ledger_counters enable row level security;
alter table inventory.lots enable row level security;
alter table inventory.stock_movements enable row level security;
alter table inventory.stock_balances enable row level security;
alter table inventory.value_movements enable row level security;
alter table inventory.approval_cases enable row level security;

revoke all on inventory.tenant_inventory_settings from public, anon, authenticated;
revoke all on inventory.ledger_counters from public, anon, authenticated;
revoke all on inventory.lots from public, anon, authenticated;
revoke all on inventory.stock_movements from public, anon, authenticated;
revoke all on inventory.stock_balances from public, anon, authenticated;
revoke all on inventory.value_movements from public, anon, authenticated;
revoke all on inventory.approval_cases from public, anon, authenticated;

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
