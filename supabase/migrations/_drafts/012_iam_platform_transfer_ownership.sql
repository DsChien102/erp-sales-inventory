-- Title: iam platform transfer ownership (S16 / EP-02 US-09)
-- Kind: patch
-- Intent: iam_platform_transfer_ownership
-- Touches: iam.transfer_platform_tenant_ownership
-- Notes: Draft only — do not apply via supabase migration up until promoted.
--        Atomic is_owner flip; role column unchanged. Idempotent via ops table.

create table if not exists iam.ownership_transfer_operations (
  idempotency_key text primary key,
  tenant_id uuid not null,
  new_owner_user_id uuid not null,
  created_at timestamptz not null default now()
);

create or replace function iam.transfer_platform_tenant_ownership(
  p_tenant_id uuid,
  p_new_owner_user_id uuid,
  p_idempotency_key text
)
returns void
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare
  v_actor uuid := auth.uid();
  v_status text;
  v_existing text;
begin
  if not iam.has_platform_permission('platform.tenant.owner.transfer') then
    raise exception 'platform permission denied';
  end if;

  if p_idempotency_key is null or trim(p_idempotency_key) = '' then
    raise exception 'idempotency key required';
  end if;

  select idempotency_key into v_existing
  from iam.ownership_transfer_operations
  where idempotency_key = p_idempotency_key;

  if v_existing is not null then
    return;
  end if;

  select coalesce(status, 'active') into v_status
  from iam.tenants
  where id = p_tenant_id
  for update;

  if v_status is null then
    raise exception 'platform tenant not found';
  end if;

  if v_status = 'closed' then
    raise exception 'closed tenant cannot transfer ownership';
  end if;

  if not exists (
    select 1
    from iam.memberships m
    where m.tenant_id = p_tenant_id
      and m.user_id = p_new_owner_user_id
  ) then
    raise exception 'invalid ownership transfer target';
  end if;

  -- Flip is_owner only; do not change role (US-09 BR-03/04).
  update iam.memberships
  set is_owner = (user_id = p_new_owner_user_id)
  where tenant_id = p_tenant_id;

  insert into iam.ownership_transfer_operations (
    idempotency_key, tenant_id, new_owner_user_id
  ) values (
    p_idempotency_key, p_tenant_id, p_new_owner_user_id
  );

  insert into iam.platform_audit_logs (
    actor_user_id, action, target_tenant_id, target_user_id, status, title,
    correlation_id, source_app, before_state, after_state, payload
  ) values (
    v_actor,
    'platform.tenant.owner.transfer',
    p_tenant_id,
    p_new_owner_user_id,
    'success',
    'Đã chuyển quyền sở hữu',
    gen_random_uuid()::text,
    'admin',
    'previous_owner',
    'new_owner',
    jsonb_build_object(
      'new_owner_user_id', p_new_owner_user_id,
      'idempotency_key', p_idempotency_key
    )
  );
end;
$$;

revoke all on function iam.transfer_platform_tenant_ownership(uuid, uuid, text)
  from public, anon;
grant execute on function iam.transfer_platform_tenant_ownership(uuid, uuid, text)
  to authenticated;

revoke all on table iam.ownership_transfer_operations from public, anon, authenticated;
