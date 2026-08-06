-- Title: iam patch owner-role canonicalization — is_owner bypass + flat member permission model
-- Kind: patch
-- Intent: iam_owner_role_canonicalization
-- Context: TH-01 EP-04 — owner bypass keyed on is_owner (not role); add is_owner to payloads.
--   Permission model: every active member shares all feature permissions equally; only owner
--   holds the organization-administration namespaces (iam.* + tenant.*: members/roles hub, invite,
--   tenant profile, readiness, activate, audit).
-- Touches: iam.has_permission, iam.get_session_context, iam.get_tenant_context, iam.switch_tenant_context
-- Safety: idempotent ; medium
-- Depends on: 20260805017_iam_tenant_membership_lifecycle, 20260805012_iam_get_tenant_context, 20260805010_iam_switch_tenant_context

-- iam.has_permission — flat authorization model (TH-01):
--   • owner (is_owner) → full access;
--   • any other ACTIVE member → full OPERATIONAL access, but the org-admin
--     domain (tenant.* / iam.* — member management, invitations, tenant
--     profile / readiness / activate / audit) is OWNER-ONLY.
-- role_permissions is intentionally no longer consulted (role does not gate
-- operational features in this model).
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
  v_is_owner boolean;
  v_status text;
begin
  if v_user_id is null then
    return false;
  end if;

  select m.role, m.is_owner, m.status
  into v_role, v_is_owner, v_status
  from iam.memberships m
  where m.user_id = v_user_id
    and m.tenant_id = p_tenant_id;

  -- Not a member, or membership no longer active.
  if v_role is null or coalesce(v_status, 'active') <> 'active' then
    return false;
  end if;

  -- Owner: full access.
  if coalesce(v_is_owner, false) then
    return true;
  end if;

  -- Non-owner active member: org-admin domain is owner-only.
  if p_permission like 'tenant.%' or p_permission like 'iam.%' then
    return false;
  end if;

  -- Everything else (operational: partner.* / catalog.* / pricing.* / ...).
  return true;
end;
$$;

-- iam.get_session_context — bypass keyed on is_owner; is_owner added to payload.
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
  v_is_owner boolean;
  v_permissions text[];
begin
  if v_user_id is null then
    raise exception 'not authenticated';
  end if;

  if p_tenant_id is not null then
    select m.tenant_id, m.role, m.status, m.is_owner
    into v_tenant_id, v_role, v_status, v_is_owner
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
    select m.tenant_id, m.role, m.is_owner
    into v_tenant_id, v_role, v_is_owner
    from iam.memberships m
    where m.user_id = v_user_id
      and m.status = 'active'
    order by m.created_at
    limit 1;

    if v_tenant_id is null then
      return null;
    end if;
  end if;

  if coalesce(v_is_owner, false) then
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
    'is_owner', coalesce(v_is_owner, false),
    'permissions', to_jsonb(v_permissions)
  );
end;
$$;

-- iam.get_tenant_context — bypass keyed on is_owner; is_owner added to valid payload.
create or replace function iam.get_tenant_context(p_tenant_id uuid default null)
returns jsonb
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_role text;
  v_is_owner boolean;
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

  select m.role, m.is_owner, t.name, coalesce(t.status, 'active')
  into v_role, v_is_owner, v_tenant_name, v_tenant_status
  from iam.tenants t
  left join iam.memberships m
    on m.tenant_id = t.id
   and m.user_id = v_user_id
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

  if coalesce(v_is_owner, false) then
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
    'is_owner', coalesce(v_is_owner, false),
    'permissions', to_jsonb(v_permissions),
    'tenant_status', v_tenant_status
  );
end;
$$;

-- iam.switch_tenant_context — bypass keyed on is_owner; is_owner added to valid payload.
create or replace function iam.switch_tenant_context(p_target_tenant_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_role text;
  v_is_owner boolean;
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

  select m.role, m.is_owner, t.name, coalesce(t.status, 'active')
  into v_role, v_is_owner, v_tenant_name, v_tenant_status
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

  if coalesce(v_is_owner, false) then
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
    'is_owner', coalesce(v_is_owner, false),
    'permissions', to_jsonb(v_permissions),
    'tenant_status', v_tenant_status
  );
end;
$$;
