-- Title: iam tenant membership lifecycle (S10 / EP-03 US-05 + US-06)
-- Kind: patch
-- Intent: iam_tenant_membership_lifecycle
-- Touches: iam.get_tenant_member, iam.deactivate_membership, iam.reactivate_membership, iam.remove_membership, iam.get_session_context, iam.list_user_tenants, iam.list_accessible_tenants, iam.switch_tenant_context, iam.get_tenant_context, iam.has_permission, iam.list_tenant_members
-- Notes: Draft only — do not apply via supabase migration up until promoted.
--        Elevates memberships from composite PK to stable id + status/version.
--        Access resolution uses active memberships only.
--        Admin list still returns active/inactive/removed.
--        S6: iam.list_tenant_members is a JSON page RPC (search/status/cursor/limit).

-- ── DDL ─────────────────────────────────────────────────────────────────────

alter table iam.memberships
  add column if not exists id uuid,
  add column if not exists status text not null default 'active',
  add column if not exists status_changed_at timestamptz,
  add column if not exists removed_at timestamptz,
  add column if not exists version int not null default 1,
  add column if not exists updated_at timestamptz not null default now(),
  add column if not exists is_owner boolean not null default false;

update iam.memberships
set is_owner = true
where role = 'owner'
  and is_owner is not true;

update iam.memberships
set id = gen_random_uuid()
where id is null;

alter table iam.memberships
  alter column id set default gen_random_uuid(),
  alter column id set not null;

alter table iam.memberships drop constraint if exists memberships_status_chk;
alter table iam.memberships
  add constraint memberships_status_chk
  check (status in ('active', 'inactive', 'removed'));

do $$
begin
  if exists (
    select 1
    from information_schema.table_constraints
    where table_schema = 'iam'
      and table_name = 'memberships'
      and constraint_type = 'PRIMARY KEY'
      and constraint_name = 'memberships_pkey'
  ) then
    alter table iam.memberships drop constraint memberships_pkey;
  end if;
exception
  when undefined_object then null;
end $$;

alter table iam.memberships drop constraint if exists memberships_pkey;
alter table iam.memberships add primary key (id);

drop index if exists iam.memberships_tenant_user_active_uidx;
create unique index memberships_tenant_user_active_uidx
  on iam.memberships (tenant_id, user_id)
  where status in ('active', 'inactive');

-- ── Helper: membership detail jsonb ─────────────────────────────────────────

create or replace function iam._membership_detail_json(p_membership iam.memberships)
returns jsonb
language plpgsql
stable
security definer
set search_path = iam, pg_temp
as $$
declare
  v_sole_owner boolean := false;
begin
  if (p_membership.is_owner is true or p_membership.role = 'owner') then
    select count(*) = 1
    into v_sole_owner
    from iam.memberships m
    where m.tenant_id = p_membership.tenant_id
      and (m.is_owner is true or m.role = 'owner')
      and m.status = 'active';
  end if;

  return jsonb_build_object(
    'membership_id', p_membership.id,
    'tenant_id', p_membership.tenant_id,
    'user_id', p_membership.user_id,
    'role', p_membership.role,
    'is_owner', (p_membership.is_owner is true or p_membership.role = 'owner'),
    'is_sole_owner', v_sole_owner,
    'status', p_membership.status,
    'version', p_membership.version,
    'joined_at', p_membership.created_at,
    'status_changed_at', p_membership.status_changed_at,
    'removed_at', p_membership.removed_at
  );
end;
$$;

-- ── get_tenant_member ───────────────────────────────────────────────────────

