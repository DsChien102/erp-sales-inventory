-- Title: Sales schema — E-Invoice dev acceptance source orders and access gate
-- Kind: patch
-- Intent: sales_einvoice_dev_acceptance_source
-- Context: TH-08 dev live acceptance harness fixture (sales-owned)
-- Touches: sales.einvoice_acceptance_orders, sales.get_einvoice_source_snapshot, sales.can_access_sales_order
-- Safety: idempotent (create if not exists), RLS enabled, tenant_id scoped
-- Depends on: 001_einvoice_configuration_schema.sql

create schema if not exists sales;

create table if not exists sales.einvoice_acceptance_orders (
  id uuid not null default gen_random_uuid(),
  tenant_id uuid not null,
  order_code text not null,
  source_version bigint not null default 1,
  status text not null default 'COMPLETED' check (status in ('COMPLETED', 'DRAFT', 'CANCELLED')),
  buyer_partner_id uuid not null,
  buyer_snapshot jsonb not null default '{}'::jsonb,
  commercial_snapshot jsonb not null default '{}'::jsonb,
  created_by_actor_id uuid not null,
  updated_by_actor_id uuid not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (tenant_id, id)
);

alter table sales.einvoice_acceptance_orders enable row level security;
revoke all on sales.einvoice_acceptance_orders from public, anon, authenticated;

create or replace function sales.get_einvoice_source_snapshot(
  p_tenant_id uuid,
  p_sales_order_id uuid
) returns table (
  available boolean,
  source_version text,
  order_completed boolean,
  buyer_partner_id uuid,
  commercial_snapshot jsonb,
  buyer_snapshot jsonb,
  blockers jsonb
)
language plpgsql
security definer
set search_path = sales, public
as $$
declare
  v_order record;
begin
  select *
  into v_order
  from sales.einvoice_acceptance_orders
  where tenant_id = p_tenant_id
    and id = p_sales_order_id;

  if not found then
    return query select
      false as available,
      null::text as source_version,
      false as order_completed,
      null::uuid as buyer_partner_id,
      '{}'::jsonb as commercial_snapshot,
      '{}'::jsonb as buyer_snapshot,
      jsonb_build_array('ORDER_NOT_FOUND') as blockers;
    return;
  end if;

  if v_order.status <> 'COMPLETED' then
    return query select
      true as available,
      v_order.source_version::text as source_version,
      false as order_completed,
      v_order.buyer_partner_id as buyer_partner_id,
      v_order.commercial_snapshot as commercial_snapshot,
      v_order.buyer_snapshot as buyer_snapshot,
      jsonb_build_array('ORDER_NOT_COMPLETED') as blockers;
    return;
  end if;

  return query select
    true as available,
    v_order.source_version::text as source_version,
    true as order_completed,
    v_order.buyer_partner_id as buyer_partner_id,
    v_order.commercial_snapshot as commercial_snapshot,
    v_order.buyer_snapshot as buyer_snapshot,
    '[]'::jsonb as blockers;
end;
$$;

revoke all on function sales.get_einvoice_source_snapshot(uuid, uuid) from public, anon, authenticated;
grant execute on function sales.get_einvoice_source_snapshot(uuid, uuid) to service_role;

create or replace function sales.can_access_sales_order(
  p_tenant_id uuid,
  p_actor_id uuid,
  p_sales_order_id uuid
) returns boolean
language plpgsql
security definer
set search_path = sales, iam, public
as $$
declare
  v_user_id uuid := auth.uid();
  v_has_membership boolean;
  v_order_exists boolean;
begin
  if v_user_id is null or v_user_id <> p_actor_id then
    return false;
  end if;

  select exists (
    select 1
    from iam.memberships
    where tenant_id = p_tenant_id
      and user_id = p_actor_id
      and status = 'active'
  ) into v_has_membership;

  if not v_has_membership then
    return false;
  end if;

  select exists (
    select 1
    from sales.einvoice_acceptance_orders
    where tenant_id = p_tenant_id
      and id = p_sales_order_id
  ) into v_order_exists;

  return v_order_exists;
end;
$$;

revoke all on function sales.can_access_sales_order(uuid, uuid, uuid) from public, anon;
grant execute on function sales.can_access_sales_order(uuid, uuid, uuid) to authenticated, service_role;
