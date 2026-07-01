-- TH-03 Epic-02/US-02: partner delete mutation + detail eligibility read.
-- Context: docs/themes/TH-03-partner/Epic-02-partner-status/US-02/

insert into iam.role_permissions (role, permission)
values
  ('staff', 'partner.delete')
on conflict (role, permission) do nothing;

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
  ) as has_supplier_role,
  exists (
    select 1
    from partner.partner_transaction_histories pth
    where pth.business_partner_id = bp.id
      and pth.tenant_id = bp.tenant_id
  ) as has_business_data
from partner.business_partners bp
left join partner.business_partner_roles bpr
  on bpr.business_partner_id = bp.id
group by bp.id;

-- Postgres cannot OR REPLACE a function when RETURNS TABLE gains a new column.
drop function if exists partner.get_partner_detail(uuid, uuid);

create function partner.get_partner_detail(
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
  has_supplier_role boolean,
  has_business_data boolean
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
    vpd.has_supplier_role,
    vpd.has_business_data
  from partner.v_partner_detail vpd
  where vpd.tenant_id = p_tenant_id
    and vpd.id = p_partner_id;
end;
$$;

create or replace function partner.delete_partner(
  p_tenant_id uuid,
  p_partner_id uuid,
  p_expected_version integer,
  p_actor_id uuid default auth.uid()
)
returns boolean
language plpgsql
security definer
set search_path = partner, iam, pg_temp
as $$
declare
  v_current_version integer;
  v_before_profile jsonb;
  v_outbox_payload jsonb;
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  if p_actor_id is null or p_actor_id <> auth.uid() then
    raise exception 'actor mismatch';
  end if;

  if not iam.has_permission(p_tenant_id, 'partner.delete') then
    raise exception 'permission denied: partner.delete';
  end if;

  select bp.version
  into v_current_version
  from partner.business_partners bp
  where bp.id = p_partner_id
    and bp.tenant_id = p_tenant_id
  for update;

  if v_current_version is null then
    raise exception 'partner not found';
  end if;

  if v_current_version <> p_expected_version then
    raise exception 'version conflict';
  end if;

  if exists (
    select 1
    from partner.partner_transaction_histories pth
    where pth.business_partner_id = p_partner_id
      and pth.tenant_id = p_tenant_id
  ) then
    insert into partner.partner_audit_logs (
      tenant_id,
      business_partner_id,
      action,
      field_name,
      old_value,
      new_value,
      actor_id
    )
    values (
      p_tenant_id,
      p_partner_id,
      'partner_delete_rejected',
      'delete',
      jsonb_build_object('reason', 'partner has transaction history'),
      null,
      p_actor_id
    );

    v_outbox_payload := jsonb_build_object(
      'business_partner_id', p_partner_id,
      'tenant_id', p_tenant_id,
      'reason', 'partner has transaction history'
    );

    perform partner.enqueue_outbox_message(
      p_tenant_id,
      'partner.partner.delete_rejected',
      v_outbox_payload
    );

    raise exception 'partner has transaction history';
  end if;

  select jsonb_build_object(
    'display_name', bp.display_name,
    'status', bp.status,
    'phone', bp.phone,
    'email', bp.email
  )
  into v_before_profile
  from partner.business_partners bp
  where bp.id = p_partner_id
    and bp.tenant_id = p_tenant_id;

  insert into partner.partner_audit_logs (
    tenant_id,
    business_partner_id,
    action,
    field_name,
    old_value,
    new_value,
    actor_id
  )
  values (
    p_tenant_id,
    p_partner_id,
    'partner_deleted',
    'profile',
    v_before_profile,
    null,
    p_actor_id
  );

  v_outbox_payload := jsonb_build_object(
    'business_partner_id', p_partner_id,
    'tenant_id', p_tenant_id
  );

  perform partner.enqueue_outbox_message(
    p_tenant_id,
    'partner.partner.deleted',
    v_outbox_payload
  );

  delete from partner.business_partners bp
  where bp.id = p_partner_id
    and bp.tenant_id = p_tenant_id
    and bp.version = p_expected_version;

  if not found then
    raise exception 'version conflict';
  end if;

  return true;
end;
$$;

revoke all on function partner.get_partner_detail(uuid, uuid) from public, anon;
grant execute on function partner.get_partner_detail(uuid, uuid) to authenticated;

revoke all on function partner.delete_partner(uuid, uuid, integer, uuid) from public, anon;
grant execute on function partner.delete_partner(uuid, uuid, integer, uuid) to authenticated, service_role;