create or replace function iam.get_tenant_member(
  p_tenant_id uuid,
  p_membership_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare
  v_caller uuid := auth.uid();
  v_row iam.memberships;
begin
  if v_caller is null then
    raise exception 'AUTHENTICATION_REQUIRED';
  end if;

  if not exists (
    select 1
    from iam.memberships m
    where m.tenant_id = p_tenant_id
      and m.user_id = v_caller
      and m.status = 'active'
  ) then
    raise exception 'PERMISSION_DENIED';
  end if;

  if not iam.has_permission(p_tenant_id, 'tenant.member.view') then
    raise exception 'PERMISSION_DENIED';
  end if;

  select *
  into v_row
  from iam.memberships m
  where m.id = p_membership_id
    and m.tenant_id = p_tenant_id;

  if not found then
    raise exception 'RESOURCE_NOT_FOUND';
  end if;

  return iam._membership_detail_json(v_row);
end;
$$;

-- ── Shared mutation body ────────────────────────────────────────────────────

create or replace function iam._mutate_membership_status(
  p_tenant_id uuid,
  p_membership_id uuid,
  p_expected_version int,
  p_target_status text,
  p_event_type text,
  p_require_permission text
)
returns jsonb
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare
  v_caller uuid := auth.uid();
  v_row iam.memberships;
  v_is_owner boolean;
  v_active_owner_count int := 0;
  v_now timestamptz := now();
  v_before jsonb;
begin
  if v_caller is null then
    raise exception 'AUTHENTICATION_REQUIRED';
  end if;

  if not exists (
    select 1
    from iam.memberships m
    where m.tenant_id = p_tenant_id
      and m.user_id = v_caller
      and m.status = 'active'
  ) then
    raise exception 'PERMISSION_DENIED';
  end if;

  if not iam.has_permission(p_tenant_id, p_require_permission) then
    raise exception 'PERMISSION_DENIED';
  end if;

  -- Global lock order for tenant-scoped mutations: tenant -> membership.
  -- Keep this order aligned with iam.activate_tenant and ownership transfer
  -- to avoid membership/tenant lock inversion under concurrent requests.
  perform 1
  from iam.tenants t
  where t.id = p_tenant_id
  for update;

  if not found then
    raise exception 'RESOURCE_NOT_FOUND';
  end if;

  select *
  into v_row
  from iam.memberships m
  where m.id = p_membership_id
    and m.tenant_id = p_tenant_id
  for update;

  if not found then
    raise exception 'RESOURCE_NOT_FOUND';
  end if;

  if v_row.version <> p_expected_version then
    raise exception 'STATE_CHANGED';
  end if;

  if v_row.status = 'removed' then
    raise exception 'MEMBERSHIP_REMOVED';
  end if;

  if p_target_status = 'active' and v_row.status <> 'inactive' then
    raise exception 'STATE_CHANGED';
  end if;

  if p_target_status = 'inactive' and v_row.status <> 'active' then
    raise exception 'STATE_CHANGED';
  end if;

  if p_target_status = 'removed' and v_row.status not in ('active', 'inactive') then
    raise exception 'STATE_CHANGED';
  end if;

  v_is_owner := (v_row.is_owner is true or v_row.role = 'owner');
  if v_is_owner and p_target_status in ('inactive', 'removed') then
    select count(*)
    into v_active_owner_count
    from iam.memberships m
    where m.tenant_id = p_tenant_id
      and (m.is_owner is true or m.role = 'owner')
      and m.status = 'active';

    if v_active_owner_count <= 1 then
      raise exception 'LAST_OWNER_PROTECTED';
    end if;
  end if;

  if p_target_status = 'active' and v_row.role not in ('owner', 'staff') then
    raise exception 'ROLE_NOT_ASSIGNABLE';
  end if;

  v_before := jsonb_build_object(
    'status', v_row.status,
    'version', v_row.version,
    'role', v_row.role
  );

  update iam.memberships
  set status = p_target_status,
      version = version + 1,
      status_changed_at = v_now,
      removed_at = case when p_target_status = 'removed' then v_now else removed_at end,
      updated_at = v_now
  where id = v_row.id
  returning * into v_row;

  -- Domain change + audit row in the same transaction. Audit failure must
  -- roll back the mutation, so this is NOT wrapped in an exception handler.
  perform iam.append_audit_log(
    p_scope => 'tenant',
    p_tenant_id => p_tenant_id,
    p_actor_user_id => v_caller,
    p_event_code => p_event_type,
    p_subject_type => 'membership',
    p_subject_id => v_row.id::text,
    p_result => 'success',
    p_source => 'iam',
    p_tracking_id => v_row.id::text || ':' || v_row.version::text,
    p_before => v_before,
    p_after => jsonb_build_object(
      'status', v_row.status,
      'version', v_row.version,
      'role', v_row.role
    )
  );

  begin
    perform iam.enqueue_outbox_message(
      p_tenant_id,
      p_event_type,
      jsonb_build_object(
        'membership_id', v_row.id,
        'tenant_id', v_row.tenant_id,
        'user_id', v_row.user_id,
        'status', v_row.status,
        'version', v_row.version,
        'actor_user_id', v_caller
      )
    );
  exception
    when undefined_function then
      null;
  end;

  return iam._membership_detail_json(v_row);
end;
$$;

create or replace function iam.deactivate_membership(
  p_tenant_id uuid,
  p_membership_id uuid,
  p_expected_version int
)
returns jsonb
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
begin
  return iam._mutate_membership_status(
    p_tenant_id,
    p_membership_id,
    p_expected_version,
    'inactive',
    'iam.membership.deactivated',
    'tenant.member.status.update'
  );
end;
$$;

create or replace function iam.reactivate_membership(
  p_tenant_id uuid,
  p_membership_id uuid,
  p_expected_version int
)
returns jsonb
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
begin
  return iam._mutate_membership_status(
    p_tenant_id,
    p_membership_id,
    p_expected_version,
    'active',
    'iam.membership.reactivated',
    'tenant.member.status.update'
  );
end;
$$;

create or replace function iam.remove_membership(
  p_tenant_id uuid,
  p_membership_id uuid,
  p_expected_version int
)
returns jsonb
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
begin
  return iam._mutate_membership_status(
    p_tenant_id,
    p_membership_id,
    p_expected_version,
    'removed',
    'iam.membership.removed',
    'tenant.member.remove'
  );
end;
$$;

-- ── Patch access RPCs: active membership only ───────────────────────────────

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
  v_status text;
  v_permissions text[];
begin
  if v_user_id is null then
    raise exception 'not authenticated';
  end if;

  if p_tenant_id is not null then
    select m.tenant_id, m.role, m.status
    into v_tenant_id, v_role, v_status
    from iam.memberships m
    where m.user_id = v_user_id
      and m.tenant_id = p_tenant_id;

    if v_tenant_id is null then
      raise exception 'TENANT_ACCESS_DENIED';
    end if;
    if v_status = 'inactive' then
      raise exception 'MEMBERSHIP_INACTIVE';
    end if;
    if v_status = 'removed' then
      raise exception 'MEMBERSHIP_REMOVED';
    end if;
  else
    select m.tenant_id, m.role
    into v_tenant_id, v_role
    from iam.memberships m
    where m.user_id = v_user_id
      and m.status = 'active'
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
    and m.status = 'active'
  order by m.created_at;
end;
$$;

create or replace function iam.list_accessible_tenants()
returns table (
  tenant_id uuid,
  name text,
  role text,
  status text
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
  select t.id, t.name, m.role, t.status
  from iam.memberships m
  join iam.tenants t on t.id = m.tenant_id
  where m.user_id = v_user_id
    and m.status = 'active'
  order by m.created_at;
end;
$$;

create or replace function iam.switch_tenant_context(p_target_tenant_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_role text;
  v_membership_status text;
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

  select m.role, m.status, t.name, coalesce(t.status, 'active')
  into v_role, v_membership_status, v_tenant_name, v_tenant_status
  from iam.memberships m
  join iam.tenants t on t.id = m.tenant_id
  where m.user_id = v_user_id
    and m.tenant_id = p_target_tenant_id;

  if v_role is null then
    raise exception 'TENANT_ACCESS_DENIED';
  end if;

  if v_membership_status = 'inactive' then
    raise exception 'MEMBERSHIP_INACTIVE';
  end if;

  if v_membership_status = 'removed' then
    raise exception 'MEMBERSHIP_REMOVED';
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

create or replace function iam.get_tenant_context(p_tenant_id uuid default null)
returns jsonb
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_role text;
  v_membership_status text;
  v_tenant_name text;
  v_tenant_status text;
  v_permissions text[];
begin
  if v_user_id is null then
    raise exception 'not authenticated';
  end if;

  if p_tenant_id is null then
    return jsonb_build_object('status', 'none');
  end if;

  select m.role, m.status, t.name, coalesce(t.status, 'active')
  into v_role, v_membership_status, v_tenant_name, v_tenant_status
  from iam.tenants t
  left join iam.memberships m
    on m.tenant_id = t.id
   and m.user_id = v_user_id
   and m.status <> 'removed'
  where t.id = p_tenant_id;

  if not found then
    return jsonb_build_object(
      'status', 'invalidated',
      'invalidation_reason', 'accessDenied',
      'blocked_error_code', 'TENANT_ACCESS_DENIED',
      'tenant_id', p_tenant_id
    );
  end if;

  if v_role is null then
    return jsonb_build_object(
      'status', 'invalidated',
      'invalidation_reason', 'membershipRemoved',
      'blocked_error_code', 'MEMBERSHIP_REMOVED',
      'tenant_id', p_tenant_id,
      'tenant_name', v_tenant_name,
      'tenant_status', v_tenant_status
    );
  end if;

  if v_membership_status = 'inactive' then
    return jsonb_build_object(
      'status', 'invalidated',
      'invalidation_reason', 'membershipInactive',
      'blocked_error_code', 'MEMBERSHIP_INACTIVE',
      'tenant_id', p_tenant_id,
      'tenant_name', v_tenant_name,
      'role', v_role,
      'tenant_status', v_tenant_status
    );
  end if;

  if v_tenant_status = 'suspended' then
    return jsonb_build_object(
      'status', 'invalidated',
      'invalidation_reason', 'tenantSuspended',
      'blocked_error_code', 'TENANT_SUSPENDED',
      'tenant_id', p_tenant_id,
      'tenant_name', v_tenant_name,
      'role', v_role,
      'tenant_status', v_tenant_status
    );
  end if;

  if v_tenant_status = 'closed' then
    return jsonb_build_object(
      'status', 'invalidated',
      'invalidation_reason', 'tenantClosed',
      'blocked_error_code', 'TENANT_CLOSED',
      'tenant_id', p_tenant_id,
      'tenant_name', v_tenant_name,
      'role', v_role,
      'tenant_status', v_tenant_status
    );
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
    'tenant_id', p_tenant_id,
    'tenant_name', v_tenant_name,
    'role', v_role,
    'permissions', to_jsonb(v_permissions),
    'tenant_status', v_tenant_status
  );
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
    and m.tenant_id = p_tenant_id
    and m.status = 'active';

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

drop function if exists iam.list_tenant_members(uuid);

create or replace function iam.list_tenant_members(
  p_tenant_id uuid,
  p_search text,
  p_status text,
  p_cursor text,
  p_limit integer
)
returns jsonb
language plpgsql
security definer
set search_path = iam, auth, pg_temp
as $$
declare
  v_caller uuid := auth.uid();
  v_limit int := coalesce(p_limit, 20);
  v_search text := lower(trim(coalesce(p_search, '')));
  v_status text := nullif(trim(coalesce(p_status, '')), '');
  v_cur_created timestamptz;
  v_cur_id uuid;
  v_cursor_payload jsonb;
  v_items jsonb;
  v_next_cursor text;
begin
  if v_caller is null then
    raise exception 'AUTHENTICATION_REQUIRED';
  end if;

  if not exists (
    select 1
    from iam.memberships m
    where m.tenant_id = p_tenant_id
      and m.user_id = v_caller
      and m.status = 'active'
  ) then
    raise exception 'PERMISSION_DENIED';
  end if;

  if not iam.has_permission(p_tenant_id, 'tenant.member.view') then
    raise exception 'PERMISSION_DENIED';
  end if;

  if v_limit < 1 or v_limit > 100 then
    raise exception 'VALIDATION_ERROR';
  end if;

  if v_status is not null and v_status not in ('active', 'inactive', 'removed') then
    raise exception 'VALIDATION_ERROR';
  end if;

  if p_cursor is not null and p_cursor <> '' then
    begin
      v_cursor_payload :=
        convert_from(decode(p_cursor, 'hex'), 'UTF8')::jsonb;
      v_cur_created :=
        (v_cursor_payload ->> 'created_at')::timestamptz;
      v_cur_id :=
        (v_cursor_payload ->> 'id')::uuid;

      if v_cur_created is null or v_cur_id is null then
        raise exception 'VALIDATION_ERROR';
      end if;
    exception
      when others then
        raise exception 'VALIDATION_ERROR';
    end;
  end if;

  with filtered as (
    select
      m.id,
      m.user_id,
      m.role,
      m.is_owner,
      m.status,
      m.created_at,
      m.version,
      coalesce(
        nullif(
          trim(concat_ws(' ', p.given_name, p.family_middle_name)),
          ''
        ),
        ''
      ) as display_name,
      coalesce(u.email::text, '') as email,
      coalesce(rd.id::text, m.role) as role_id,
      coalesce(rd.label, m.role) as role_label
    from iam.memberships m
    left join auth.users u on u.id = m.user_id
    left join iam.platform_user_profiles p on p.user_id = m.user_id
    left join iam.role_definitions rd on rd.code = m.role
    where m.tenant_id = p_tenant_id
      and (v_status is null or m.status = v_status)
      and (
        v_search = ''
        or lower(coalesce(u.email::text, ''))
          like '%' || v_search || '%'
        or lower(
          coalesce(
            nullif(
              trim(concat_ws(' ', p.given_name, p.family_middle_name)),
              ''
            ),
            ''
          )
        ) like '%' || v_search || '%'
      )
      and (
        v_cur_created is null
        or (m.created_at, m.id) < (v_cur_created, v_cur_id)
      )
    order by m.created_at desc, m.id desc
    limit v_limit + 1
  ),
  page as (
    select *
    from filtered
    order by created_at desc, id desc
    limit v_limit
  )
  select
    coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'membership_id', f.id,
            'user_id', f.user_id,
            'display_name', f.display_name,
            'email', f.email,
            'role_id', f.role_id,
            'role_label', f.role_label,
            'is_owner', (f.is_owner is true or f.role = 'owner'),
            'status', f.status,
            'joined_at', f.created_at,
            'version', f.version
          )
          order by f.created_at desc, f.id desc
        )
        from page f
      ),
      '[]'::jsonb
    ),
    case
      when (select count(*) from filtered) > v_limit then (
        select encode(
          convert_to(
            jsonb_build_object(
              'created_at', p.created_at,
              'id', p.id
            )::text,
            'UTF8'
          ),
          'hex'
        )
        from page p
        order by p.created_at asc, p.id asc
        limit 1
      )
      else null
    end
  into v_items, v_next_cursor;

  return jsonb_build_object(
    'items', coalesce(v_items, '[]'::jsonb),
    'next_cursor', v_next_cursor
  );
