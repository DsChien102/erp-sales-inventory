-- Partner transaction history read: TH-03 Epic-03/US-01 list + filter RPC.
-- Context: TH-03/Epic-03/US-01; docs/themes/TH-03-partner/harness/*
-- Safety: idempotent ; low lock impact on existing partner schema

create or replace view partner.v_partner_transaction_history as
select
  pth.id,
  pth.tenant_id,
  pth.business_partner_id,
  pth.transaction_role,
  pth.source_module,
  pth.source_type,
  pth.source_id,
  pth.source_code,
  pth.transaction_date,
  pth.amount,
  pth.status,
  pth.description,
  pth.created_at
from partner.partner_transaction_histories pth;

comment on view partner.v_partner_transaction_history is
'Read projection for Epic-03/US-01 partner transaction history lookup.';

create or replace function partner.get_partner_transaction_history(
  p_tenant_id uuid,
  p_partner_id uuid,
  p_keyword text default null,
  p_transaction_types text[] default null,
  p_transaction_role partner.partner_transaction_role default null,
  p_from timestamptz default null,
  p_to timestamptz default null,
  p_limit integer default 100,
  p_offset integer default 0
)
returns table (
  id uuid,
  tenant_id uuid,
  business_partner_id uuid,
  transaction_role partner.partner_transaction_role,
  source_module text,
  source_type text,
  source_id uuid,
  source_code text,
  transaction_date timestamptz,
  amount numeric(18,2),
  status text,
  description text,
  created_at timestamptz,
  total_count bigint
)
language plpgsql
security definer
set search_path = partner, iam, pg_temp
as $$
declare
  v_keyword text;
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  if not iam.has_permission(p_tenant_id, 'partner.view_transaction_history') then
    raise exception 'permission denied: partner.view_transaction_history';
  end if;

  if not exists (
    select 1
    from partner.business_partners bp
    where bp.id = p_partner_id
      and bp.tenant_id = p_tenant_id
  ) then
    raise exception 'partner not found';
  end if;

  v_keyword := nullif(btrim(coalesce(p_keyword, '')), '');

  return query
  with filtered as (
    select
      vth.id,
      vth.tenant_id,
      vth.business_partner_id,
      vth.transaction_role,
      vth.source_module,
      vth.source_type,
      vth.source_id,
      vth.source_code,
      vth.transaction_date,
      vth.amount,
      vth.status,
      vth.description,
      vth.created_at
    from partner.v_partner_transaction_history vth
    where vth.tenant_id = p_tenant_id
      and vth.business_partner_id = p_partner_id
      and (
        p_transaction_types is null
        or cardinality(p_transaction_types) = 0
        or vth.source_type = any (p_transaction_types)
      )
      and (
        p_transaction_role is null
        or vth.transaction_role = p_transaction_role
      )
      and (
        p_from is null
        or vth.transaction_date >= p_from
      )
      and (
        p_to is null
        or vth.transaction_date <= p_to
      )
      and (
        v_keyword is null
        or vth.source_code ilike '%' || v_keyword || '%'
        or vth.description ilike '%' || v_keyword || '%'
      )
  )
  select
    filtered.id,
    filtered.tenant_id,
    filtered.business_partner_id,
    filtered.transaction_role,
    filtered.source_module,
    filtered.source_type,
    filtered.source_id,
    filtered.source_code,
    filtered.transaction_date,
    filtered.amount,
    filtered.status,
    filtered.description,
    filtered.created_at,
    count(*) over () as total_count
  from filtered
  order by filtered.transaction_date desc, filtered.created_at desc
  limit greatest(p_limit, 0)
  offset greatest(p_offset, 0);
end;
$$;

revoke all on function partner.get_partner_transaction_history(
  uuid,
  uuid,
  text,
  text[],
  partner.partner_transaction_role,
  timestamptz,
  timestamptz,
  integer,
  integer
) from public, anon;

grant execute on function partner.get_partner_transaction_history(
  uuid,
  uuid,
  text,
  text[],
  partner.partner_transaction_role,
  timestamptz,
  timestamptz,
  integer,
  integer
) to authenticated;
