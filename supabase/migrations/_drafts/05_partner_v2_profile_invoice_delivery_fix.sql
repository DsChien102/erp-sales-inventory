-- Title: Partner profile invoice/delivery insert fix (no normalized columns)
-- Context: TH-03 S1 — nested+flat invoice/delivery keys; no *_normalized fields.
-- Safety: Idempotent CREATE OR REPLACE; additive column for org delivery_address.
-- Apply via SQL editor on the environment under test (not auto-promoted).

alter table partner.organization_profiles
  add column if not exists delivery_address text null;

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
    partner_id,
    tenant_id,
    title,
    full_name,
    nickname,
    phone,
    phone2,
    email,
    tax_code,
    invoice_name,
    invoice_address,
    invoice_email,
    delivery_province,
    delivery_commune,
    delivery_address,
    note
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
    partner_id,
    tenant_id,
    organization_type,
    organization_name,
    short_name,
    intl_name,
    phone,
    email,
    tax_code,
    company_address,
    invoice_name,
    invoice_address,
    invoice_email,
    delivery_province,
    delivery_commune,
    delivery_address,
    note
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
