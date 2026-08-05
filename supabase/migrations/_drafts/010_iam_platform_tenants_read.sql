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
  add column if not exists updated_at timestamptz not null default now();

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

alter table iam.tenants
  add column if not exists version int not null default 1;

alter table iam.memberships
  add column if not exists is_owner boolean not null default false,
  add column if not exists status text not null default 'active';

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
    coalesce(t.version, 1) as version,
    t.created_at,
    t.updated_at,
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
      'full_name', m.full_name,
      'email', m.email,
      'role', m.role::text,
      'role_label', m.role_label,
      'is_owner', m.is_owner
    )
    order by m.is_owner desc, m.created_at
  )
  into v_members
  from (
    select distinct on (m.user_id)
      m.user_id,
      coalesce(
        nullif(trim(concat_ws(' ', u.raw_user_meta_data->>'last_name', u.raw_user_meta_data->>'first_name')), ''),
        coalesce(u.email::text, m.user_id::text)
      )::text as full_name,
      coalesce(u.email::text, '')::text as email,
      m.role,
      coalesce(rd.label, m.role::text) as role_label,
      m.is_owner,
      m.created_at
    from iam.memberships m
    join auth.users u on u.id = m.user_id
    left join iam.role_definitions rd on rd.code = m.role
    where m.tenant_id = p_tenant_id
      and coalesce(m.status, 'active') = 'active'
    order by m.user_id, m.is_owner desc, m.created_at desc
  ) m;

  select
    m.user_id,
    coalesce(
      nullif(trim(concat_ws(' ', u.raw_user_meta_data->>'last_name', u.raw_user_meta_data->>'first_name')), ''),
      coalesce(u.email::text, '')
    )::text as owner_name,
    coalesce(u.email::text, '')::text as owner_email,
    coalesce(rd.label, m.role::text) as owner_role
  into v_owner
  from iam.memberships m
  join auth.users u on u.id = m.user_id
  left join iam.role_definitions rd on rd.code = m.role
  where m.tenant_id = p_tenant_id
    and m.is_owner
    and coalesce(m.status, 'active') = 'active'
  limit 1;

  return jsonb_build_object(
    'tenant_id', v_tenant.id,
    'name', v_tenant.name,
    'code', v_tenant.code,
    'status', v_tenant.status,
    'version', v_tenant.version,
    'created_at', v_tenant.created_at,
    'activated_at', v_tenant.activated_at,
    'last_activity_at', coalesce(v_tenant.updated_at, v_tenant.activated_at, v_tenant.created_at),
    'suspended_at', v_tenant.suspended_at,
    'suspend_reason', v_tenant.suspend_reason,
    'suspended_by', (
      select coalesce(
        nullif(
          trim(concat_ws(' ', u.raw_user_meta_data->>'last_name', u.raw_user_meta_data->>'first_name')),
          ''
        ),
        u.email::text
      )
      from auth.users u
      where u.id = v_tenant.suspended_by
    ),
    'closed_at', v_tenant.closed_at,
    'close_reason', v_tenant.close_reason,
    'closed_by', (
      select coalesce(
        nullif(
          trim(concat_ws(' ', u.raw_user_meta_data->>'last_name', u.raw_user_meta_data->>'first_name')),
          ''
        ),
        u.email::text
      )
      from auth.users u
      where u.id = v_tenant.closed_by
    ),
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
    m.full_name,
    m.email,
    m.role_label,
    m.is_owner
  from (
    select distinct on (m.user_id)
      m.user_id,
      coalesce(
        nullif(trim(concat_ws(' ', u.raw_user_meta_data->>'last_name', u.raw_user_meta_data->>'first_name')), ''),
        coalesce(u.email::text, m.user_id::text)
      )::text as full_name,
      coalesce(u.email::text, '')::text as email,
      m.role,
      coalesce(rd.label, m.role::text) as role_label,
      m.is_owner,
      m.created_at
    from iam.memberships m
    join auth.users u on u.id = m.user_id
    left join iam.role_definitions rd on rd.code = m.role
    where m.tenant_id = p_tenant_id
      and coalesce(m.status, 'active') = 'active'
    order by m.user_id, m.is_owner desc, m.created_at desc
  ) m
  order by m.is_owner desc, m.created_at;
end;
$$;

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
set search_path = iam, auth, pg_temp
as $$
declare
  v_limit int := least(greatest(coalesce(p_page_size, 20), 1), 100);
  v_offset int := case
    when coalesce(p_cursor, '') ~ '^[0-9]+$' then p_cursor::int
    else 0
  end;
  v_items jsonb := '[]'::jsonb;
  v_next_cursor text;
begin
  if not iam.has_platform_permission('platform.tenant.view') then
    raise exception 'PLATFORM_PERMISSION_DENIED';
  end if;

  with filtered as (
    select
      t.id as tenant_id,
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
        where om.tenant_id = t.id
          and om.is_owner
          and coalesce(om.status, 'active') = 'active'
        limit 1
      ) as owner_name,
      (
        select coalesce(ou.email::text, '')::text
        from iam.memberships om
        join auth.users ou on ou.id = om.user_id
        where om.tenant_id = t.id
          and om.is_owner
          and coalesce(om.status, 'active') = 'active'
        limit 1
      ) as owner_email,
      (
        select count(distinct m.user_id)
        from iam.memberships m
        where m.tenant_id = t.id
          and coalesce(m.status, 'active') = 'active'
      ) as member_count,
      null::text as readiness_state,
      null::text as warning_code
    from iam.tenants t
    where (p_status is null or coalesce(t.status, 'active') = p_status)
      and p_readiness_state is null
      and p_warning_code is null
      and (
        p_query is null
        or p_query = ''
        or t.name ilike '%' || p_query || '%'
        or coalesce(t.code, '') ilike '%' || p_query || '%'
      )
  ),
  windowed as (
    select
      filtered.*,
      row_number() over (order by filtered.created_at desc, filtered.tenant_id) as rn
    from filtered
  ),
  page_rows as (
    select *
    from windowed
    where rn > v_offset and rn <= v_offset + v_limit
  )
  select
    coalesce(jsonb_agg(to_jsonb(page_rows) - 'rn' order by page_rows.rn), '[]'::jsonb),
    case
      when exists(select 1 from windowed where rn > v_offset + v_limit)
      then (v_offset + v_limit)::text
      else null
    end
  into v_items, v_next_cursor
  from page_rows;

  return jsonb_build_object('items', v_items, 'next_cursor', v_next_cursor);
end;
$$;

revoke all on function iam.search_platform_tenants(text, text, text, text, text, integer) from public, anon;
grant execute on function iam.search_platform_tenants(text, text, text, text, text, integer) to authenticated;
