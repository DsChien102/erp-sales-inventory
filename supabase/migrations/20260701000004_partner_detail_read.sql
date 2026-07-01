-- TH-03 Epic-01/US-04: partner detail read model + get_partner_detail RPC.
-- Context: docs/themes/TH-03-partner/Epic-01-partner-profile/US-04/

create or replace view partner.v_partner_detail as
select
  bp.id,
  bp.tenant_id,
  bp.display_name,
  bp.entity_type,
  bp.individual_name,
  bp.business_name,
  bp.company_name,
  bp.phone,
  bp.email,
  bp.address,
  bp.tax_code,
  bp.invoice_name,
  bp.invoice_address,
  bp.invoice_email,
  bp.bank_name,
  bp.bank_account_number,
  bp.bank_account_holder,
  bp.note,
  bp.status,
  bp.created_by,
  bp.created_at,
  bp.updated_by,
  bp.updated_at,
  bp.version,
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

comment on view partner.v_partner_detail is
'Full partner profile projection for Epic-01/US-04 detail view.';

create or replace function partner.get_partner_detail(
  p_tenant_id uuid,
  p_partner_id uuid
)
returns table (
  id uuid,
  tenant_id uuid,
  display_name text,
  entity_type partner.entity_type,
  individual_name text,
  business_name text,
  company_name text,
  phone text,
  email text,
  address text,
  tax_code text,
  invoice_name text,
  invoice_address text,
  invoice_email text,
  bank_name text,
  bank_account_number text,
  bank_account_holder text,
  note text,
  status partner.partner_status,
  created_by uuid,
  created_at timestamptz,
  updated_by uuid,
  updated_at timestamptz,
  version integer,
  has_customer_role boolean,
  has_supplier_role boolean
)
language plpgsql
security definer
set search_path = partner, iam, pg_temp
as $$
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  if not iam.has_permission(p_tenant_id, 'partner.view_detail') then
    raise exception 'permission denied: partner.view_detail';
  end if;

  return query
  select
    vpd.id,
    vpd.tenant_id,
    vpd.display_name,
    vpd.entity_type,
    vpd.individual_name,
    vpd.business_name,
    vpd.company_name,
    vpd.phone,
    vpd.email,
    vpd.address,
    vpd.tax_code,
    vpd.invoice_name,
    vpd.invoice_address,
    vpd.invoice_email,
    vpd.bank_name,
    vpd.bank_account_number,
    vpd.bank_account_holder,
    vpd.note,
    vpd.status,
    vpd.created_by,
    vpd.created_at,
    vpd.updated_by,
    vpd.updated_at,
    vpd.version,
    vpd.has_customer_role,
    vpd.has_supplier_role
  from partner.v_partner_detail vpd
  where vpd.tenant_id = p_tenant_id
    and vpd.id = p_partner_id;
end;
$$;

revoke all on function partner.get_partner_detail(uuid, uuid) from public, anon;
grant execute on function partner.get_partner_detail(uuid, uuid) to authenticated;
