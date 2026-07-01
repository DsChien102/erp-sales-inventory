-- Partner search read model: TH-03 Epic-01/US-01 list + search RPC.
-- Context: TH-03/Epic-01/US-01; docs/themes/TH-03-partner/harness/*
-- Safety: idempotent ; low lock impact on existing partner schema

create or replace view partner.v_partner_list as
select
  bp.id,
  bp.tenant_id,
  bp.display_name,
  bp.phone,
  bp.phone_normalized,
  bp.email,
  bp.tax_code,
  bp.entity_type,
  bp.status,
  bp.updated_at,
  bp.created_at,
  coalesce(
    bool_or(bpr.role = 'customer' and bpr.is_active),
    false
  ) as has_customer_role,
  coalesce(
    bool_or(bpr.role = 'supplier' and bpr.is_active),
    false
  ) as has_supplier_role
from partner.business_partners bp
left join partner.business_partner_roles bpr
  on bpr.business_partner_id = bp.id
group by bp.id;

comment on view partner.v_partner_list is
'Denormalized partner list projection for Epic-01/US-01 search and filters.';

create or replace function partner.search_partners(
  p_tenant_id uuid,
  p_keyword text default null,
  p_keyword_phone_normalized text default null,
  p_statuses partner.partner_status[] default array['active']::partner.partner_status[],
  p_role_filter text default null,
  p_entity_types partner.entity_type[] default null,
  p_limit integer default 100,
  p_offset integer default 0
)
returns table (
  id uuid,
  tenant_id uuid,
  display_name text,
  phone text,
  email text,
  tax_code text,
  entity_type partner.entity_type,
  status partner.partner_status,
  updated_at timestamptz,
  created_at timestamptz,
  has_customer_role boolean,
  has_supplier_role boolean,
  total_count bigint
)
language plpgsql
security definer
set search_path = partner, iam, pg_temp
as $$
declare
  v_keyword text;
  v_phone_keyword text;
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  if not iam.has_permission(p_tenant_id, 'partner.view') then
    raise exception 'permission denied: partner.view';
  end if;

  v_keyword := nullif(btrim(coalesce(p_keyword, '')), '');
  v_phone_keyword := nullif(btrim(coalesce(p_keyword_phone_normalized, '')), '');

  return query
  with filtered as (
    select
      vpl.id,
      vpl.tenant_id,
      vpl.display_name,
      vpl.phone,
      vpl.email,
      vpl.tax_code,
      vpl.entity_type,
      vpl.status,
      vpl.updated_at,
      vpl.created_at,
      vpl.has_customer_role,
      vpl.has_supplier_role
    from partner.v_partner_list vpl
    where vpl.tenant_id = p_tenant_id
      and (
        p_statuses is null
        or cardinality(p_statuses) = 0
        or vpl.status = any (p_statuses)
      )
      and (
        p_entity_types is null
        or cardinality(p_entity_types) = 0
        or vpl.entity_type = any (p_entity_types)
      )
      and (
        p_role_filter is null
        or (
          p_role_filter = 'customer'
          and vpl.has_customer_role
        )
        or (
          p_role_filter = 'supplier'
          and vpl.has_supplier_role
        )
        or (
          p_role_filter = 'both'
          and vpl.has_customer_role
          and vpl.has_supplier_role
        )
      )
      and (
        (v_keyword is null and v_phone_keyword is null)
        or (
          v_phone_keyword is not null
          and vpl.phone_normalized = v_phone_keyword
        )
        or (
          v_keyword is not null
          and (
            vpl.display_name ilike '%' || v_keyword || '%'
            or vpl.phone ilike '%' || v_keyword || '%'
            or (
              vpl.email is not null
              and vpl.email ilike '%' || v_keyword || '%'
            )
            or (
              vpl.tax_code is not null
              and vpl.tax_code ilike '%' || v_keyword || '%'
            )
          )
        )
      )
  )
  select
    filtered.id,
    filtered.tenant_id,
    filtered.display_name,
    filtered.phone,
    filtered.email,
    filtered.tax_code,
    filtered.entity_type,
    filtered.status,
    filtered.updated_at,
    filtered.created_at,
    filtered.has_customer_role,
    filtered.has_supplier_role,
    count(*) over () as total_count
  from filtered
  order by filtered.updated_at desc, filtered.created_at desc
  limit greatest(p_limit, 0)
  offset greatest(p_offset, 0);
end;
$$;

revoke all on function partner.search_partners(
  uuid,
  text,
  text,
  partner.partner_status[],
  text,
  partner.entity_type[],
  integer,
  integer
) from public, anon;

grant execute on function partner.search_partners(
  uuid,
  text,
  text,
  partner.partner_status[],
  text,
  partner.entity_type[],
  integer,
  integer
) to authenticated;
