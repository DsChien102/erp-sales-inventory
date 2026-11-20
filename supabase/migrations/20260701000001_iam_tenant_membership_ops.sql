-- IAM tenant membership operations (interim — align SRS Theme 1 later).

create or replace function iam.list_tenant_members(p_tenant_id uuid)
returns table (
  user_id uuid,
  role text,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'not authenticated';
  end if;

  if not exists (
    select 1
    from iam.memberships m
    where m.user_id = v_user_id
      and m.tenant_id = p_tenant_id
  ) then
    raise exception 'tenant access denied';
  end if;

  return query
  select m.user_id, m.role, m.created_at
  from iam.memberships m
  where m.tenant_id = p_tenant_id
  order by m.created_at;
end;
$$;

create or replace function iam.assign_member_role(
  p_tenant_id uuid,
  p_user_id uuid,
  p_role text
)
returns void
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare
  v_caller_id uuid := auth.uid();
  v_caller_role text;
begin
  if v_caller_id is null then
    raise exception 'not authenticated';
  end if;

  select m.role
  into v_caller_role
  from iam.memberships m
  where m.user_id = v_caller_id
    and m.tenant_id = p_tenant_id;

  if v_caller_role is null then
    raise exception 'tenant access denied';
  end if;

  if v_caller_role <> 'owner' then
    raise exception 'permission denied';
  end if;

  if p_role not in ('owner', 'staff') then
    raise exception 'invalid role';
  end if;

  update iam.memberships
  set role = p_role
  where tenant_id = p_tenant_id
    and user_id = p_user_id;

  if not found then
    raise exception 'membership not found';
  end if;
end;
$$;

revoke all on function iam.list_tenant_members(uuid) from public, anon;
revoke all on function iam.assign_member_role(uuid, uuid, text) from public, anon;

grant execute on function iam.list_tenant_members(uuid) to authenticated;
grant execute on function iam.assign_member_role(uuid, uuid, text) to authenticated;
