-- Title: iam platform users read (S15 / EP-01 US-01)
-- Kind: patch
-- Intent: iam_platform_users_read
-- Touches: iam.search_platform_users, iam.get_platform_user
-- Notes: Draft only — do not apply via supabase migration up until promoted.
--        Identity fields (email/name) read from auth.users; Theme-1 owns status profile.

create table if not exists iam.platform_user_profiles (
  user_id uuid primary key references auth.users (id) on delete cascade,
  status text not null default 'active'
    check (status in ('pending_activation', 'active', 'suspended')),
  email_verified boolean not null default false,
  last_login_at timestamptz,
  created_at timestamptz not null default now()
);

alter table iam.platform_user_profiles enable row level security;

alter table iam.memberships
  add column if not exists is_owner boolean not null default false;

create or replace function iam.search_platform_users(
  p_query text default null,
  p_status text default null
)
returns table (
  user_id uuid,
  full_name text,
  email text,
  status text,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = iam, auth, pg_temp
as $$
begin
  if not iam.has_platform_permission('platform.user.view') then
    raise exception 'platform permission denied';
  end if;

  return query
  select
    u.id,
    coalesce(
      nullif(trim(concat_ws(' ', u.raw_user_meta_data->>'last_name', u.raw_user_meta_data->>'first_name')), ''),
      coalesce(u.email, u.id::text)
    ) as full_name,
    coalesce(u.email, '') as email,
    coalesce(p.status, 'active') as status,
    coalesce(p.created_at, u.created_at) as created_at
  from auth.users u
  left join iam.platform_user_profiles p on p.user_id = u.id
  where (p_status is null or coalesce(p.status, 'active') = p_status)
    and (
      p_query is null
      or p_query = ''
      or u.email ilike '%' || p_query || '%'
      or coalesce(u.raw_user_meta_data->>'first_name', '') ilike '%' || p_query || '%'
      or coalesce(u.raw_user_meta_data->>'last_name', '') ilike '%' || p_query || '%'
    )
  order by coalesce(p.created_at, u.created_at) desc;
end;
$$;

create or replace function iam.get_platform_user(p_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = iam, auth, pg_temp
as $$
declare
  v_row record;
  v_memberships jsonb;
begin
  if not iam.has_platform_permission('platform.user.view') then
    raise exception 'platform permission denied';
  end if;

  select
    u.id as user_id,
    coalesce(
      nullif(trim(concat_ws(' ', u.raw_user_meta_data->>'last_name', u.raw_user_meta_data->>'first_name')), ''),
      coalesce(u.email, u.id::text)
    ) as full_name,
    coalesce(u.email, '') as email,
    coalesce(p.status, 'active') as status,
    coalesce(p.email_verified, coalesce(u.email_confirmed_at is not null, false)) as email_verified,
    coalesce(p.created_at, u.created_at) as created_at,
    p.last_login_at
  into v_row
  from auth.users u
  left join iam.platform_user_profiles p on p.user_id = u.id
  where u.id = p_user_id;

  if v_row.user_id is null then
    raise exception 'platform user not found';
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'tenant_id', t.id,
        'tenant_name', t.name,
        'role', m.role,
        'is_owner', m.is_owner
      )
      order by m.created_at
    ),
    '[]'::jsonb
  )
  into v_memberships
  from iam.memberships m
  join iam.tenants t on t.id = m.tenant_id
  where m.user_id = p_user_id;

  return jsonb_build_object(
    'user_id', v_row.user_id,
    'full_name', v_row.full_name,
    'email', v_row.email,
    'status', v_row.status,
    'email_verified', v_row.email_verified,
    'created_at', v_row.created_at,
    'last_login_at', v_row.last_login_at,
    'memberships', v_memberships
  );
end;
$$;

revoke all on function iam.search_platform_users(text, text) from public, anon;
revoke all on function iam.get_platform_user(uuid) from public, anon;
grant execute on function iam.search_platform_users(text, text) to authenticated;
grant execute on function iam.get_platform_user(uuid) to authenticated;

revoke all on table iam.platform_user_profiles from public, anon, authenticated;
grant select on table iam.platform_user_profiles to authenticated;
