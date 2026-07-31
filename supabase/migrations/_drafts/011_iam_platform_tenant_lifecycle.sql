-- Title: iam platform tenant lifecycle (S16 / EP-02 US-06)
-- Kind: patch
-- Intent: iam_platform_tenant_lifecycle
-- Touches: iam.suspend_platform_tenant, iam.restore_platform_tenant
-- Notes: Draft only — do not apply via supabase migration up until promoted.
--        Closed tenants cannot suspend/restore. Writes privileged audit rows.

create table if not exists iam.platform_audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_user_id uuid,
  action text not null,
  target_user_id uuid,
  target_tenant_id uuid,
  reason text,
  status text not null default 'success'
    check (status in ('success', 'blocked', 'error')),
  title text,
  correlation_id text,
  source_app text default 'admin',
  before_state text,
  after_state text,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table iam.platform_audit_logs
  add column if not exists target_tenant_id uuid;

alter table iam.platform_audit_logs
  add column if not exists status text not null default 'success';

alter table iam.platform_audit_logs
  add column if not exists title text;

alter table iam.platform_audit_logs
  add column if not exists correlation_id text;

alter table iam.platform_audit_logs
  add column if not exists source_app text default 'admin';

alter table iam.platform_audit_logs
  add column if not exists before_state text;

alter table iam.platform_audit_logs
  add column if not exists after_state text;

alter table iam.platform_audit_logs enable row level security;

create or replace function iam.suspend_platform_tenant(
  p_tenant_id uuid,
  p_reason text
)
returns void
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare
  v_actor uuid := auth.uid();
  v_status text;
begin
  if not iam.has_platform_permission('platform.tenant.suspend') then
    raise exception 'platform permission denied';
  end if;

  if p_reason is null or trim(p_reason) = '' then
    raise exception 'suspend reason required';
  end if;

  select coalesce(status, 'active') into v_status
  from iam.tenants
  where id = p_tenant_id
  for update;

  if v_status is null then
    raise exception 'platform tenant not found';
  end if;

  if v_status = 'closed' then
    raise exception 'closed tenant cannot be suspended';
  end if;

  update iam.tenants
  set status = 'suspended',
      suspended_at = now(),
      suspend_reason = trim(p_reason),
      suspended_by = v_actor
  where id = p_tenant_id;

  -- Audit into the canonical store in the same transaction (no dual-write).
  perform iam.append_audit_log(
    p_scope => 'platform',
    p_tenant_id => p_tenant_id,
    p_actor_user_id => v_actor,
    p_event_code => 'iam.tenant.suspended',
    p_subject_type => 'tenant',
    p_subject_id => p_tenant_id::text,
    p_result => 'success',
    p_source => 'admin',
    p_tracking_id => gen_random_uuid()::text,
    p_before => jsonb_build_object('status', v_status),
    p_after => jsonb_build_object('status', 'suspended', 'reason', trim(p_reason))
  );
end;
$$;

create or replace function iam.restore_platform_tenant(p_tenant_id uuid)
returns void
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare
  v_actor uuid := auth.uid();
  v_status text;
begin
  if not iam.has_platform_permission('platform.tenant.restore') then
    raise exception 'platform permission denied';
  end if;

  select coalesce(status, 'active') into v_status
  from iam.tenants
  where id = p_tenant_id
  for update;

  if v_status is null then
    raise exception 'platform tenant not found';
  end if;

  if v_status = 'closed' then
    raise exception 'closed tenant cannot be restored';
  end if;

  if v_status <> 'suspended' then
    raise exception 'only suspended tenant can be restored';
  end if;

  update iam.tenants
  set status = 'active',
      suspended_at = null,
      suspend_reason = null,
      suspended_by = null,
      activated_at = coalesce(activated_at, now())
  where id = p_tenant_id;

  -- Audit into the canonical store in the same transaction (no dual-write).
  perform iam.append_audit_log(
    p_scope => 'platform',
    p_tenant_id => p_tenant_id,
    p_actor_user_id => v_actor,
    p_event_code => 'iam.tenant.restored',
    p_subject_type => 'tenant',
    p_subject_id => p_tenant_id::text,
    p_result => 'success',
    p_source => 'admin',
    p_tracking_id => gen_random_uuid()::text,
    p_before => jsonb_build_object('status', 'suspended'),
    p_after => jsonb_build_object('status', 'active')
  );
end;
$$;

revoke all on function iam.suspend_platform_tenant(uuid, text) from public, anon;
grant execute on function iam.suspend_platform_tenant(uuid, text) to authenticated;

revoke all on function iam.restore_platform_tenant(uuid) from public, anon;
grant execute on function iam.restore_platform_tenant(uuid) to authenticated;

-- Task-10 contract patch: tenant lifecycle version/idempotency + TENANT_STATE_INVALID
create or replace function iam.suspend_platform_tenant(
  p_tenant_id uuid,
  p_reason text,
  p_expected_version integer,
  p_idempotency_key text
)
returns void
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare v_status text; v_version int;
begin
  if not iam.has_platform_permission('platform.tenant.suspend') then
    raise exception 'PLATFORM_PERMISSION_DENIED';
  end if;
  select coalesce(status, 'active'), coalesce(version, 1)
    into v_status, v_version
  from iam.tenants where id = p_tenant_id for update;
  if v_status is null then raise exception 'RESOURCE_NOT_FOUND'; end if;
  if v_status = 'closed' then raise exception 'TENANT_STATE_INVALID'; end if;
  if v_version is distinct from p_expected_version then
    raise exception 'STATE_CHANGED';
  end if;
  update iam.tenants set status = 'suspended', version = version + 1
  where id = p_tenant_id;
end;
$$;

create or replace function iam.restore_platform_tenant(
  p_tenant_id uuid,
  p_expected_version integer,
  p_idempotency_key text
)
returns void
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare v_status text;
begin
  if not iam.has_platform_permission('platform.tenant.restore') then
    raise exception 'PLATFORM_PERMISSION_DENIED';
  end if;
  select coalesce(status, 'active') into v_status
  from iam.tenants where id = p_tenant_id for update;
  if v_status = 'closed' then raise exception 'TENANT_STATE_INVALID'; end if;
  update iam.tenants set status = 'active', version = version + 1
  where id = p_tenant_id and version = p_expected_version;
  if not found then raise exception 'STATE_CHANGED'; end if;
end;
$$;
