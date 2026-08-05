-- Title: iam platform users read (S15 / EP-01 US-01) + self-service profile read (S14)
-- Kind: patch
-- Intent: iam_platform_users_read
-- Touches: iam.search_platform_users, iam.get_platform_user, iam.get_my_platform_user_profile
-- Notes: Draft only — do not apply via supabase migration up until promoted.
--        Identity fields (email/name/status/emailVerified) read from auth.users.
--        S14: iam.platform_user_profiles is the canonical self-service profile table.
--        Login email is NEVER stored here; infrastructure adapter reads it from Supabase Auth.

create table if not exists iam.platform_user_profiles (
  user_id uuid primary key references auth.users (id) on delete cascade,
  status text not null default 'active'
    check (status in ('pending_activation', 'active', 'suspended')),
  email_verified boolean not null default false,
  last_login_at timestamptz,
  created_at timestamptz not null default now()
);

-- S14: extend canonical profile with self-service editable fields (additive).
alter table iam.platform_user_profiles
  add column if not exists given_name text,
  add column if not exists family_middle_name text,
  add column if not exists phone_number text,
  add column if not exists avatar_reference text,
  add column if not exists updated_at timestamptz not null default now();

alter table iam.platform_user_profiles enable row level security;

create or replace function iam._platform_user_effective_status(
  p_email_confirmed_at timestamptz
) returns text
language sql
immutable
as $$
  select case
    when p_email_confirmed_at is not null then 'active'
    else 'pending_activation'
  end;
$$;

-- S14 US-01: self-only profile read. Resolves user from auth.uid();
-- never accepts a user_id parameter and never returns login email.
create or replace function iam.get_my_platform_user_profile()
returns jsonb
language plpgsql
security definer
set search_path = iam, auth, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_row record;
begin
  if v_user_id is null then
    raise exception 'authentication required';
  end if;

  select
    p.user_id,
    p.given_name,
    p.family_middle_name,
    p.phone_number,
    p.avatar_reference,
    coalesce(p.status, 'pending_activation') as status
  into v_row
  from iam.platform_user_profiles p
  where p.user_id = v_user_id;

  if v_row.user_id is null then
    -- Lazily materialise a pending profile row so first read is stable.
    insert into iam.platform_user_profiles (user_id, status, created_at, updated_at)
    values (v_user_id, 'pending_activation', now(), now())
    on conflict (user_id) do nothing;

    return jsonb_build_object(
      'user_id', v_user_id,
      'given_name', null,
      'family_middle_name', null,
      'phone_number', null,
      'avatar_reference', null,
      'status', 'pending_activation'
    );
  end if;

  return jsonb_build_object(
    'user_id', v_row.user_id,
    'given_name', v_row.given_name,
    'family_middle_name', v_row.family_middle_name,
    'phone_number', v_row.phone_number,
    'avatar_reference', v_row.avatar_reference,
    'status', v_row.status
  );
end;
$$;

revoke all on function iam.get_my_platform_user_profile() from public, anon;
grant execute on function iam.get_my_platform_user_profile() to authenticated;

alter table iam.memberships
  add column if not exists is_owner boolean not null default false;

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
      nullif(trim(concat_ws(' ', p.given_name, p.family_middle_name)), ''),
      nullif(trim(concat_ws(' ', u.raw_user_meta_data->>'first_name', u.raw_user_meta_data->>'last_name')), ''),
      ''
    )::text as full_name,
    coalesce(u.email::text, '')::text as email,
    iam._platform_user_effective_status(u.email_confirmed_at)::text as status,
    (u.email_confirmed_at is not null) as email_verified,
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

revoke all on function iam.get_platform_user(uuid) from public, anon;
grant execute on function iam.get_platform_user(uuid) to authenticated;

revoke all on table iam.platform_user_profiles from public, anon, authenticated;
grant select on table iam.platform_user_profiles to authenticated;

-- Task-10 contract patch: cursor page search + profile version
alter table iam.platform_user_profiles
  add column if not exists version int not null default 1;

create or replace function iam.search_platform_users(
  p_query text default null,
  p_status text default null,
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
begin
  if not iam.has_platform_permission('platform.user.view') then
    raise exception 'PLATFORM_PERMISSION_DENIED';
  end if;
  return jsonb_build_object(
    'items', coalesce((
      select jsonb_agg(row_to_json(t)::jsonb)
      from (
        select
          u.id as user_id,
          coalesce(
            nullif(
              trim(concat_ws(' ', p.given_name, p.family_middle_name)),
              ''
            ),
            nullif(
              trim(concat_ws(' ', u.raw_user_meta_data->>'first_name', u.raw_user_meta_data->>'last_name')),
              ''
            ),
            ''
          )::text as full_name,
          coalesce(u.email::text, '')::text as email,
          iam._platform_user_effective_status(u.email_confirmed_at)::text as status,
          coalesce(p.created_at, u.created_at) as created_at,
          coalesce(p.version, 1) as version
        from auth.users u
        left join iam.platform_user_profiles p on p.user_id = u.id
        where (
            p_status is null
            or iam._platform_user_effective_status(u.email_confirmed_at) = p_status
          )
          and (
            p_query is null or p_query = ''
            or u.email ilike '%' || p_query || '%'
            or coalesce(p.given_name, '') ilike '%' || p_query || '%'
            or coalesce(p.family_middle_name, '') ilike '%' || p_query || '%'
            or coalesce(u.raw_user_meta_data->>'first_name', '') ilike '%' || p_query || '%'
            or coalesce(u.raw_user_meta_data->>'last_name', '') ilike '%' || p_query || '%'
          )
        order by coalesce(p.created_at, u.created_at) desc
        limit v_limit
      ) t
    ), '[]'::jsonb),
    'next_cursor', null
  );
end;
$$;

revoke all on function iam.search_platform_users(text, text, text, integer) from public, anon;
grant execute on function iam.search_platform_users(text, text, text, integer) to authenticated;
