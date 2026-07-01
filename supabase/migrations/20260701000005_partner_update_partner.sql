-- TH-03 Epic-01/US-03: partner.update_partner RPC.
-- Context: docs/themes/TH-03-partner/Epic-01-partner-profile/US-03/

create or replace function partner.update_partner(
  p_tenant_id uuid,
  p_partner_id uuid,
  p_expected_version integer,
  p_entity_type partner.entity_type,
  p_display_name text,
  p_phone text,
  p_phone_normalized text,
  p_roles partner.partner_role[],
  p_actor_id uuid default auth.uid(),
  p_individual_name text default null,
  p_business_name text default null,
  p_company_name text default null,
  p_email text default null,
  p_email_normalized text default null,
  p_address text default null,
  p_tax_code text default null,
  p_tax_code_normalized text default null,
  p_invoice_name text default null,
  p_invoice_address text default null,
  p_invoice_email text default null,
  p_bank_name text default null,
  p_bank_account_number text default null,
  p_bank_account_holder text default null,
  p_note text default null,
  p_confirm_duplicate boolean default false
)
returns integer
language plpgsql
security definer
set search_path = partner, iam, pg_temp
as $$
declare
  v_current_version integer;
  v_duplicate_count integer;
  v_role partner.partner_role;
  v_existing_role partner.partner_role;
  v_roles_changed boolean := false;
  v_requested_roles partner.partner_role[];
  v_before_roles partner.partner_role[];
  v_before_profile jsonb;
  v_after_profile jsonb;
  v_outbox_payload jsonb;
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  if p_actor_id is null or p_actor_id <> auth.uid() then
    raise exception 'actor mismatch';
  end if;

  if not iam.has_permission(p_tenant_id, 'partner.update') then
    raise exception 'permission denied: partner.update';
  end if;

  if p_roles is null or cardinality(p_roles) = 0 then
    raise exception 'at least one partner role is required';
  end if;

  if length(btrim(coalesce(p_display_name, ''))) = 0 then
    raise exception 'display_name is required';
  end if;

  if length(btrim(coalesce(p_phone, ''))) = 0
    or length(btrim(coalesce(p_phone_normalized, ''))) = 0 then
    raise exception 'phone is required';
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

  select count(*)
  into v_duplicate_count
  from partner.business_partners bp
  where bp.tenant_id = p_tenant_id
    and bp.id <> p_partner_id
    and (
      bp.phone_normalized = p_phone_normalized
      or (
        p_email_normalized is not null
        and bp.email_normalized = p_email_normalized
      )
      or (
        p_tax_code_normalized is not null
        and bp.tax_code_normalized = p_tax_code_normalized
      )
    );

  if v_duplicate_count > 0 and not p_confirm_duplicate then
    raise exception 'duplicate confirmation required';
  end if;

  select coalesce(array_agg(distinct requested.role order by requested.role), '{}'::partner.partner_role[])
  into v_requested_roles
  from unnest(p_roles) as requested(role);

  select coalesce(array_agg(bpr.role order by bpr.role), '{}'::partner.partner_role[])
  into v_before_roles
  from partner.business_partner_roles bpr
  where bpr.business_partner_id = p_partner_id
    and bpr.tenant_id = p_tenant_id
    and bpr.is_active = true;

  v_roles_changed := v_before_roles is distinct from v_requested_roles;

  select jsonb_build_object(
    'business_partner_id', bp.id,
    'entity_type', bp.entity_type,
    'display_name', bp.display_name,
    'individual_name', bp.individual_name,
    'business_name', bp.business_name,
    'company_name', bp.company_name,
    'phone', bp.phone,
    'email', bp.email,
    'address', bp.address,
    'tax_code', bp.tax_code,
    'invoice_name', bp.invoice_name,
    'invoice_address', bp.invoice_address,
    'invoice_email', bp.invoice_email,
    'bank_name', bp.bank_name,
    'bank_account_number', bp.bank_account_number,
    'bank_account_holder', bp.bank_account_holder,
    'note', bp.note,
    'roles', v_before_roles
  )
  into v_before_profile
  from partner.business_partners bp
  where bp.id = p_partner_id
    and bp.tenant_id = p_tenant_id;

  for v_existing_role in
    select bpr.role
    from partner.business_partner_roles bpr
    where bpr.business_partner_id = p_partner_id
      and bpr.tenant_id = p_tenant_id
      and bpr.is_active = true
  loop
    if not v_existing_role = any(v_requested_roles) then
      if exists (
        select 1
        from partner.partner_transaction_histories pth
        where pth.business_partner_id = p_partner_id
          and pth.tenant_id = p_tenant_id
          and pth.transaction_role = case v_existing_role
            when 'customer'::partner.partner_role then 'customer'::partner.partner_transaction_role
            when 'supplier'::partner.partner_role then 'supplier'::partner.partner_transaction_role
          end
      ) then
        raise exception 'cannot remove role with transaction history: %', v_existing_role;
      end if;

      delete from partner.business_partner_roles bpr
      where bpr.business_partner_id = p_partner_id
        and bpr.role = v_existing_role;
    end if;
  end loop;

  foreach v_role in array v_requested_roles loop
    insert into partner.business_partner_roles (
      tenant_id,
      business_partner_id,
      role,
      is_active
    )
    values (
      p_tenant_id,
      p_partner_id,
      v_role,
      true
    )
    on conflict (business_partner_id, role)
    do update set is_active = true;
  end loop;

  update partner.business_partners bp
  set
    entity_type = p_entity_type,
    display_name = btrim(p_display_name),
    individual_name = nullif(btrim(coalesce(p_individual_name, '')), ''),
    business_name = nullif(btrim(coalesce(p_business_name, '')), ''),
    company_name = nullif(btrim(coalesce(p_company_name, '')), ''),
    phone = btrim(p_phone),
    phone_normalized = btrim(p_phone_normalized),
    email = nullif(btrim(coalesce(p_email, '')), ''),
    email_normalized = nullif(btrim(coalesce(p_email_normalized, '')), ''),
    address = nullif(btrim(coalesce(p_address, '')), ''),
    tax_code = nullif(btrim(coalesce(p_tax_code, '')), ''),
    tax_code_normalized = nullif(btrim(coalesce(p_tax_code_normalized, '')), ''),
    invoice_name = nullif(btrim(coalesce(p_invoice_name, '')), ''),
    invoice_address = nullif(btrim(coalesce(p_invoice_address, '')), ''),
    invoice_email = nullif(btrim(coalesce(p_invoice_email, '')), ''),
    bank_name = nullif(btrim(coalesce(p_bank_name, '')), ''),
    bank_account_number = nullif(btrim(coalesce(p_bank_account_number, '')), ''),
    bank_account_holder = nullif(btrim(coalesce(p_bank_account_holder, '')), ''),
    note = nullif(btrim(coalesce(p_note, '')), ''),
    updated_by = p_actor_id
  where bp.id = p_partner_id
    and bp.tenant_id = p_tenant_id
    and bp.version = p_expected_version;

  if not found then
    raise exception 'version conflict';
  end if;

  select bp.version
  into v_current_version
  from partner.business_partners bp
  where bp.id = p_partner_id;

  select jsonb_build_object(
    'business_partner_id', bp.id,
    'entity_type', bp.entity_type,
    'display_name', bp.display_name,
    'individual_name', bp.individual_name,
    'business_name', bp.business_name,
    'company_name', bp.company_name,
    'phone', bp.phone,
    'email', bp.email,
    'address', bp.address,
    'tax_code', bp.tax_code,
    'invoice_name', bp.invoice_name,
    'invoice_address', bp.invoice_address,
    'invoice_email', bp.invoice_email,
    'bank_name', bp.bank_name,
    'bank_account_number', bp.bank_account_number,
    'bank_account_holder', bp.bank_account_holder,
    'note', bp.note,
    'roles', v_requested_roles
  )
  into v_after_profile
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
    'partner_profile_updated',
    null,
    v_before_profile,
    v_after_profile,
    p_actor_id
  );

  v_outbox_payload := jsonb_build_object(
    'business_partner_id', p_partner_id,
    'tenant_id', p_tenant_id,
    'entity_type', p_entity_type,
    'roles', v_requested_roles,
    'display_name', btrim(p_display_name)
  );

  perform partner.enqueue_outbox_message(
    p_tenant_id,
    'partner.partner.profile_updated',
    v_outbox_payload
  );

  if v_roles_changed then
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
      'partner_role_changed',
      'roles',
      jsonb_build_object('roles', v_before_roles),
      jsonb_build_object('roles', v_requested_roles),
      p_actor_id
    );

    perform partner.enqueue_outbox_message(
      p_tenant_id,
      'partner.partner.role_changed',
      v_outbox_payload
    );
  end if;

  return v_current_version;
end;
$$;

revoke all on function partner.update_partner(
  uuid,
  uuid,
  integer,
  partner.entity_type,
  text,
  text,
  text,
  partner.partner_role[],
  uuid,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  boolean
) from public, anon;

grant execute on function partner.update_partner(
  uuid,
  uuid,
  integer,
  partner.entity_type,
  text,
  text,
  text,
  partner.partner_role[],
  uuid,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  boolean
) to authenticated;
