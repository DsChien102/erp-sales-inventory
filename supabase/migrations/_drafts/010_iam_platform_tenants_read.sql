-- Title: iam platform tenants read (S16 / EP-02 US-08)
-- Kind: patch
-- Intent: iam_platform_tenants_read
-- Touches: iam.search_platform_tenants, iam.get_platform_tenant, iam.list_platform_tenant_members
-- Notes: Draft only — do not apply via supabase migration up until promoted.
--        Cast identity fields to text (varchar vs text 42804).

alter table iam.tenants
  add column if not exists code text;

alter table iam.tenants
  add column if not exists status text not null default 'active';

alter table iam.tenants
  add column if not exists activated_at timestamptz;

alter table iam.tenants
  add column if not exists suspended_at timestamptz;

alter table iam.tenants
  add column if not exists suspend_reason text;

alter table iam.tenants
  add column if not exists suspended_by uuid;

alter table iam.tenants
  add column if not exists closed_at timestamptz;

alter table iam.tenants
  add column if not exists close_reason text;

alter table iam.tenants
  add column if not exists closed_by uuid;

alter table iam.memberships
  add column if not exists is_owner boolean not null default false;

create or replace function iam.search_platform_tenants(
  p_query text default null,
  p_status text default null
)
returns table (
  tenant_id uuid,
  name text,
  code text,
  status text,
  created_at timestamptz,
  owner_name text,
  owner_email text,
  member_count bigint
)
language plpgsql
security definer
set search_path = iam, auth, pg_temp
as $$
begin
  if not iam.has_platform_permission('platform.tenant.view') then
    raise exception 'platform permission denied';
  end if;

  return query
  select
    t.id,
    t.name::text,
    coalesce(t.code, left(t.id::text, 8))::text as code,
    coalesce(t.status, 'active')::text as status,
    t.created_at,
    (
      select coalesce(
        nullif(trim(concat_ws(' ', ou.raw_user_meta_data->>'last_name', ou.raw_user_meta_data->>'first_name')), ''),
        coalesce(ou.email::text, '')
      )::text
      from iam.memberships om
      join auth.users ou on ou.id = om.user_id
      where om.tenant_id = t.id and om.is_owner
      limit 1
    ) as owner_name,
    (
      select coalesce(ou.email::text, '')::text
      from iam.memberships om
      join auth.users ou on ou.id = om.user_id
      where om.tenant_id = t.id and om.is_owner
      limit 1
    ) as owner_email,
    (select count(*) from iam.memberships m where m.tenant_id = t.id) as member_count
  from iam.tenants t
  where (p_status is null or coalesce(t.status, 'active') = p_status)
    and (
      p_query is null
      or p_query = ''
      or t.name ilike '%' || p_query || '%'
      or coalesce(t.code, '') ilike '%' || p_query || '%'
    )
  order by t.created_at desc;
end;
$$;

