-- Title: iam search/get platform user phone + status::text after enum
-- Kind: patch
-- Intent: iam_platform_user_phone_and_status_enum
-- Context: TH-01 / onboarding owner card phone + enum status cast safety
-- Touches: search_platform_users, get_platform_user, get_my_platform_user_profile
-- Safety: idempotent ; medium
-- Depends on: 20260826003_iam_audit_owner_activation_cleanup, 001_iam_patch_platform_user_status_enum

-- After iam.platform_user_profiles.status → enum, CASE/coalesce that mix enum with
-- text branches must cast. search also returns phone_number for owner card UI.

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
    coalesce(p.status::text, 'pending_activation') as status
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

create or replace function iam.get_platform_user(p_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = iam, auth, pg_temp
as $$
declare
  v_row record;
  v_memberships jsonb;
  v_activation_expires_at timestamptz;
begin
  if not iam.has_platform_permission('platform.user.view') then
    raise exception 'PLATFORM_PERMISSION_DENIED';
  end if;

  select
    coalesce(u.id, p.user_id) as user_id,
    coalesce(
      nullif(trim(concat_ws(' ', p.family_middle_name, p.given_name)), ''),
      nullif(trim(concat_ws(' ', u.raw_user_meta_data->>'last_name', u.raw_user_meta_data->>'first_name')), ''),
      ''
    )::text as full_name,
    coalesce(u.email::text, p.email, '')::text as email,
    (case
      when p.status = 'suspended' then 'suspended'
      when u.id is not null then iam._platform_user_effective_status(u.email_confirmed_at)
      else coalesce(p.status::text, 'pending_activation')
    end)::text as status,
    (u.email_confirmed_at is not null) as email_verified,
    u.email_confirmed_at as email_verified_at,
    coalesce(p.created_at, u.created_at) as created_at,
    p.last_login_at,
    coalesce(p.version, 1) as version
  into v_row
  from iam.platform_user_profiles p
  full outer join auth.users u on u.id = p.user_id
  where coalesce(u.id, p.user_id) = p_user_id;

  if v_row.user_id is null then
    raise exception 'platform user not found';
  end if;

  -- Hạn kích hoạt email của owner đang chờ: lấy từ lời mời owner còn hiệu lực
  -- khớp email (null nếu không có lời mời pending → owner đã kích hoạt/không phải owner).
  select ti.expires_at into v_activation_expires_at
  from iam.tenant_invitations ti
  where ti.is_owner = true
    and ti.status = 'pending'
    and lower(ti.invitee_email) = lower(v_row.email)
  order by ti.created_at desc
  limit 1;

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
    'email_verified_at', v_row.email_verified_at,
    'created_at', v_row.created_at,
    'last_login_at', v_row.last_login_at,
    'activation_expires_at', v_activation_expires_at,
    'memberships', v_memberships,
    'version', v_row.version
  );
end;
$$;

revoke all on function iam.get_platform_user(uuid) from public, anon;
grant execute on function iam.get_platform_user(uuid) to authenticated;

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
          coalesce(u.id, p.user_id) as user_id,
          coalesce(
            nullif(trim(concat_ws(' ', p.family_middle_name, p.given_name)), ''),
            nullif(
              trim(concat_ws(' ', u.raw_user_meta_data->>'last_name', u.raw_user_meta_data->>'first_name')),
              ''
            ),
            ''
          )::text as full_name,
          coalesce(u.email::text, p.email, '')::text as email,
          (case
            when p.status = 'suspended' then 'suspended'
            when u.id is not null then iam._platform_user_effective_status(u.email_confirmed_at)
            else coalesce(p.status::text, 'pending_activation')
          end)::text as status,
          p.phone_number,
          coalesce(p.created_at, u.created_at) as created_at,
          coalesce(p.version, 1) as version
        from iam.platform_user_profiles p
        full outer join auth.users u on u.id = p.user_id
        where (
            p_status is null
            or (case
                  when p.status = 'suspended' then 'suspended'
                  when u.id is not null then iam._platform_user_effective_status(u.email_confirmed_at)
                  else coalesce(p.status::text, 'pending_activation')
                end) = p_status
          )
          and (
            p_query is null or p_query = ''
            or coalesce(u.email, p.email) ilike '%' || p_query || '%'
            or coalesce(p.given_name, '') ilike '%' || p_query || '%'
            or coalesce(p.family_middle_name, '') ilike '%' || p_query || '%'
            or coalesce(u.raw_user_meta_data->>'first_name', '') ilike '%' || p_query || '%'
            or coalesce(u.raw_user_meta_data->>'last_name', '') ilike '%' || p_query || '%'
          )
          -- Durable de-dup guard: a pending placeholder carries a generated id that
          -- differs from the real auth id, so when the person activates (via accept,
          -- login audit, or any path) their active row appears under the auth id and
          -- the placeholder can linger as an orphan. Hide such an orphan — a
          -- profile-only pending row (no auth row of its own) whose email already has
          -- a real auth account — so the list can never show the person twice,
          -- regardless of which write path created the active row.
          and not (
            u.id is null
            and p.status = 'pending_activation'
            and p.email is not null
            and exists (
              select 1 from auth.users au
              where lower(au.email::text) = lower(p.email)
            )
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
