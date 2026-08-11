-- IAM minimal foundation: tenants, memberships, role_permissions + session RPCs.
-- Temporary schema — align with SRS / Theme 1 store setup later.

create schema if not exists iam;

create table if not exists iam.tenants (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now()
);

create table if not exists iam.memberships (
  tenant_id uuid not null references iam.tenants (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  role text not null,
  created_at timestamptz not null default now(),
  primary key (tenant_id, user_id)
);

create index if not exists memberships_user_id_idx on iam.memberships (user_id);

create table if not exists iam.role_permissions (
  role text not null,
  permission text not null,
  primary key (role, permission)
);

alter table iam.tenants enable row level security;
alter table iam.memberships enable row level security;
alter table iam.role_permissions enable row level security;

create policy tenants_member_read on iam.tenants
  for select
  to authenticated
  using (
    exists (
      select 1
      from iam.memberships m
      where m.tenant_id = tenants.id
        and m.user_id = auth.uid()
    )
  );

create policy memberships_self_read on iam.memberships
  for select
  to authenticated
  using (user_id = auth.uid());

create policy role_permissions_read on iam.role_permissions
  for select
  to authenticated
  using (true);

create or replace function iam.get_session_context(p_tenant_id uuid default null)
returns jsonb
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_tenant_id uuid;
  v_role text;
  v_permissions text[];
begin
  if v_user_id is null then
    raise exception 'not authenticated';
  end if;

  if p_tenant_id is not null then
    select m.tenant_id, m.role
    into v_tenant_id, v_role
    from iam.memberships m
    where m.user_id = v_user_id
      and m.tenant_id = p_tenant_id;

    if v_tenant_id is null then
      raise exception 'tenant access denied';
    end if;
  else
    select m.tenant_id, m.role
    into v_tenant_id, v_role
    from iam.memberships m
    where m.user_id = v_user_id
    order by m.created_at
    limit 1;

    if v_tenant_id is null then
      return null;
    end if;
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
    'user_id', v_user_id,
    'tenant_id', v_tenant_id,
    'role', v_role,
    'permissions', to_jsonb(v_permissions)
  );
end;
$$;

create or replace function iam.list_user_tenants()
returns table (
  tenant_id uuid,
  name text,
  role text
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

  return query
  select t.id, t.name, m.role
  from iam.memberships m
  join iam.tenants t on t.id = m.tenant_id
  where m.user_id = v_user_id
  order by m.created_at;
end;
$$;

create or replace function iam.has_permission(
  p_tenant_id uuid,
  p_permission text
)
returns boolean
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_role text;
begin
  if v_user_id is null then
    return false;
  end if;

  select m.role
  into v_role
  from iam.memberships m
  where m.user_id = v_user_id
    and m.tenant_id = p_tenant_id;

  if v_role is null then
    return false;
  end if;

  if v_role = 'owner' then
    return true;
  end if;

  return exists (
    select 1
    from iam.role_permissions rp
    where rp.role = v_role
      and rp.permission = p_permission
  );
end;
$$;

revoke all on schema iam from public, anon;
grant usage on schema iam to authenticated;

revoke all on all tables in schema iam from public, anon;
grant select on iam.tenants, iam.memberships, iam.role_permissions to authenticated;

revoke all on function iam.get_session_context(uuid) from public, anon;
revoke all on function iam.list_user_tenants() from public, anon;
revoke all on function iam.has_permission(uuid, text) from public, anon;

grant execute on function iam.get_session_context(uuid) to authenticated;
grant execute on function iam.list_user_tenants() to authenticated;
grant execute on function iam.has_permission(uuid, text) to authenticated;
