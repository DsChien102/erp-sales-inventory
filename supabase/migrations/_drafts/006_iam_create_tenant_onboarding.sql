-- Title: iam create tenant onboarding (S15 / EP-01 US-03)
-- Kind: patch
-- Intent: iam_create_tenant_onboarding
-- Touches: iam.create_tenant_onboarding
-- Notes: Draft only — do not apply via supabase migration up until promoted.
--        Atomic Theme-1: Tenant(provisioning) + Owner Membership + role owner.
--        Platform User create (auth.users) is Identity boundary — pass resolved p_owner_user_id.
--        Idempotent via iam.onboarding_operations.idempotency_key.

alter table iam.tenants
  add column if not exists status text not null default 'active';

do $$
begin
  if exists (
    select 1 from pg_constraint
    where conname = 'tenants_status_chk'
      and conrelid = 'iam.tenants'::regclass
  ) then
    alter table iam.tenants drop constraint tenants_status_chk;
  end if;
  alter table iam.tenants
    add constraint tenants_status_chk
    check (status in ('provisioning', 'active', 'suspended', 'closed'));
end $$;

alter table iam.memberships
  add column if not exists is_owner boolean not null default false;

create table if not exists iam.onboarding_operations (
  idempotency_key text primary key,
  correlation_id text not null,
  result jsonb not null,
  created_at timestamptz not null default now()
);

create or replace function iam.create_tenant_onboarding(
  p_owner_user_id uuid,
  p_org_name text,
  p_idempotency_key text,
  p_correlation_id text default null,
  p_is_new_user boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare
  v_actor uuid := auth.uid();
  v_existing jsonb;
  v_tenant_id uuid;
  v_membership_id text;
  v_correlation text;
  v_result jsonb;
begin
  if not iam.has_platform_permission('platform.tenant.create') then
    raise exception 'platform permission denied';
  end if;

  if p_org_name is null or trim(p_org_name) = '' then
    raise exception 'organization name required';
  end if;

  if p_idempotency_key is null or trim(p_idempotency_key) = '' then
    raise exception 'idempotency key required';
  end if;

  if p_owner_user_id is null then
    raise exception 'owner user id required';
  end if;

  select result into v_existing
  from iam.onboarding_operations
  where idempotency_key = p_idempotency_key;

  if v_existing is not null then
    return v_existing;
  end if;

  v_correlation := coalesce(nullif(trim(p_correlation_id), ''), gen_random_uuid()::text);

  insert into iam.tenants (name, status)
  values (trim(p_org_name), 'provisioning')
  returning id into v_tenant_id;

  insert into iam.memberships (tenant_id, user_id, role, is_owner)
  values (v_tenant_id, p_owner_user_id, 'owner', true);

  -- Interim membership id composite key (tenant_id,user_id) — expose as stable string.
  v_membership_id := v_tenant_id::text || ':' || p_owner_user_id::text;

  perform iam.enqueue_outbox_message(
    v_tenant_id,
    'iam.tenant.created',
    jsonb_build_object(
      'tenant_id', v_tenant_id,
      'owner_user_id', p_owner_user_id,
      'actor_user_id', v_actor,
      'correlation_id', v_correlation
    )
  );

  v_result := jsonb_build_object(
    'tenant_id', v_tenant_id,
    'owner_membership_id', v_membership_id,
    'owner_user_id', p_owner_user_id,
    'tenant_status', 'provisioning',
    'correlation_id', v_correlation,
    'is_new_user', coalesce(p_is_new_user, false)
  );

  insert into iam.onboarding_operations (idempotency_key, correlation_id, result)
  values (p_idempotency_key, v_correlation, v_result);

  return v_result;
end;
$$;

revoke all on function iam.create_tenant_onboarding(uuid, text, text, text, boolean)
  from public, anon;
grant execute on function iam.create_tenant_onboarding(uuid, text, text, text, boolean)
  to authenticated;

revoke all on table iam.onboarding_operations from public, anon, authenticated;
