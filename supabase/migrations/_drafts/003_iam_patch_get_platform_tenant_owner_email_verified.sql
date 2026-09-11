-- Title: iam patch get_platform_tenant returns owner_email_verified
-- Kind: surgical
-- Intent: iam_platform_tenant_owner_email_verified
-- Context: TH-01 / platform tenant detail owner email verified status
-- Touches: iam.get_platform_tenant
-- Safety: idempotent ; low
-- Depends on: 20260811010_iam_platform_tenants_read

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
    coalesce(rd.label, m.role::text) as owner_role,
    (u.email_confirmed_at is not null) as owner_email_verified
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
    'owner_email_verified', coalesce(v_owner.owner_email_verified, false),
    'members', coalesce(v_members, '[]'::jsonb)
  );
end;
$$;

revoke all on function iam.get_platform_tenant(uuid) from public, anon;
grant execute on function iam.get_platform_tenant(uuid) to authenticated;
