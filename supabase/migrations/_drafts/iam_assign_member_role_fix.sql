-- Title: iam surgical fix assign member role permissions and catalog check
-- Kind: surgical
-- Intent: iam_assign_member_role_fix
-- Context: TH-01 EP-03 US-06 — assign member role fails with permission denied for store_owner
-- Touches: iam.assign_member_role
-- Safety: idempotent ; low
-- Depends on: 20260701000001_iam_tenant_membership_ops, 20260811024_iam_patch_owner_role_canonicalization

-- Root cause: the legacy assign_member_role RPC hardcoded `v_caller_role <> 'owner'`
-- and `p_role not in ('owner', 'staff')`. Under Theme-1, store_owner/is_owner and
-- the 4-role model (store_owner, staff, accountant, warehouse) are used.
-- We modernize permission checks, role catalog validation, version bump, and audit logging.

create or replace function iam.assign_member_role(
  p_tenant_id uuid,
  p_user_id uuid,
  p_role text
)
returns void
language plpgsql
security definer
set search_path = iam, auth, pg_temp
as $$
declare
  v_caller uuid := auth.uid();
  v_target_row iam.memberships;
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

  if not (
    exists (
      select 1
      from iam.memberships m
      where m.tenant_id = p_tenant_id
        and m.user_id = v_caller
        and (m.is_owner is true or m.role in ('owner', 'store_owner'))
        and m.status = 'active'
    )
    or iam.has_permission(p_tenant_id, 'iam.members.assign_role')
    or iam.has_permission(p_tenant_id, 'tenant.members.write')
  ) then
    raise exception 'PERMISSION_DENIED';
  end if;

  -- Role must be an active assignable role
  if not exists (
    select 1
    from iam.role_definitions r
    where r.code = p_role
      and r.status = 'active'
  ) and p_role not in ('store_owner', 'staff', 'accountant', 'warehouse') then
    raise exception 'ROLE_NOT_ASSIGNABLE';
  end if;

  -- Global lock on membership
  select *
  into v_target_row
  from iam.memberships m
  where m.tenant_id = p_tenant_id
    and m.user_id = p_user_id
  for update;

  if not found then
    raise exception 'RESOURCE_NOT_FOUND';
  end if;

  if v_target_row.status = 'removed' then
    raise exception 'MEMBERSHIP_REMOVED';
  end if;

  -- Protect the last owner from being demoted away from owner/store_owner
  if (v_target_row.is_owner is true or v_target_row.role in ('owner', 'store_owner'))
     and p_role not in ('owner', 'store_owner') then
    select count(*)
    into v_active_owner_count
    from iam.memberships m
    where m.tenant_id = p_tenant_id
      and (m.is_owner is true or m.role in ('owner', 'store_owner'))
      and m.status = 'active';

    if v_active_owner_count <= 1 then
      raise exception 'LAST_OWNER_PROTECTED';
    end if;
  end if;

  v_before := jsonb_build_object(
    'status', v_target_row.status,
    'version', v_target_row.version,
    'role', v_target_row.role
  );

  update iam.memberships
  set role = p_role,
      version = version + 1,
      updated_at = v_now
  where id = v_target_row.id
  returning * into v_target_row;

  begin
    perform iam.append_audit_log(
      p_scope => 'tenant',
      p_tenant_id => p_tenant_id,
      p_actor_user_id => v_caller,
      p_event_code => 'iam.membership.role_changed',
      p_subject_type => 'membership',
      p_subject_id => v_target_row.id::text,
      p_result => 'success',
      p_source => 'iam',
      p_tracking_id => v_target_row.id::text || ':' || v_target_row.version::text,
      p_before => v_before,
      p_after => jsonb_build_object(
        'status', v_target_row.status,
        'version', v_target_row.version,
        'role', v_target_row.role
      )
    );
  exception
    when undefined_function then
      null;
  end;

  begin
    perform iam.enqueue_outbox_message(
      p_tenant_id,
      'iam.membership.role_changed',
      jsonb_build_object(
        'membership_id', v_target_row.id,
        'tenant_id', v_target_row.tenant_id,
        'user_id', v_target_row.user_id,
        'role', v_target_row.role,
        'previous_role', v_before->>'role',
        'status', v_target_row.status,
        'version', v_target_row.version,
        'actor_user_id', v_caller
      )
    );
  exception
    when undefined_function then
      null;
  end;
end;
$$;

revoke all on function iam.assign_member_role(uuid, uuid, text) from public, anon;
grant execute on function iam.assign_member_role(uuid, uuid, text) to authenticated;
