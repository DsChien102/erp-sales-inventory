-- Fix partner.check_duplicate: ORDER BY after UNION ALL must use subquery aliases.
-- Error: 0A000 invalid UNION/INTERSECT/EXCEPT ORDER BY clause

create or replace function partner.check_duplicate(
  p_tenant_id uuid,
  p_phone_normalized text default null,
  p_email_normalized text default null,
  p_tax_code_normalized text default null
)
returns table (
  duplicate_field text,
  business_partner_id uuid,
  display_name text,
  matched_value text
)
language plpgsql
security definer
set search_path = partner, iam, pg_temp
as $$
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  if not iam.has_permission(p_tenant_id, 'partner.create') then
    raise exception 'permission denied: partner.create';
  end if;

  return query
  select
    d.duplicate_field,
    d.business_partner_id,
    d.display_name,
    d.matched_value
  from (
    select
      'phone'::text as duplicate_field,
      bp.id as business_partner_id,
      bp.display_name as display_name,
      bp.phone as matched_value
    from partner.business_partners bp
    where bp.tenant_id = p_tenant_id
      and p_phone_normalized is not null
      and bp.phone_normalized = p_phone_normalized

    union all

    select
      'email'::text as duplicate_field,
      bp.id as business_partner_id,
      bp.display_name as display_name,
      bp.email as matched_value
    from partner.business_partners bp
    where bp.tenant_id = p_tenant_id
      and p_email_normalized is not null
      and bp.email_normalized = p_email_normalized

    union all

    select
      'tax_code'::text as duplicate_field,
      bp.id as business_partner_id,
      bp.display_name as display_name,
      bp.tax_code as matched_value
    from partner.business_partners bp
    where bp.tenant_id = p_tenant_id
      and p_tax_code_normalized is not null
      and bp.tax_code_normalized = p_tax_code_normalized
  ) d
  order by d.duplicate_field, d.display_name;
end;
$$;