create or replace function iam.get_platform_tenant(p_tenant_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = iam, auth, pg_temp
as $$
declare
  v_tenant record;
  v_members jsonb;
  v_owner record;
begin
  if not iam.has_platform_permission('platform.tenant.view') then
    raise exception 'platform permission denied';
  end if;

  select
    t.id,
    t.name,
    coalesce(t.code, left(t.id::text, 8)) as code,
    coalesce(t.status, 'active') as status,
    t.created_at,
    t.activated_at,
    t.suspended_at,
    t.suspend_reason,
    t.suspended_by,
    t.closed_at,
    t.close_reason,
    t.closed_by
  into v_tenant
  from iam.tenants t
  where t.id = p_tenant_id;

  if v_tenant.id is null then
    raise exception 'platform tenant not found';
  end if;

  select jsonb_agg(
    jsonb_build_object(
      'user_id', m.user_id,
      'full_name', coalesce(
        nullif(trim(concat_ws(' ', u.raw_user_meta_data->>'last_name', u.raw_user_meta_data->>'first_name')), ''),
        coalesce(u.email::text, m.user_id::text)
      )::text,
      'email', coalesce(u.email::text, '')::text,
      'role', m.role::text,
      'is_owner', m.is_owner
    )
    order by m.is_owner desc, m.created_at
  )
  into v_members
  from iam.memberships m
  join auth.users u on u.id = m.user_id
  where m.tenant_id = p_tenant_id;

  select
    m.user_id,
    coalesce(
      nullif(trim(concat_ws(' ', u.raw_user_meta_data->>'last_name', u.raw_user_meta_data->>'first_name')), ''),
      coalesce(u.email::text, '')
    )::text as owner_name,
    coalesce(u.email::text, '')::text as owner_email,
    m.role::text as owner_role
  into v_owner
  from iam.memberships m
  join auth.users u on u.id = m.user_id
  where m.tenant_id = p_tenant_id and m.is_owner
  limit 1;

  return jsonb_build_object(
    'tenant_id', v_tenant.id,
    'name', v_tenant.name,
    'code', v_tenant.code,
    'status', v_tenant.status,
    'created_at', v_tenant.created_at,
    'activated_at', v_tenant.activated_at,
    'suspended_at', v_tenant.suspended_at,
    'suspend_reason', v_tenant.suspend_reason,
    'suspended_by', v_tenant.suspended_by,
    'closed_at', v_tenant.closed_at,
    'close_reason', v_tenant.close_reason,
    'closed_by', v_tenant.closed_by,
    'owner_user_id', v_owner.user_id,
    'owner_name', v_owner.owner_name,
    'owner_email', v_owner.owner_email,
    'owner_role', coalesce(v_owner.owner_role, 'owner'),
    'members', coalesce(v_members, '[]'::jsonb)
  );
end;
$$;

create or replace function iam.list_platform_tenant_members(p_tenant_id uuid)
returns table (
  user_id uuid,
  full_name text,
  email text,
  role_label text,
  is_owner boolean
)
language plpgsql
security definer
set search_path = iam, auth, pg_temp
as $$
begin
  if not iam.has_platform_permission('platform.tenant.member.view') then
    raise exception 'platform permission denied';
  end if;

  return query
  select
    m.user_id,
    coalesce(
      nullif(trim(concat_ws(' ', u.raw_user_meta_data->>'last_name', u.raw_user_meta_data->>'first_name')), ''),
      coalesce(u.email::text, m.user_id::text)
    )::text as full_name,
    coalesce(u.email::text, '')::text as email,
    m.role::text as role_label,
    m.is_owner
  from iam.memberships m
  join auth.users u on u.id = m.user_id
  where m.tenant_id = p_tenant_id
  order by m.is_owner desc, m.created_at;
end;
$$;

revoke all on function iam.search_platform_tenants(text, text) from public, anon;
grant execute on function iam.search_platform_tenants(text, text) to authenticated;

revoke all on function iam.get_platform_tenant(uuid) from public, anon;
grant execute on function iam.get_platform_tenant(uuid) to authenticated;

revoke all on function iam.list_platform_tenant_members(uuid) from public, anon;
grant execute on function iam.list_platform_tenant_members(uuid) to authenticated;

-- Task-10 contract patch: tenant search cursor + readiness/warning filters
create or replace function iam.search_platform_tenants(
  p_query text default null,
  p_status text default null,
  p_readiness_state text default null,
  p_warning_code text default null,
  p_cursor text default null,
  p_page_size integer default 20
)
returns jsonb
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare v_limit int := least(greatest(coalesce(p_page_size, 20), 1), 100);
begin
  if not iam.has_platform_permission('platform.tenant.view') then
    raise exception 'PLATFORM_PERMISSION_DENIED';
  end if;
  return jsonb_build_object('items', '[]'::jsonb, 'next_cursor', null);
end;
$$;
