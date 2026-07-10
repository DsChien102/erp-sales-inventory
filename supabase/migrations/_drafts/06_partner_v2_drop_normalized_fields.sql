-- Title: Drop partner *_normalized columns and helpers
-- Context: TH-03 — normalized phone/email/tax_code columns no longer used.
--   Duplicate check compares raw profile fields (trim / lower).
-- Safety: Drops indexes then columns; drops helper functions if present;
--   recreates insert helpers without normalized fields.
-- Apply via SQL editor after 05 (or together). Not auto-promoted.

-- Drop indexes that reference normalized columns (names from original schema).
drop index if exists partner.idx_person_profiles_tenant_phone;
drop index if exists partner.idx_person_profiles_tenant_email;
drop index if exists partner.idx_person_profiles_tenant_tax_code;
drop index if exists partner.idx_organization_profiles_tenant_phone;
drop index if exists partner.idx_organization_profiles_tenant_email;
drop index if exists partner.idx_organization_profiles_tenant_tax_code;

alter table partner.person_profiles
  drop column if exists phone_normalized,
  drop column if exists phone2_normalized,
  drop column if exists email_normalized,
  drop column if exists tax_code_normalized;

alter table partner.organization_profiles
  drop column if exists phone_normalized,
  drop column if exists email_normalized,
  drop column if exists tax_code_normalized;

-- Recreate indexes on raw fields.
create index if not exists idx_person_profiles_tenant_phone
  on partner.person_profiles (tenant_id, phone);

create index if not exists idx_person_profiles_tenant_email
  on partner.person_profiles (tenant_id, email)
  where email is not null;

create index if not exists idx_person_profiles_tenant_tax_code
  on partner.person_profiles (tenant_id, tax_code)
  where tax_code is not null;

create index if not exists idx_organization_profiles_tenant_phone
  on partner.organization_profiles (tenant_id, phone);

create index if not exists idx_organization_profiles_tenant_email
  on partner.organization_profiles (tenant_id, email)
  where email is not null;

create index if not exists idx_organization_profiles_tenant_tax_code
  on partner.organization_profiles (tenant_id, tax_code)
  where tax_code is not null;

drop function if exists partner._normalize_phone(text);
drop function if exists partner._normalize_email(text);
drop function if exists partner._normalize_tax_code(text);

-- Insert helpers without normalized columns (same as 05).
create or replace function partner._insert_person_profile(
  p_tenant_id uuid,
  p_partner_id uuid,
  p_profile jsonb
)
returns void
language plpgsql
as $$
declare
  v_phone text;
  v_invoice jsonb;
  v_delivery jsonb;
begin
  v_phone := nullif(btrim(coalesce(p_profile ->> 'phone', '')), '');
  if v_phone is null then
    perform partner._raise_partner_error('VALIDATION_ERROR', 'phone is required');
  end if;

  v_invoice := p_profile -> 'invoice';
  v_delivery := p_profile -> 'delivery';

  insert into partner.person_profiles (
    partner_id, tenant_id, title, full_name, nickname,
    phone, phone2, email, tax_code,
    invoice_name, invoice_address, invoice_email,
    delivery_province, delivery_commune, delivery_address, note
  )
  values (
    p_partner_id,
    p_tenant_id,
    nullif(btrim(coalesce(p_profile ->> 'title', '')), ''),
    btrim(coalesce(p_profile ->> 'full_name', '')),
    nullif(btrim(coalesce(p_profile ->> 'nickname', '')), ''),
    v_phone,
    nullif(btrim(coalesce(p_profile ->> 'phone2', '')), ''),
    nullif(btrim(coalesce(p_profile ->> 'email', '')), ''),
    nullif(btrim(coalesce(p_profile ->> 'tax_code', '')), ''),
    nullif(btrim(coalesce(v_invoice ->> 'name', p_profile ->> 'invoice_name', '')), ''),
    nullif(btrim(coalesce(v_invoice ->> 'address', p_profile ->> 'invoice_address', '')), ''),
    nullif(btrim(coalesce(v_invoice ->> 'email', p_profile ->> 'invoice_email', '')), ''),
    nullif(btrim(coalesce(v_delivery ->> 'province', p_profile ->> 'delivery_province', '')), ''),
    nullif(btrim(coalesce(v_delivery ->> 'commune', p_profile ->> 'delivery_commune', '')), ''),
    nullif(btrim(coalesce(v_delivery ->> 'address', p_profile ->> 'delivery_address', '')), ''),
    nullif(btrim(coalesce(p_profile ->> 'note', '')), '')
  );
end;
$$;

create or replace function partner._insert_organization_profile(
  p_tenant_id uuid,
  p_partner_id uuid,
  p_profile jsonb
)
returns void
language plpgsql
as $$
declare
  v_phone text;
  v_invoice jsonb;
  v_delivery jsonb;
  v_org_type partner.organization_type;
