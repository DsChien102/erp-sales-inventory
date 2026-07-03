-- Partner transaction history projection upsert (Epic-03 ingest path).
-- Context: TH-03/Epic-03/US-01 inbox projection
-- Safety: idempotent via uq_partner_transaction_histories_source

create or replace function partner.upsert_transaction_history(
  p_tenant_id uuid,
  p_business_partner_id uuid,
  p_transaction_role partner.partner_transaction_role,
  p_source_module text,
  p_source_type text,
  p_source_id uuid,
  p_transaction_date timestamptz,
  p_source_code text default null,
  p_amount numeric(18,2) default null,
  p_status text default null,
  p_description text default null
)
returns uuid
language plpgsql
security definer
set search_path = partner, iam, pg_temp
as $$
declare
  v_id uuid;
begin
  if not exists (
    select 1
    from partner.business_partners bp
    where bp.id = p_business_partner_id
      and bp.tenant_id = p_tenant_id
  ) then
    raise exception 'partner not found';
  end if;

  insert into partner.partner_transaction_histories (
    tenant_id,
    business_partner_id,
    transaction_role,
    source_module,
    source_type,
    source_id,
    source_code,
    transaction_date,
    amount,
    status,
    description
  )
  values (
    p_tenant_id,
    p_business_partner_id,
    p_transaction_role,
    p_source_module,
    p_source_type,
    p_source_id,
    p_source_code,
    p_transaction_date,
    p_amount,
    p_status,
    p_description
  )
  on conflict on constraint uq_partner_transaction_histories_source
  do update set
    source_code = excluded.source_code,
    transaction_date = excluded.transaction_date,
    amount = excluded.amount,
    status = excluded.status,
    description = excluded.description
  returning id into v_id;

  return v_id;
end;
$$;

revoke all on function partner.upsert_transaction_history(
  uuid,
  uuid,
  partner.partner_transaction_role,
  text,
  text,
  uuid,
  timestamptz,
  text,
  numeric,
  text,
  text
) from public, anon, authenticated;

grant execute on function partner.upsert_transaction_history(
  uuid,
  uuid,
  partner.partner_transaction_role,
  text,
  text,
  uuid,
  timestamptz,
  text,
  numeric,
  text,
  text
) to service_role;
