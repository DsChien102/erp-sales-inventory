-- Title: iam switch tenant context (S2 / EP-05 US-02)
-- Kind: patch
-- Intent: iam_switch_tenant_context
-- Touches: iam.switch_tenant_context
-- Notes: Draft only — do not apply via supabase migration up until promoted.
--        Re-validates membership + tenant lifecycle at switch time.
--        Raises TENANT_ACCESS_DENIED / TENANT_SUSPENDED / TENANT_CLOSED.

create or replace function iam.switch_tenant_context(p_target_tenant_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_role text;
  v_tenant_name text;
  v_tenant_status text;
  v_permissions text[];
begin
  if v_user_id is null then
    raise exception 'not authenticated';
  end if;

  if p_target_tenant_id is null then
    raise exception 'TENANT_ACCESS_DENIED';
  end if;

  select m.role, t.name, coalesce(t.status, 'active')
  into v_role, v_tenant_name, v_tenant_status
  from iam.memberships m
  join iam.tenants t on t.id = m.tenant_id
  where m.user_id = v_user_id
    and m.tenant_id = p_target_tenant_id;

  if v_role is null then
    raise exception 'TENANT_ACCESS_DENIED';
  end if;

  if v_tenant_status = 'suspended' then
    raise exception 'TENANT_SUSPENDED';
  end if;

  if v_tenant_status = 'closed' then
    raise exception 'TENANT_CLOSED';
  end if;

  if v_role = 'owner' then
    v_permissions := array[]::text[];
  else
    select coalesce(array_agg(rp.permission order by rp.permission), array[]::text[])
    into v_permissions
    from iam.role_permissions rp
    where rp.role = v_role;
  end if;

  return jsonb_build_object(
    'status', 'valid',
    'user_id', v_user_id,
    'tenant_id', p_target_tenant_id,
    'tenant_name', v_tenant_name,
    'role', v_role,
    'permissions', to_jsonb(v_permissions),
    'tenant_status', v_tenant_status
  );
end;
$$;

revoke all on function iam.switch_tenant_context(uuid) from public, anon;
grant execute on function iam.switch_tenant_context(uuid) to authenticated;