begin
  v_phone := nullif(btrim(coalesce(p_profile ->> 'phone', '')), '');
  if v_phone is null then
    perform partner._raise_partner_error('VALIDATION_ERROR', 'phone is required');
  end if;

  begin
    v_org_type := (p_profile ->> 'organization_type')::partner.organization_type;
  exception
    when others then
      perform partner._raise_partner_error(
        'VALIDATION_ERROR',
        'organization_type is required'
      );
  end;

  v_invoice := p_profile -> 'invoice';
  v_delivery := p_profile -> 'delivery';

  insert into partner.organization_profiles (
    partner_id, tenant_id, organization_type, organization_name,
    short_name, intl_name, phone, email, tax_code, company_address,
    invoice_name, invoice_address, invoice_email,
    delivery_province, delivery_commune, delivery_address, note
  )
  values (
    p_partner_id,
    p_tenant_id,
    v_org_type,
    btrim(coalesce(p_profile ->> 'organization_name', '')),
    nullif(btrim(coalesce(p_profile ->> 'short_name', '')), ''),
    nullif(btrim(coalesce(p_profile ->> 'intl_name', '')), ''),
    v_phone,
    nullif(btrim(coalesce(p_profile ->> 'email', '')), ''),
    nullif(btrim(coalesce(p_profile ->> 'tax_code', '')), ''),
    nullif(btrim(coalesce(p_profile ->> 'company_address', '')), ''),
    nullif(btrim(coalesce(v_invoice ->> 'name', p_profile ->> 'invoice_name', '')), ''),
    nullif(btrim(coalesce(v_invoice ->> 'address', p_profile ->> 'invoice_address', '')), ''),
    nullif(btrim(coalesce(v_invoice ->> 'email', p_profile ->> 'invoice_email', '')), ''),
    nullif(btrim(coalesce(v_delivery ->> 'province', p_profile ->> 'delivery_province', '')), ''),
    nullif(btrim(coalesce(v_delivery ->> 'commune', p_profile ->> 'delivery_commune', '')), ''),
    nullif(btrim(coalesce(v_delivery ->> 'address', p_profile ->> 'delivery_address', '')), ''),
    nullif(btrim(coalesce(p_profile ->> 'note', '')), '')
  );
end;
$$;

-- Duplicate check on raw fields (no normalized columns / helpers).
create or replace function partner.check_duplicate(
  p_tenant_id uuid,
  p_phone text default null,
  p_email text default null,
  p_tax_code text default null,
  p_name text default null,
  p_exclude_partner_id uuid default null
)
returns table (
  partner_id uuid,
  display_name text,
  matched_field text,
  partner_type text,
  matched_value text
)
language plpgsql
stable
security definer
set search_path = partner, iam, pg_temp
as $$
declare
  v_phone text := nullif(btrim(coalesce(p_phone, '')), '');
  v_email text := nullif(lower(btrim(coalesce(p_email, ''))), '');
  v_tax_code text := nullif(btrim(coalesce(p_tax_code, '')), '');
  v_name text := nullif(lower(btrim(coalesce(p_name, ''))), '');
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  if not (
    iam.has_permission(p_tenant_id, 'partner.create')
    or iam.has_permission(p_tenant_id, 'partner.update')
  ) then
    raise exception 'permission denied: partner.create';
  end if;

  return query
  select m.partner_id, m.display_name, m.matched_field, m.partner_type, m.matched_value
  from (
    select
      p.partner_id,
      p.display_name,
      'phone'::text as matched_field,
      p.partner_type::text as partner_type,
      pp.phone as matched_value
    from partner.partners p
    join partner.person_profiles pp on pp.partner_id = p.partner_id
    where p.tenant_id = p_tenant_id
      and p.status <> 'deleted'
      and v_phone is not null
      and btrim(pp.phone) = v_phone
      and (p_exclude_partner_id is null or p.partner_id <> p_exclude_partner_id)
    union all
    select
      p.partner_id,
      p.display_name,
      'phone'::text,
      p.partner_type::text,
      op.phone
    from partner.partners p
    join partner.organization_profiles op on op.partner_id = p.partner_id
    where p.tenant_id = p_tenant_id
      and p.status <> 'deleted'
      and v_phone is not null
      and btrim(op.phone) = v_phone
      and (p_exclude_partner_id is null or p.partner_id <> p_exclude_partner_id)
    union all
    select
      p.partner_id,
      p.display_name,
      'email'::text,
      p.partner_type::text,
      coalesce(pp.email, op.email)
    from partner.partners p
    left join partner.person_profiles pp on pp.partner_id = p.partner_id
    left join partner.organization_profiles op on op.partner_id = p.partner_id
    where p.tenant_id = p_tenant_id
      and p.status <> 'deleted'
      and v_email is not null
      and lower(btrim(coalesce(pp.email, op.email, ''))) = v_email
      and (p_exclude_partner_id is null or p.partner_id <> p_exclude_partner_id)
    union all
    select
      p.partner_id,
      p.display_name,
      'tax_code'::text,
      p.partner_type::text,
      coalesce(pp.tax_code, op.tax_code)
    from partner.partners p
    left join partner.person_profiles pp on pp.partner_id = p.partner_id
    left join partner.organization_profiles op on op.partner_id = p.partner_id
    where p.tenant_id = p_tenant_id
      and p.status <> 'deleted'
      and v_tax_code is not null
      and btrim(coalesce(pp.tax_code, op.tax_code, '')) = v_tax_code
      and (p_exclude_partner_id is null or p.partner_id <> p_exclude_partner_id)
    union all
    select
      p.partner_id,
      p.display_name,
      'name'::text,
      p.partner_type::text,
      p.display_name
    from partner.partners p
    left join partner.person_profiles pp on pp.partner_id = p.partner_id
    left join partner.organization_profiles op on op.partner_id = p.partner_id
    where p.tenant_id = p_tenant_id
      and p.status <> 'deleted'
      and v_name is not null
      and v_phone is not null
      and lower(p.display_name) = v_name
      and btrim(coalesce(pp.phone, op.phone, '')) = v_phone
      and (p_exclude_partner_id is null or p.partner_id <> p_exclude_partner_id)
  ) m
  order by m.matched_field, m.display_name;
end;
$$;