end;
$$;

revoke all on function iam.get_tenant_member(uuid, uuid) from public, anon;
revoke all on function iam.deactivate_membership(uuid, uuid, int) from public, anon;
revoke all on function iam.reactivate_membership(uuid, uuid, int) from public, anon;
revoke all on function iam.remove_membership(uuid, uuid, int) from public, anon;
revoke all on function iam.get_session_context(uuid) from public, anon;
revoke all on function iam.list_user_tenants() from public, anon;
revoke all on function iam.list_accessible_tenants() from public, anon;
revoke all on function iam.switch_tenant_context(uuid) from public, anon;
revoke all on function iam.get_tenant_context(uuid) from public, anon;
revoke all on function iam.has_permission(uuid, text) from public, anon;
revoke all on function iam.list_tenant_members(uuid, text, text, text, integer) from public, anon;

grant execute on function iam.get_tenant_member(uuid, uuid) to authenticated;
grant execute on function iam.deactivate_membership(uuid, uuid, int) to authenticated;
grant execute on function iam.reactivate_membership(uuid, uuid, int) to authenticated;
grant execute on function iam.remove_membership(uuid, uuid, int) to authenticated;
grant execute on function iam.get_session_context(uuid) to authenticated;
grant execute on function iam.list_user_tenants() to authenticated;
grant execute on function iam.list_accessible_tenants() to authenticated;
grant execute on function iam.switch_tenant_context(uuid) to authenticated;
grant execute on function iam.get_tenant_context(uuid) to authenticated;
grant execute on function iam.has_permission(uuid, text) to authenticated;
grant execute on function iam.list_tenant_members(uuid, text, text, text, integer) to authenticated;
