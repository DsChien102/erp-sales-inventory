-- TH-03 Epic-01/US-03: fix role-history guard in deployed partner.update_partner RPC.
-- Context: deployed 20260701000005 used an explicit cast from partner.partner_role
-- to partner.partner_transaction_role while checking role removal history.

create or replace function partner.partner_role_to_transaction_role(
  p_role partner.partner_role
)
returns partner.partner_transaction_role
language sql
immutable
strict
set search_path = partner, pg_temp
as $$
  select case p_role
    when 'customer'::partner.partner_role then 'customer'::partner.partner_transaction_role
    when 'supplier'::partner.partner_role then 'supplier'::partner.partner_transaction_role
  end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_cast c
    join pg_type source_type on source_type.oid = c.castsource
    join pg_namespace source_ns on source_ns.oid = source_type.typnamespace
    join pg_type target_type on target_type.oid = c.casttarget
    join pg_namespace target_ns on target_ns.oid = target_type.typnamespace
    where source_ns.nspname = 'partner'
      and source_type.typname = 'partner_role'
      and target_ns.nspname = 'partner'
      and target_type.typname = 'partner_transaction_role'
  ) then
    execute
      'create cast (partner.partner_role as partner.partner_transaction_role) ' ||
      'with function partner.partner_role_to_transaction_role(partner.partner_role)';
  end if;
end;
$$;

revoke all on function partner.partner_role_to_transaction_role(
  partner.partner_role
) from public, anon;

grant execute on function partner.partner_role_to_transaction_role(
  partner.partner_role
) to authenticated;
