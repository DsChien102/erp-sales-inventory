-- TH-03 Epic-02/US-01: partner status mutations (deactivate / reactivate).
-- Context: docs/themes/TH-03-partner/Epic-02-partner-status/US-01/

insert into iam.role_permissions (role, permission)
values
  ('staff', 'partner.manage_status')
on conflict (role, permission) do nothing;

create or replace function partner.deactivate_partner(
  p_tenant_id uuid,
  p_partner_id uuid,
  p_expected_version integer,
  p_actor_id uuid default auth.uid(),
  p_status_note text default null
)
returns integer
language plpgsql
security definer
set search_path = partner, iam, pg_temp
as $$
declare
  v_current_version integer;
  v_current_status partner.partner_status;
  v_outbox_payload jsonb;
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  if p_actor_id is null or p_actor_id <> auth.uid() then
    raise exception 'actor mismatch';
  end if;

  if not iam.has_permission(p_tenant_id, 'partner.manage_status') then
    raise exception 'permission denied: partner.manage_status';
  end if;

  select bp.version, bp.status
  into v_current_version, v_current_status
  from partner.business_partners bp
  where bp.id = p_partner_id
    and bp.tenant_id = p_tenant_id
  for update;

  if v_current_version is null then
    raise exception 'partner not found';
  end if;

  if v_current_version <> p_expected_version then
    raise exception 'version conflict';
  end if;

  if v_current_status <> 'active'::partner.partner_status then
    raise exception 'invalid status transition';
  end if;

  update partner.business_partners bp
  set
    status = 'inactive'::partner.partner_status,
    status_changed_at = now(),
    status_changed_by = p_actor_id,
    status_note = nullif(btrim(coalesce(p_status_note, '')), ''),
    updated_by = p_actor_id
  where bp.id = p_partner_id
    and bp.tenant_id = p_tenant_id
    and bp.version = p_expected_version;

  if not found then
    raise exception 'version conflict';
  end if;

  select bp.version
  into v_current_version
  from partner.business_partners bp
  where bp.id = p_partner_id
    and bp.tenant_id = p_tenant_id;

  insert into partner.partner_audit_logs (
    tenant_id,
    business_partner_id,
    action,
    field_name,
    old_value,
    new_value,
    actor_id
  )
  values (
    p_tenant_id,
    p_partner_id,
    'partner_deactivated',
    'status',
    jsonb_build_object('status', 'active'),
    jsonb_build_object(
      'status', 'inactive',
      'status_note', nullif(btrim(coalesce(p_status_note, '')), '')
    ),
    p_actor_id
  );

  v_outbox_payload := jsonb_build_object(
    'business_partner_id', p_partner_id,
    'tenant_id', p_tenant_id,
    'status', 'inactive'
  );

  perform partner.enqueue_outbox_message(
    p_tenant_id,
    'partner.partner.deactivated',
    v_outbox_payload
  );

  return v_current_version;
end;
$$;

create or replace function partner.reactivate_partner(
  p_tenant_id uuid,
  p_partner_id uuid,
  p_expected_version integer,
  p_actor_id uuid default auth.uid()
)
returns integer
language plpgsql
security definer
set search_path = partner, iam, pg_temp
as $$
declare
  v_current_version integer;
  v_current_status partner.partner_status;
  v_outbox_payload jsonb;
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  if p_actor_id is null or p_actor_id <> auth.uid() then
    raise exception 'actor mismatch';
  end if;

  if not iam.has_permission(p_tenant_id, 'partner.manage_status') then
    raise exception 'permission denied: partner.manage_status';
  end if;

  select bp.version, bp.status
  into v_current_version, v_current_status
  from partner.business_partners bp
  where bp.id = p_partner_id
    and bp.tenant_id = p_tenant_id
  for update;

  if v_current_version is null then
    raise exception 'partner not found';
  end if;

  if v_current_version <> p_expected_version then
    raise exception 'version conflict';
  end if;

  if v_current_status <> 'inactive'::partner.partner_status then
    raise exception 'invalid status transition';
  end if;

  update partner.business_partners bp
  set
    status = 'active'::partner.partner_status,
    status_changed_at = now(),
    status_changed_by = p_actor_id,
    status_note = null,
    updated_by = p_actor_id
  where bp.id = p_partner_id
    and bp.tenant_id = p_tenant_id
    and bp.version = p_expected_version;

  if not found then
    raise exception 'version conflict';
  end if;

  select bp.version
  into v_current_version
  from partner.business_partners bp
  where bp.id = p_partner_id
    and bp.tenant_id = p_tenant_id;

  insert into partner.partner_audit_logs (
    tenant_id,
    business_partner_id,
    action,
    field_name,
    old_value,
    new_value,
    actor_id
  )
  values (
    p_tenant_id,
    p_partner_id,
    'partner_reactivated',
    'status',
    jsonb_build_object('status', 'inactive'),
    jsonb_build_object('status', 'active'),
    p_actor_id
  );

  v_outbox_payload := jsonb_build_object(
    'business_partner_id', p_partner_id,
    'tenant_id', p_tenant_id,
    'status', 'active'
  );

  perform partner.enqueue_outbox_message(
    p_tenant_id,
    'partner.partner.reactivated',
    v_outbox_payload
  );

  return v_current_version;
end;
$$;

revoke all on function partner.deactivate_partner(uuid, uuid, integer, uuid, text) from public, anon;
grant execute on function partner.deactivate_partner(uuid, uuid, integer, uuid, text) to authenticated, service_role;

revoke all on function partner.reactivate_partner(uuid, uuid, integer, uuid) from public, anon;
grant execute on function partner.reactivate_partner(uuid, uuid, integer, uuid) to authenticated, service_role;
